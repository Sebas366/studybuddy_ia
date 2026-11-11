import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/materias_repository.dart';
import 'data/materias_repository_sqflite.dart';
import 'providers/ajustes_provider.dart';
import 'providers/estadisticas_provider.dart';
import 'providers/ia_provider.dart';
import 'providers/materias_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'screens/error_base_datos_screen.dart';
import 'screens/main_shell.dart';
import 'services/almacen_clave.dart';
import 'services/notificador_local.dart';
import 'services/notificador_pomodoro.dart';
import 'services/selector_imagen.dart';
import 'theme/app_theme.dart';
import 'utils/reloj.dart';

/// Punto de entrada principal de la aplicación StudyBuddy IA.
///
/// Inicializa el entorno Flutter, abre la base de datos local y monta el
/// widget raíz [StudyBuddyApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _iniciar();
}

/// Abre la base de datos y arranca la app; si falla, muestra una pantalla de
/// error con la opción de reintentar en lugar de dejar la app en blanco.
Future<void> _iniciar() async {
  try {
    final repositorio = await MateriasRepositorySqflite.abrir();
    final notificador = await _crearNotificador();
    final recordatorio = notificador is NotificadorRecordatorio
        ? notificador as NotificadorRecordatorio
        : const RecordatorioNulo();
    // Los ajustes se leen antes de dibujar para arrancar ya con el tema elegido.
    final ajustes = AjustesProvider(
      repositorio: repositorio,
      recordatorio: recordatorio,
    );
    await ajustes.cargar();
    runApp(
      StudyBuddyApp(
        repositorio: repositorio,
        notificador: notificador,
        recordatorio: recordatorio,
        ajustes: ajustes,
        almacenClave: const AlmacenClaveSeguro(),
        selectorImagen: const SelectorImagenSistema(),
      ),
    );
  } catch (_) {
    runApp(ErrorBaseDatosApp(onReintentar: _iniciar));
  }
}

/// Crea el notificador real; si el sistema no lo permite, usa uno que no hace nada
/// (el Pomodoro funciona igual, solo que sin aviso al terminar).
Future<NotificadorPomodoro> _crearNotificador() async {
  try {
    return await NotificadorLocal.crear();
  } catch (_) {
    return const NotificadorNulo();
  }
}

/// Widget raíz de la aplicación StudyBuddy IA.
///
/// Configura el [MaterialApp] con Material 3, tipografía Poppins y temas claro
/// y oscuro, y monta los providers con el estado de la app. Todo lo que habla
/// con el sistema (base de datos, notificaciones, clave, cámara, IA) entra por
/// el constructor para que las pruebas puedan reemplazarlo.
class StudyBuddyApp extends StatelessWidget {
  /// Almacenamiento de los datos del usuario (SQLite en la app, memoria en pruebas).
  final MateriasRepository repositorio;

  /// Aviso al terminar cada bloque de Pomodoro (alarma del sistema en la app real).
  final NotificadorPomodoro notificador;

  /// Recordatorio diario de estudio.
  final NotificadorRecordatorio recordatorio;

  /// Ajustes ya cargados; si es `null` se crean y se cargan al montar la app.
  final AjustesProvider? ajustes;

  /// Dónde se guarda la clave de la API de IA.
  final AlmacenClave? almacenClave;

  /// Crea el servicio de IA a partir del proveedor y la clave; `null` usa las APIs reales.
  final FabricaServicioIa? fabricaIa;

  /// Cámara y galería para escanear apuntes.
  final SelectorImagen selectorImagen;

  /// Reloj de la app; las pruebas lo reemplazan por uno simulado.
  final Reloj ahora;

