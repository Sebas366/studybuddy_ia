import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/apunte.dart';
import '../models/mensaje_chat.dart';
import '../models/pregunta.dart';
import '../models/resultados_ia.dart';
import 'servicio_ia.dart';

/// Imagen que acompaña una petición a la IA.
typedef ImagenIa = ({Uint8List bytes, String tipoMime});

/// Turno de una conversación con el tutor.
typedef TurnoChat = ({bool esUsuario, String texto});

/// Parte común de los servicios de IA: qué se le pide al modelo y cómo se
/// valida lo que responde.
///
/// Cada proveedor (Gemini, Claude) hereda de aquí y solo implementa el
/// transporte: [pedirJson] para las respuestas con datos (resumen, quiz, plan y
/// transcripción), que deben cumplir un esquema JSON, y [pedirRespuesta] para
/// el tutor, que responde en streaming. Así las instrucciones y las
/// validaciones se escriben una sola vez.
abstract class ServicioIaBase implements ServicioIa {
  ServicioIaBase({
    http.Client? cliente,
    Random? azar,
    this.pausaReintento = const Duration(seconds: 2),
  }) : cliente = cliente ?? http.Client(),
       _azar = azar ?? Random();

  /// Cliente HTTP con el que se llama a la API.
  @protected
  final http.Client cliente;

  final Random _azar;

  /// Espera antes de reintentar una petición que falló por saturación del servicio.
  final Duration pausaReintento;

  /// Cuántas veces se reintenta una petición que falló por saturación (429 o 5xx).
  static const int _reintentos = 2;

  /// Tiempo máximo para recibir una respuesta completa.
  @protected
  static const Duration esperaRespuesta = Duration(minutes: 3);

  /// Tiempo máximo sin recibir nada durante una respuesta en streaming.
  @protected
  static const Duration esperaEntreEventos = Duration(seconds: 90);

  // ---------------------------------------------------------------------------
  // Transporte (lo implementa cada proveedor)
  // ---------------------------------------------------------------------------

  /// Pide una respuesta que cumpla el [esquema] y la devuelve ya decodificada.
  @protected
  Future<Map<String, Object?>> pedirJson({
    required String sistema,
    required String texto,
    ImagenIa? imagen,
    required Map<String, Object?> esquema,
  });

  /// Pide la respuesta a una conversación y la entrega por partes.
  ///
  /// [turnos] empieza y termina con un turno del estudiante, y alterna.
  @protected
  Stream<String> pedirRespuesta({
    required String sistema,
    required List<TurnoChat> turnos,
  });

  // ---------------------------------------------------------------------------
  // Operaciones
  // ---------------------------------------------------------------------------

  @override
  Future<ResumenApunte> resumirApunte({
    required String materia,
    required String titulo,
    required String contenido,
  }) async {
    final datos = await pedirJson(
      sistema:
          'Eres un asistente de estudio para estudiantes universitarios. '
          'Resumes apuntes de clase en español, con fidelidad al texto: no '
          'agregues datos que el apunte no contiene. $_formato',
      texto:
          'Materia: $materia\n'
          'Título del apunte: $titulo\n\n'
          '<apunte>\n$contenido\n</apunte>\n\n'
          'Resume este apunte en tres niveles y extrae sus ideas clave:\n'
          '- resumen_corto: una o dos oraciones con la idea central.\n'
          '- resumen_medio: un párrafo de tres a cinco oraciones con los '
          'puntos principales.\n'
          '- resumen_detallado: dos o tres párrafos para un repaso completo, '
          'con las relaciones entre conceptos.\n'
          '- ideas_clave: entre cuatro y seis ideas, cada una en una oración '
          'que se entienda por sí sola.',
      esquema: _objeto({
        'resumen_corto': _cadena,
        'resumen_medio': _cadena,
        'resumen_detallado': _cadena,
        'ideas_clave': _lista(_cadena),
      }),
    );

    final ideas = [
      for (final idea in _comoLista(datos['ideas_clave']))
        if (idea is String && idea.trim().isNotEmpty) idea.trim(),
    ];
    final medio = _comoTexto(datos['resumen_medio']);
    if (medio.isEmpty) throw respuestaInvalida();
    return ResumenApunte(
      corto: _comoTexto(datos['resumen_corto']),
      medio: medio,
      detallado: _comoTexto(datos['resumen_detallado']),
      ideasClave: ideas,
    );
  }

