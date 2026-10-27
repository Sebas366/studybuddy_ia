import 'package:flutter/material.dart';

/// Tarjeta con borde punteado que avisa que las funciones de IA llegan en la Fase 3.
///
/// Se muestra en lugar de las ideas clave, los resúmenes y el quiz de un apunte real.
class AvisoIaFase3 extends StatelessWidget {
  const AvisoIaFase3({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorBorde = esOscuro ? Colors.white38 : Colors.black38;

    return CustomPaint(
      painter: _BordePunteadoPainter(color: colorBorde, radio: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esOscuro
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen, ideas clave y quiz con IA',
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Disponible en la Fase 3.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: esOscuro ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra el aviso de IA en un diálogo con un botón "Entendido".
Future<void> mostrarAvisoIaFase3(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (contextDialogo) => AlertDialog(
      title: const Text('Función con IA'),
      content: const AvisoIaFase3(),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contextDialogo),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

/// Dibuja un rectángulo redondeado con borde de guiones.
class _BordePunteadoPainter extends CustomPainter {
  final Color color;
  final double radio;

  const _BordePunteadoPainter({required this.color, required this.radio});

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final contorno = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radio),
      ));

    const largoGuion = 6.0;
    const largoEspacio = 4.0;
    for (final tramo in contorno.computeMetrics()) {
      var distancia = 0.0;
      while (distancia < tramo.length) {
        final fin = (distancia + largoGuion).clamp(0.0, tramo.length);
        canvas.drawPath(tramo.extractPath(distancia, fin), pincel);
        distancia += largoGuion + largoEspacio;
      }
    }
  }

  @override
  bool shouldRepaint(_BordePunteadoPainter anterior) =>
      anterior.color != color || anterior.radio != radio;
}
