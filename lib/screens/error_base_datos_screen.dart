import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App mínima que se muestra cuando la base de datos local no se pudo abrir.
///
/// Explica el problema y ofrece [onReintentar], en vez de dejar al usuario con
/// una pantalla en blanco.
class ErrorBaseDatosApp extends StatelessWidget {
  /// Acción ejecutada al pulsar "Reintentar" (vuelve a intentar abrir la base).
  final VoidCallback onReintentar;

  const ErrorBaseDatosApp({super.key, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyBuddy IA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.temaClaro,
      darkTheme: AppTheme.temaOscuro,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storage_rounded, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'No se pudo abrir tu base de datos',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No pudimos acceder al almacenamiento de tus apuntes. Prueba de '
                  'nuevo; si el problema continúa, libera espacio en el celular y '
                  'reinicia la app.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  key: const Key('reintentar-base-datos'),
                  onPressed: onReintentar,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
