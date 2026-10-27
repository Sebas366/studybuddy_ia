import 'package:flutter/material.dart';

/// Tarjeta de acción interactiva para la cuadrícula 2x2 de la pantalla de Detalle de Materia.
///
/// Diseñada para accesos rápidos como Resumir, Quiz IA, Tutor IA y Pomodoro.
class AccionCard extends StatelessWidget {
  /// Título principal de la acción (ej. "Resumir", "Quiz IA").
  final String titulo;

  /// Subtítulo descriptivo breve (ej. "Ideas clave", "5 preguntas").
  final String subtitulo;

  /// Icono ilustrativo de la acción.
  final IconData icono;

  /// Color temático base para resaltar la acción.
  final Color colorTema;

  /// Acción a ejecutar al tocar la tarjeta.
  final VoidCallback onTap;

  const AccionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.colorTema,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: esOscuro
            ? colorTema.withValues(alpha: 0.12)
            : colorTema.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorTema.withValues(alpha: esOscuro ? 0.3 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorTema.withValues(alpha: esOscuro ? 0.15 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorTema.withValues(alpha: esOscuro ? 0.25 : 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icono,
                    color: colorTema,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: esOscuro
                            ? Colors.white60
                            : Colors.black.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
