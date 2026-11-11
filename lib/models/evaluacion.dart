/// Parcial, quiz o entrega con fecha que el estudiante quiere preparar.
class Evaluacion {
  /// Identificador único de la evaluación.
  final String id;

  /// Materia que se evalúa.
  final String materiaId;

  /// Nombre de la evaluación (ej. "Primer parcial").
  final String titulo;

  /// Día de la evaluación (sin hora).
  final DateTime fecha;

  /// Temas que entran; puede estar vacío.
  final String temas;

  const Evaluacion({
    required this.id,
    required this.materiaId,
    required this.titulo,
    required this.fecha,
    this.temas = '',
  });
}