  @override
  Future<List<Pregunta>> generarQuiz({
    required String materia,
    required List<Apunte> apuntes,
    int cantidad = 5,
  }) async {
    final datos = await pedirJson(
      sistema:
          'Eres un profesor universitario que escribe preguntas de opción '
          'múltiple en español para que un estudiante se autoevalúe. '
          '$_formato',
      texto:
          'Materia: $materia\n\n'
          '${_textoApuntes(apuntes)}\n\n'
          'Escribe $cantidad preguntas de opción múltiple sobre estos '
          'apuntes:\n'
          '- Cada pregunta evalúa comprensión de un concepto de los apuntes, '
          'no memoria de frases literales.\n'
          '- Reparte las preguntas entre los distintos apuntes y temas.\n'
          '- Cada pregunta tiene exactamente cuatro opciones, una sola '
          'correcta, y las incorrectas deben ser plausibles.\n'
          '- No uses opciones como "todas las anteriores" o "ninguna de las '
          'anteriores": la app baraja el orden de las opciones.\n'
          '- indice_correcta es la posición (empezando en 0) de la opción '
          'correcta.\n'
          '- explicacion: una a tres oraciones que digan por qué esa es la '
          'respuesta correcta, para leer después de responder.',
      esquema: _objeto({
        'preguntas': _lista(
          _objeto({
            'enunciado': _cadena,
            'opciones': _lista(_cadena),
            'indice_correcta': {'type': 'integer'},
            'explicacion': _cadena,
          }),
        ),
      }),
    );

    final preguntas = <Pregunta>[];
    for (final cruda in _comoLista(datos['preguntas'])) {
      final pregunta = _preguntaValida(cruda, preguntas.length);
      if (pregunta != null) preguntas.add(pregunta);
    }
    if (preguntas.isEmpty) throw respuestaInvalida();
    return preguntas;
  }

  /// Convierte una pregunta del modelo en [Pregunta] con las opciones barajadas.
  ///
  /// Devuelve `null` si la pregunta no se puede usar (sin enunciado, con menos
  /// de dos opciones o con un índice fuera de rango).
  Pregunta? _preguntaValida(Object? cruda, int posicion) {
    if (cruda is! Map) return null;
    final enunciado = _comoTexto(cruda['enunciado']);
    final opciones = [
      for (final opcion in _comoLista(cruda['opciones']))
        if (opcion is String) opcion.trim(),
    ];
    final indice = cruda['indice_correcta'];
    if (enunciado.isEmpty ||
        opciones.length < 2 ||
        opciones.any((opcion) => opcion.isEmpty) ||
        indice is! int ||
        indice < 0 ||
        indice >= opciones.length) {
      return null;
    }

    // Los modelos tienden a repetir la posición de la respuesta correcta;
    // barajar evita que el estudiante la adivine por el patrón.
    final correcta = opciones[indice];
    final barajadas = [...opciones]..shuffle(_azar);
    return Pregunta(
      id: 'p$posicion',
      enunciado: enunciado,
      opciones: barajadas,
      indiceRespuestaCorrecta: barajadas.indexOf(correcta),
      explicacionIa: _comoTexto(cruda['explicacion']),
    );
  }

  @override
  Stream<String> responderTutor({
    required String materia,
    required String nombreEstudiante,
    required List<Apunte> apuntes,
    required List<MensajeChat> historial,
  }) async* {
    final turnos = _turnosDe(historial);
    if (turnos.isEmpty) return;

    final instrucciones = StringBuffer()
      ..writeln(
        'Eres el tutor de la materia "$materia" de $nombreEstudiante, '
        'estudiante universitario. Conversas por un chat dentro de una app '
        'de estudio para celular.',
      )
      ..writeln()
      ..writeln(
        'Explica con claridad y con ejemplos concretos, en español. Sé '
        'breve: unas pocas oraciones o una lista corta, salvo que te pidan '
        'más detalle. Si te piden que los evalúes, haz una sola pregunta, '
        'espera la respuesta y luego dales retroalimentación.',
      )
      ..writeln()
      ..writeln(
        'Debajo están los apuntes del estudiante. Cuando la respuesta esté '
        'en ellos, básate en ellos; cuando no, responde con lo que sabes de '
        'la materia y avisa que eso no aparece en sus apuntes.',
      )
      ..writeln()
      ..writeln(
        'La app muestra tu respuesta tal cual, sin interpretar formato, así '
        'que no uses Markdown: nada de asteriscos, numerales ni tablas. Para '
        'listas usa guiones o números al inicio de la línea. Escribe con la '
        'ortografía normal del español, con sus tildes y eñes.',
      )
      ..writeln()
      ..write(
        apuntes.isEmpty
            ? 'El estudiante todavía no tiene apuntes en esta materia.'
            : _textoApuntes(apuntes),
      );

    yield* pedirRespuesta(sistema: instrucciones.toString(), turnos: turnos);
  }

