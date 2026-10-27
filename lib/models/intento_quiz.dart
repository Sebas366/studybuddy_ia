/// Resultado de un quiz que el usuario terminó.
class IntentoQuiz {
  /// Identificador único del intento.
  final String id;

  /// Materia a la que pertenece el quiz.
  final String materiaId;

  /// Cantidad de preguntas respondidas correctamente.
  final int aciertos;

  /// Cantidad total de preguntas del quiz.
  final int total;

  /// Momento en que se terminó el quiz.
  final DateTime fecha;

  const IntentoQuiz({
    required this.id,
    required this.materiaId,
    required this.aciertos,
    required this.total,
    required this.fecha,
  });

  /// Proporción de aciertos entre 0.0 y 1.0 (0 si el quiz no tenía preguntas).
  double get proporcion => total > 0 ? aciertos / total : 0.0;
}
