import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Indicador centrado que se muestra mientras la IA trabaja.
class CargandoIa extends StatelessWidget {
  /// Qué está haciendo la IA (ej. "Resumiendo tu apunte...").
  final String mensaje;

  const CargandoIa({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primario),
            const SizedBox(height: 20),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Puede tardar unos segundos.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje centrado cuando la IA falló, con un botón para reintentar.
class ErrorDeIa extends StatelessWidget {
  /// Mensaje del error, listo para mostrar.
  final String mensaje;

  /// Acción del botón "Reintentar".
  final VoidCallback onReintentar;

  const ErrorDeIa({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: tema.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              key: const Key('reintentar-ia'),
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