  @override
  Future<ApunteEscaneado> transcribirImagen({
    required Uint8List imagen,
    required String tipoMime,
    required String materia,
  }) async {
    final datos = await pedirJson(
      sistema:
          'Transcribes fotos de apuntes de clase (cuadernos, tableros y '
          'diapositivas) a texto, con fidelidad: no corrijas el contenido ni '
          'agregues información que no esté en la imagen. Conserva las '
          'tildes y eñes tal como aparecen.',
      imagen: (bytes: imagen, tipoMime: tipoMime),
      texto:
          'Esta foto es un apunte de la materia "$materia". Transcríbela:\n'
          '- contenido: todo el texto de la imagen, en el orden de lectura, '
          'con saltos de línea para conservar títulos, listas y párrafos. '
          'Escribe las fórmulas en una sola línea de texto. Si hay un '
          'diagrama o una figura, descríbelo en una línea entre corchetes. '
          'Si una palabra no se lee, escribe [ilegible].\n'
          '- titulo: un título corto que describa el tema del apunte.\n'
          '- legible: false si la imagen no contiene texto que se pueda '
          'leer; en ese caso deja contenido vacío.',
      esquema: _objeto({
        'titulo': _cadena,
        'contenido': _cadena,
        'legible': {'type': 'boolean'},
      }),
    );

    final contenido = _comoTexto(datos['contenido']);
    if (datos['legible'] == false || contenido.isEmpty) {
      throw const ErrorIa(
        TipoErrorIa.respuestaInvalida,
        'No se encontró texto legible en la imagen. Prueba con otra foto, '
        'más cerca y con buena luz.',
      );
    }
    final titulo = _comoTexto(datos['titulo']);
    return ApunteEscaneado(
      titulo: titulo.isEmpty ? 'Apunte escaneado' : titulo,
      contenido: contenido,
    );
  }

  @override
  Future<List<SesionSugerida>> sugerirPlan({
    required String materia,
    required String evaluacion,
    required String temas,
    required List<Apunte> apuntes,
    required DateTime hoy,
    required DateTime fechaEvaluacion,
  }) async {
    final primerDia = DateTime(hoy.year, hoy.month, hoy.day);
    final diaEvaluacion = DateTime(
      fechaEvaluacion.year,
      fechaEvaluacion.month,
      fechaEvaluacion.day,
    );
    // Se estudia hasta el día anterior; si la evaluación es hoy, solo queda hoy.
    final vispera = DateTime(
      diaEvaluacion.year,
      diaEvaluacion.month,
      diaEvaluacion.day - 1,
    );
    final ultimoDia = vispera.isBefore(primerDia) ? primerDia : vispera;

    final datos = await pedirJson(
      sistema:
          'Eres un asesor académico que arma planes de estudio realistas '
          'para estudiantes universitarios. Escribe en español. $_formato',
      texto:
          'Materia: $materia\n'
          'Evaluación: $evaluacion\n'
          'Fecha de la evaluación: ${_fechaIso(diaEvaluacion)}\n'
          'Hoy es: ${_fechaIso(primerDia)}\n'
          'Temas que entran: ${temas.trim().isEmpty ? '(no indicados)' : temas.trim()}\n\n'
          '${apuntes.isEmpty ? 'El estudiante no tiene apuntes de esta materia.' : _textoApuntes(apuntes)}\n\n'
          'Arma un plan de sesiones de estudio para preparar esta '
          'evaluación:\n'
          '- Las sesiones van desde ${_fechaIso(primerDia)} hasta '
          '${_fechaIso(ultimoDia)}, ambos incluidos.\n'
          '- Máximo una sesión por día y máximo siete sesiones en total; si '
          'hay más días que sesiones, repártelas dejando días libres.\n'
          '- Cada sesión dura entre 30 y 90 minutos.\n'
          '- La última sesión es un repaso general con autoevaluación.\n'
          '- tema: qué estudiar exactamente en esa sesión, con los temas '
          'concretos, en una frase corta de máximo 90 caracteres.\n'
          '- fecha con formato AAAA-MM-DD y hora de inicio con formato '
          'HH:MM de 24 horas, entre las 07:00 y las 21:00.',
      esquema: _objeto({
        'sesiones': _lista(
          _objeto({
            'fecha': _cadena,
            'hora': _cadena,
            'duracion_minutos': {'type': 'integer'},
            'tema': _cadena,
          }),
        ),
      }),
    );

    final sesiones = <SesionSugerida>[];
    for (final cruda in _comoLista(datos['sesiones'])) {
      if (cruda is! Map) continue;
      final dia = DateTime.tryParse(_comoTexto(cruda['fecha']));
      final hora = _horaValida(_comoTexto(cruda['hora']));
      final tema = _comoTexto(cruda['tema']);
      final duracion = cruda['duracion_minutos'];
      if (dia == null || hora == null || tema.isEmpty || duracion is! int) {
        continue;
      }
      final soloDia = DateTime(dia.year, dia.month, dia.day);
      if (soloDia.isBefore(primerDia) || soloDia.isAfter(ultimoDia)) continue;
      sesiones.add(
        SesionSugerida(
          inicio: DateTime(dia.year, dia.month, dia.day, hora.$1, hora.$2),
          duracionMinutos: duracion.clamp(15, 180),
          tema: tema,
        ),
      );
    }
    if (sesiones.isEmpty) throw respuestaInvalida();
    sesiones.sort((a, b) => a.inicio.compareTo(b.inicio));
    return sesiones;
  }

