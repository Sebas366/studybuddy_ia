import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/materias_repository.dart';
import 'data/materias_repository_sqflite.dart';
import 'providers/estadisticas_provider.dart';
import 'providers/materias_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'screens/error_base_datos_screen.dart';
import 'screens/main_shell.dart';
import 'services/notificador_local.dart';
import 'services/notificador_pomodoro.dart';
import 'theme/app_theme.dart';

/// Punto de entrada principal de la aplicación StudyBuddy IA.
///
/// Inicializa el entorno Flutter, abre la base de datos local de materias y
/// apuntes, y monta el widget raíz [StudyBuddyApp].
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
    runApp(StudyBuddyApp(repositorio: repositorio, notificador: notificador));
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
/// Configura el [MaterialApp] con soporte para Material 3, tipografía Poppins,
/// temas claro y oscuro, y escucha reactivamente a [modoTemaGlobal] para permitir
/// al usuario alternar el tema visual en tiempo real desde la pantalla de Perfil.
/// También provee el [MateriasProvider] con las materias y apuntes del usuario.
class StudyBuddyApp extends StatelessWidget {
  /// Almacenamiento de materias y apuntes (SQLite en la app, memoria en pruebas).
  final MateriasRepository repositorio;

  /// Aviso al terminar cada bloque de Pomodoro (alarma del sistema en la app real).
  final NotificadorPomodoro notificador;

  /// Reloj de la app; las pruebas lo reemplazan por uno simulado.
  final DateTime Function() ahora;

  const StudyBuddyApp({
    super.key,
    required this.repositorio,
    this.notificador = const NotificadorNulo(),
    this.ahora = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: modoTemaGlobal,
          builder: (context, modoTema, _) {
            return MaterialApp(
              title: 'StudyBuddy IA',
              debugShowCheckedModeBanner: false,

              // Definición de temas claro y oscuro
              theme: AppTheme.temaClaro,
              darkTheme: AppTheme.temaOscuro,
              themeMode: modoTema,

              // Pantalla principal con la barra de navegación inferior
              home: const MainShell(),
            );
          },
        ),
      ),
    );
  }
}

/// Recarga las estadísticas cuando la app vuelve a primer plano.
///
/// Así los datos y las fechas (racha, semana actual) no quedan viejos si la app
/// estuvo en segundo plano, por ejemplo durante la noche.
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
