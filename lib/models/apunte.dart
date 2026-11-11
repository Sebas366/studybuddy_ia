/// Representa un apunte o tema de estudio cargado en una materia.
///
/// Contiene el texto original, las ideas clave extraídas por la IA,
/// y tres niveles de resumen automático (corto, medio y detallado).
class Apunte {
  /// Identificador único del apunte.
  final String id;

  /// Título descriptivo del apunte o tema.
  final String titulo;

  /// Identificador de la materia a la que pertenece.
  final String materiaId;

  /// Fecha en formato legible en que se registró el apunte.
  final String fecha;

  /// Contenido textual completo del apunte original.
  final String contenido;

  /// Lista de ideas clave identificadas por la IA.
  final List<String> ideasClave;

  /// Resumen ultra conciso (1-2 oraciones) generado por la IA.
  final String resumenCorto;

  /// Resumen intermedio con los puntos principales.
  final String resumenMedio;

  /// Resumen extenso y detallado para un repaso exhaustivo.
  final String resumenDetallado;

  /// Los campos de IA son opcionales: quedan vacíos hasta que se pide el resumen.
  const Apunte({
    required this.id,
    required this.titulo,
    required this.materiaId,
    required this.fecha,
    required this.contenido,
    this.ideasClave = const [],
    this.resumenCorto = '',
    this.resumenMedio = '',
    this.resumenDetallado = '',
  });

  /// `true` si la IA ya generó el resumen de este apunte.
  bool get tieneResumen => resumenMedio.isNotEmpty;
}