  // ---------------------------------------------------------------------------
  // Peticiones HTTP
  // ---------------------------------------------------------------------------

  /// Envía la petición que arma [crear] y devuelve la respuesta una vez aceptada.
  ///
  /// Repite la petición si el servicio está saturado. Con [corregir], el
  /// proveedor puede ajustar algo tras un error y pedir que se repita de
  /// inmediato (devolviendo `true`). Si la API responde con error, lanza lo
  /// que devuelva [errorDeEstado].
  @protected
  Future<http.StreamedResponse> enviar(
    http.BaseRequest Function() crear, {
    required ErrorIa Function(int estado, List<int> cuerpo) errorDeEstado,
    bool Function(int estado, List<int> cuerpo)? corregir,
  }) async {
    for (var intento = 0; ; intento++) {
      final http.StreamedResponse respuesta;
      final List<int> cuerpo;
      try {
        respuesta = await cliente.send(crear()).timeout(esperaRespuesta);
        if (respuesta.statusCode == 200) return respuesta;
        cuerpo = await respuesta.stream.toBytes().timeout(esperaEntreEventos);
      } on Exception catch (error) {
        throw errorDeRed(error);
      }

      if (corregir != null && corregir(respuesta.statusCode, cuerpo)) continue;
      final saturado =
          respuesta.statusCode == 429 || respuesta.statusCode >= 500;
      if (saturado && intento < _reintentos) {
        await Future<void>.delayed(pausaReintento * (intento + 1));
        continue;
      }
      throw errorDeEstado(respuesta.statusCode, cuerpo);
    }
  }

  /// Lee completo el cuerpo de una respuesta aceptada, como texto.
  @protected
  Future<String> leerCuerpo(http.StreamedResponse respuesta) async {
    final List<int> cuerpo;
    try {
      cuerpo = await respuesta.stream.toBytes().timeout(esperaRespuesta);
    } on Exception catch (error) {
      throw errorDeRed(error);
    }
    return utf8.decode(cuerpo, allowMalformed: true);
  }

  /// Lee completa una respuesta aceptada y la decodifica como objeto JSON.
  @protected
  Future<Map<String, Object?>> leerJson(http.StreamedResponse respuesta) async {
    return decodificarObjeto(await leerCuerpo(respuesta));
  }

  /// Decodifica un texto como objeto JSON; si no lo es, lanza respuesta inválida.
  @protected
  Map<String, Object?> decodificarObjeto(String texto) {
    try {
      final datos = jsonDecode(texto);
      if (datos is Map<String, Object?>) return datos;
    } on FormatException {
      // Se reporta abajo como respuesta inválida.
    }
    throw respuestaInvalida();
  }