  const StudyBuddyApp({
    super.key,
    required this.repositorio,
    this.notificador = const NotificadorNulo(),
    this.recordatorio = const RecordatorioNulo(),
    this.ajustes,
    this.almacenClave,
    this.fabricaIa,
    this.selectorImagen = const SelectorImagenSistema(),
    this.ahora = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MateriasRepository>.value(value: repositorio),
        Provider<SelectorImagen>.value(value: selectorImagen),
        Provider<Reloj>.value(value: ahora),
        if (ajustes != null)
          ChangeNotifierProvider<AjustesProvider>.value(value: ajustes!)
        else
          ChangeNotifierProvider<AjustesProvider>(
            create: (_) => AjustesProvider(
              repositorio: repositorio,
              recordatorio: recordatorio,
            )..cargar(),
          ),
        ChangeNotifierProvider<IaProvider>(
          lazy: false,
          create: (_) => IaProvider(
            almacen: almacenClave ?? AlmacenClaveMemoria(),
            fabrica: fabricaIa,
          )..cargar(),
        ),
        ChangeNotifierProvider<MateriasProvider>(
          create: (_) => MateriasProvider(repositorio)..cargar(),
        ),
        // Se recarga cuando cambian las materias (borrar una borra sus datos).
        ChangeNotifierProxyProvider<MateriasProvider, EstadisticasProvider>(
          lazy: false,
          create: (_) => EstadisticasProvider(repositorio)..cargar(),
          update: (_, materias, estadisticas) {
            estadisticas!.sincronizarConMaterias(materias.materias);
            return estadisticas;
          },
        ),
        // El plan también se recarga: borrar una materia borra sus evaluaciones y sesiones.
        ChangeNotifierProxyProvider<MateriasProvider, PlanProvider>(
          lazy: false,
          create: (_) => PlanProvider(repositorio)..cargar(),
          update: (_, materias, plan) {
            plan!.sincronizarConMaterias(materias.materias);
            return plan;
          },
        ),
        // El Pomodoro vive aquí para que siga corriendo al salir de su pantalla.
        ChangeNotifierProvider<PomodoroProvider>(
          lazy: false,
          create: (context) => PomodoroProvider(
            repositorio: repositorio,
            notificador: notificador,
            registrarSesion: context
                .read<EstadisticasProvider>()
                .registrarSesionEnfoque,
            ahora: ahora,
          )..restaurar(),
        ),
      ],
      child: _RefrescarAlReanudar(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              title: 'StudyBuddy IA',
              debugShowCheckedModeBanner: false,

              // Definición de temas claro y oscuro
              theme: AppTheme.temaClaro,
              darkTheme: AppTheme.temaOscuro,
              // Solo se reconstruye cuando cambia el tema elegido en Perfil.
              themeMode: context.select<AjustesProvider, ThemeMode>(
                (ajustes) => ajustes.modoTema,
              ),

              // Pantalla principal con la barra de navegación inferior
              home: const MainShell(),
            );
          },
        ),
      ),
    );
  }
}

/// Recarga las estadísticas y el plan cuando la app vuelve a primer plano.
///
/// Así los datos y las fechas (racha, semana actual, sesiones de hoy) no quedan
/// viejos si la app estuvo en segundo plano, por ejemplo durante la noche.
class _RefrescarAlReanudar extends StatefulWidget {
  final Widget child;

  const _RefrescarAlReanudar({required this.child});

  @override
  State<_RefrescarAlReanudar> createState() => _RefrescarAlReanudarState();
}

class _RefrescarAlReanudarState extends State<_RefrescarAlReanudar>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final pomodoro = context.read<PomodoroProvider>();
    switch (estado) {
      case AppLifecycleState.resumed:
        pomodoro.definirPrimerPlano(true);
        context.read<EstadisticasProvider>().cargar();
        context.read<PlanProvider>().cargar();
        pomodoro.alReanudarApp();
      case AppLifecycleState.paused ||
          AppLifecycleState.hidden ||
          AppLifecycleState.detached:
        pomodoro.definirPrimerPlano(false);
      case AppLifecycleState.inactive:
        break; // transitorio (p. ej. al bajar el panel de notificaciones)
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
