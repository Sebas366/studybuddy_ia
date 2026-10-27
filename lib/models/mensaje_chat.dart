/// Representa un mensaje individual dentro de la conversación con el Tutor IA.
class MensajeChat {
  /// Identificador único del mensaje.
  final String id;

  /// Contenido del mensaje en texto plano.
  final String texto;

  /// Indica si el mensaje fue enviado por el estudiante (true) o por el Tutor IA (false).
  final bool esUsuario;

  /// Momento temporal en el que se generó el mensaje.
  final DateTime fecha;

  const MensajeChat({
    required this.id,
    required this.texto,
    required this.esUsuario,
    required this.fecha,
  });
}
