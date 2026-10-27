import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Indicador visual animado que simula la respuesta en progreso del Tutor IA ("escribiendo...").
///
/// Presenta 3 puntos que oscilan suavemente y un mensaje descriptivo.
/// Maneja y cancela adecuadamente su [AnimationController] en [dispose].
class IndicadorEscribiendo extends StatefulWidget {
  const IndicadorEscribiendo({super.key});

  @override
  State<IndicadorEscribiendo> createState() => _IndicadorEscribiendoState();
}

class _IndicadorEscribiendoState extends State<IndicadorEscribiendo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controladorAnimacion;

  @override
  void initState() {
    super.initState();
    // Animación continua y cíclica para los tres puntos pulsantes
    _controladorAnimacion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    // Cancelación obligatoria para evitar fugas de memoria
    _controladorAnimacion.dispose();
    super.dispose();
  }

  /// Construye un punto con retardo de fase según su índice (0, 1 o 2).
  Widget _construirPunto(int indice) {
    return AnimatedBuilder(
      animation: _controladorAnimacion,
      builder: (context, child) {
        // Desfase matemático para crear el efecto ola entre los puntos
        final retraso = indice * 0.2;
        final valorOnda = (_controladorAnimacion.value - retraso) % 1.0;
        final escala = 0.5 + (0.5 * (1.0 - (valorOnda - 0.5).abs() * 2));

        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: AppColors.primario.withValues(alpha: 0.4 + (0.6 * escala)),
            shape: BoxShape.circle,
          ),
          transform: Matrix4.diagonal3Values(escala, escala, 1.0),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar en miniatura
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.degradadoEncabezado,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          // Contenedor de los puntos y leyenda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: esOscuro
                  ? const Color(0xFF282531)
                  : const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _construirPunto(0),
                _construirPunto(1),
                _construirPunto(2),
                const SizedBox(width: 8),
                Text(
                  'StudyBuddy IA está pensando...',
                  style: tema.textTheme.labelSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: esOscuro ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
