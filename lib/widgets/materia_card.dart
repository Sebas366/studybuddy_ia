import 'package:flutter/material.dart';

import '../models/materia.dart';

/// Tarjeta visual representativa de una materia en la pantalla de inicio.
///
/// Implementa una animación [Hero] en el contenedor del icono de la asignatura,
/// un degradado con los colores de la materia y, si ya se presentó algún quiz,
/// una barra con el mejor resultado.
class MateriaCard extends StatelessWidget {
  /// Instancia de la materia que contiene la información a renderizar.
  final Materia materia;

  /// Callback ejecutado cuando el usuario presiona la tarjeta.
  final VoidCallback onTap;

  /// Callback opcional ejecutado al mantener presionada la tarjeta.
  final VoidCallback? onLongPress;

  /// Semestre a mostrar antes del subtítulo; `null` para no mostrarlo.
  final String? semestre;

  /// Mejor resultado en los quizzes de la materia (0.0 a 1.0); `null` si no hay ninguno.
  final double? dominio;

  const MateriaCard({
    super.key,
    required this.materia,
    required this.onTap,
    this.onLongPress,
    this.semestre,
    this.dominio,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final dominio = this.dominio;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF23202B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: esOscuro
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono de la materia envuelto en Hero para animación fluida hacia el detalle
                    Hero(
                      tag: 'icono-${materia.id}',
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: materia.coloresDegradado,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: materia.colorInicio.withValues(
                                alpha: esOscuro ? 0.4 : 0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          materia.icono,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Título y subtítulo descriptivo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            materia.nombre,
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            semestre == null
                                ? materia.subtitulo
                                : '$semestre · ${materia.subtitulo}',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: esOscuro
                                  ? Colors.white70
                                  : Colors.black.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Flecha indicadora de navegación
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: esOscuro
                          ? Colors.white38
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                // El dominio sale del mejor quiz; sin quizzes no se muestra la barra
                if (dominio != null) ...[
                  const SizedBox(height: 18),
                  // Barra de progreso y porcentaje numérico
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mejor resultado en quiz',
                            style: tema.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: esOscuro
                                  ? Colors.white60
                                  : Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                          Text(
                            '${(dominio * 100).round()}%',
                            style: tema.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: materia.colorInicio,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: dominio,
                          minHeight: 7,
                          backgroundColor: esOscuro
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            materia.colorInicio,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
