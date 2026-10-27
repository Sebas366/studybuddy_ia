/// Representa un bloque o sesión de estudio planificada para la jornada.
class SesionEstudio {
  /// Identificador único de la sesión.
  final String id;

  /// Nombre de la materia asignada a la sesión.
  final String materia;

  /// Tema específico que se abordará en la sesión.
  final String tema;

  /// Horario planeado para el estudio (ej. "09:00 AM - 10:30 AM").
  final String hora;

  /// Duración estimada de la sesión en minutos.
  final int duracionMinutos;

  /// Estado de cumplimiento marcado por el estudiante.
  bool completada;

  SesionEstudio({
    required this.id,
    required this.materia,
    required this.tema,
    required this.hora,
    required this.duracionMinutos,
    this.completada = false,
  });
}
