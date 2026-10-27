import 'package:flutter/material.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

/// Punto de entrada principal de la aplicación StudyBuddy IA.
///
/// Inicializa el entorno Flutter y monta el widget raíz [StudyBuddyApp].
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyBuddyApp());
}

/// Widget raíz de la aplicación StudyBuddy IA.
///
/// Configura el [MaterialApp] con soporte para Material 3, tipografía Poppins,
/// temas claro y oscuro, y escucha reactivamente a [modoTemaGlobal] para permitir
/// al usuario alternar el tema visual en tiempo real desde la pantalla de Perfil.
class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
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
    );
  }
}
