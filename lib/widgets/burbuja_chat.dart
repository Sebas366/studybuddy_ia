import 'package:flutter/material.dart';
import '../models/mensaje_chat.dart';
import '../theme/app_colors.dart';

/// Burbuja de conversación personalizada para la pantalla del Tutor IA.
///
/// Diferencia visualmente los mensajes del estudiante y las respuestas de la IA,
/// incluyendo avatar para el asistente, degradado y hora del mensaje.
class BurbujaChat extends StatelessWidget {
  /// Objeto con los datos del mensaje a dibujar.
  final MensajeChat mensaje;

  const BurbujaChat({
    super.key,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final esUsuario = mensaje.esUsuario;

    // Formateo simple de la hora en HH:mm
    final horaTexto =
        '${mensaje.fecha.hour.toString().padLeft(2, '0')}:${mensaje.fecha.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del asistente de IA para mensajes recibidos
          if (!esUsuario) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.degradadoEncabezado,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primario.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],

          // Contenedor principal de la burbuja
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: esUsuario
                    ? AppColors.primario
                    : (esOscuro
                        ? const Color(0xFF282531)
                        : const Color(0xFFEDE7F6)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(esUsuario ? 18 : 4),
                  bottomRight: Radius.circular(esUsuario ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: esUsuario
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    mensaje.texto,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: esUsuario
                          ? Colors.white
                          : (esOscuro ? Colors.white : Colors.black87),
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    horaTexto,
                    style: tema.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: esUsuario
                          ? Colors.white.withValues(alpha: 0.7)
                          : (esOscuro ? Colors.white54 : Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Espaciado derecho si es usuario para evitar pegarse al borde absoluto
          if (esUsuario) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
