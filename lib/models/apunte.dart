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

  /// Lista de ideas clave identificadas por la IA (al menos 4 ideas).
  final List<String> ideasClave;

  /// Resumen ultra conciso (1-2 oraciones) generado por la IA.
  final String resumenCorto;

  /// Resumen intermedio con los puntos principales.
  final String resumenMedio;

  /// Resumen extenso y detallado para un repaso exhaustivo.
  final String resumenDetallado;

  /// Los campos de IA son opcionales: un apunte real los deja vacíos hasta la Fase 3.
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
}