  /// Entrega los eventos (SSE) de una respuesta en streaming, ya decodificados.
  @protected
  Stream<Map<String, Object?>> leerEventos(
    http.StreamedResponse respuesta,
  ) async* {
    final lineas = respuesta.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(esperaEntreEventos);
    try {
      await for (final linea in lineas) {
        if (!linea.startsWith('data:')) continue;
        final Object? evento;
        try {
          evento = jsonDecode(linea.substring(5));
        } on FormatException {
          continue;
        }
        if (evento is Map<String, Object?>) yield evento;
      }
    } on ErrorIa {
      rethrow;
    } on Exception catch (error) {
      throw errorDeRed(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Errores
  // ---------------------------------------------------------------------------

  /// Error para un fallo de red o de espera.
  @protected
  ErrorIa errorDeRed(Exception error) {
    if (error is ErrorIa) return error;
    if (error is TimeoutException) {
      return const ErrorIa(
        TipoErrorIa.sinConexion,
        'La IA tardó demasiado en responder. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return const ErrorIa(
        TipoErrorIa.sinConexion,
        'No hay conexión a internet. Conéctate e inténtalo de nuevo.',
      );
    }
    return const ErrorIa(
      TipoErrorIa.sinConexion,
      'No se pudo conectar con la IA. Inténtalo de nuevo.',
    );
  }

  /// Error para cuando el modelo declina responder.
  @protected
  ErrorIa rechazo() => const ErrorIa(
    TipoErrorIa.rechazo,
    'La IA no pudo responder a este contenido. Prueba con otro texto.',
  );

  /// Error para una respuesta que no tiene el formato esperado.
  @protected
  ErrorIa respuestaInvalida() => const ErrorIa(
    TipoErrorIa.respuestaInvalida,
    'La IA devolvió una respuesta que la app no pudo leer. Inténtalo de nuevo.',
  );

  /// Error para una respuesta que se cortó antes de terminar.
  @protected
  ErrorIa respuestaIncompleta() => const ErrorIa(
    TipoErrorIa.respuestaInvalida,
    'La respuesta de la IA quedó incompleta. Prueba con un apunte más corto.',
  );

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------

  /// Indicación de formato común a las respuestas con datos.
  ///
  /// Pedir "texto plano" a secas hace que a veces el modelo escriba sin
  /// tildes, por eso se pide la ortografía de forma explícita.
  static const String _formato =
      'Escribe con la ortografía normal del español, con sus tildes y eñes, '
      'y sin formato Markdown, porque la app muestra el texto tal cual.';

  static const Map<String, Object?> _cadena = {'type': 'string'};

  static Map<String, Object?> _lista(Map<String, Object?> elemento) => {
    'type': 'array',
    'items': elemento,
  };

  /// Esquema de un objeto con todas sus propiedades obligatorias.
  static Map<String, Object?> _objeto(Map<String, Object?> propiedades) => {
    'type': 'object',
    'properties': propiedades,
    'required': propiedades.keys.toList(),
    'additionalProperties': false,
  };

  static List<Object?> _comoLista(Object? valor) =>
      valor is List ? valor : const [];

  static String _comoTexto(Object? valor) =>
      valor is String ? valor.trim() : '';

  static String _fechaIso(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';

  /// Convierte `HH:MM` en (hora, minuto); `null` si no es una hora válida.
  static (int, int)? _horaValida(String texto) {
    final partes = texto.split(':');
    if (partes.length < 2) return null;
    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null) return null;
    if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59) return null;
    return (hora, minuto);
  }

  /// Junta los apuntes en un solo texto, cada uno marcado con su título.
  static String _textoApuntes(List<Apunte> apuntes) {
    final texto = StringBuffer('<apuntes>\n');
    for (final apunte in apuntes) {
      texto
        ..writeln('<apunte titulo="${apunte.titulo.replaceAll('"', "'")}">')
        ..writeln(apunte.contenido)
        ..writeln('</apunte>');
    }
    texto.write('</apuntes>');
    return texto.toString();
  }

  /// Convierte el historial del chat en turnos listos para enviar.
  ///
  /// La conversación debe empezar con el estudiante y alternar los turnos, así
  /// que se descartan los mensajes del tutor del inicio y se unen los mensajes
  /// seguidos de un mismo autor (pasa si una respuesta anterior falló).
  static List<TurnoChat> _turnosDe(List<MensajeChat> historial) {
    final turnos = <TurnoChat>[];
    for (final mensaje in historial) {
      final texto = mensaje.texto.trim();
      if (texto.isEmpty) continue;
      if (turnos.isEmpty) {
        if (!mensaje.esUsuario) continue;
      } else if (turnos.last.esUsuario == mensaje.esUsuario) {
        turnos.last = (
          esUsuario: mensaje.esUsuario,
          texto: '${turnos.last.texto}\n\n$texto',
        );
        continue;
      }
      turnos.add((esUsuario: mensaje.esUsuario, texto: texto));
    }
    // El último turno debe ser del estudiante: es la pregunta por responder.
    while (turnos.isNotEmpty && !turnos.last.esUsuario) {
      turnos.removeLast();
    }
    return turnos;
  }
}
