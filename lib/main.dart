import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/materias_repository.dart';
import 'data/materias_repository_sqflite.dart';
import 'providers/estadisticas_provider.dart';
import 'providers/materias_provider.dart';
import 'screens/error_base_datos_screen.dart';
import 'screens/main_shell.dart';
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
    runApp(StudyBuddyApp(repositorio: repositorio));
  } catch (_) {
    runApp(ErrorBaseDatosApp(onReintentar: _iniciar));
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

  const StudyBuddyApp({super.key, required this.repositorio});

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
      ],
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
    );
  }
}
