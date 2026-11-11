/// Bloque de estudio que el estudiante planea para un día y una hora.
class SesionEstudio {
  /// Identificador único de la sesión.
  final String id;

  /// Materia de la sesión; `null` si es estudio libre.
  final String? materiaId;

  /// Tema específico que se abordará en la sesión.
  final String tema;

  /// Día y hora en que empieza la sesión.
  final DateTime inicio;

  /// Duración planeada en minutos.
  final int duracionMinutos;

  /// `true` si el estudiante ya la marcó como hecha.
  final bool completada;

  const SesionEstudio({
    required this.id,
    required this.materiaId,
    required this.tema,
    required this.inicio,
    required this.duracionMinutos,
    this.completada = false,
  });

  /// Momento en que termina la sesión.
  DateTime get fin => inicio.add(Duration(minutes: duracionMinutos));
}
