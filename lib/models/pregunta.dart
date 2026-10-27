/// Representa una pregunta de autoevaluación o quiz generado por la IA.
///
/// Incluye el enunciado, opciones múltiples, el índice de la respuesta correcta
/// y una explicación pedagógica generada por la IA para retroalimentar al alumno.
class Pregunta {
  /// Identificador único de la pregunta.
  final String id;

  /// Enunciado o texto de la pregunta formulada.
  final String enunciado;

  /// Lista de opciones disponibles (usualmente 4 alternativas).
  final List<String> opciones;

  /// Índice numérico (base 0) que corresponde a la respuesta correcta en [opciones].
  final int indiceRespuestaCorrecta;

  /// Explicación detallada de la IA explicando por qué es la respuesta correcta
  /// o aclarando los conceptos clave.
  final String explicacionIa;

  const Pregunta({
    required this.id,
    required this.enunciado,
    required this.opciones,
    required this.indiceRespuestaCorrecta,
    required this.explicacionIa,
  });
}
