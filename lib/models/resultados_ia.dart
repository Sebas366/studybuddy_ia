/// Resumen de un apunte generado por la IA, en tres niveles de detalle.
class ResumenApunte {
  /// Resumen de una o dos oraciones.
  final String corto;

  /// Resumen de un párrafo con los puntos principales.
  final String medio;

  /// Resumen extenso para un repaso completo.
  final String detallado;

  /// Ideas clave del apunte, una oración cada una.
  final List<String> ideasClave;

  const ResumenApunte({
    required this.corto,
    required this.medio,
    required this.detallado,
    required this.ideasClave,
  });
}

/// Texto que la IA transcribió de la foto de un apunte.
class ApunteEscaneado {
  /// Título que la IA propone para el apunte.
  final String titulo;

  /// Texto transcrito de la imagen.
  final String contenido;

  const ApunteEscaneado({required this.titulo, required this.contenido});
}

/// Sesión de estudio que la IA propone para preparar una evaluación.
class SesionSugerida {
  /// Día y hora propuestos para empezar.
  final DateTime inicio;

  /// Duración propuesta en minutos.
  final int duracionMinutos;

  /// Qué estudiar en la sesión.
  final String tema;

  const SesionSugerida({
    required this.inicio,
    required this.duracionMinutos,
    required this.tema,
  });
}
