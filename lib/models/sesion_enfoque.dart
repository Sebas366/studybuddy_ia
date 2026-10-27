/// Un bloque de enfoque del Pomodoro que el usuario completó.
///
/// Solo se guardan los bloques que llegaron a 00:00; saltar o reiniciar no
/// deja registro.
class SesionEnfoque {
  /// Identificador único de la sesión.
  final String id;

  /// Materia a la que se dedicó el bloque; `null` si se estudió sin materia.
  final String? materiaId;

  /// Momento en que empezó el bloque.
  final DateTime inicio;

  /// Duración del bloque en segundos (un enfoque completo son 1500).
  final int duracionSegundos;

  const SesionEnfoque({
    required this.id,
    this.materiaId,
    required this.inicio,
    required this.duracionSegundos,
  });
}
