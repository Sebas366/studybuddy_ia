import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studybuddy_ia/models/apunte.dart';
import 'package:studybuddy_ia/models/mensaje_chat.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';
import 'package:studybuddy_ia/services/servicio_ia_claude.dart';

/// Respuesta de la API con un solo bloque de texto.
http.Response respuestaConTexto(String texto, {String motivo = 'end_turn'}) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'type': 'message',
        'role': 'assistant',
        'stop_reason': motivo,
        'content': [
          // El modelo razona antes de responder; ese bloque no trae texto útil.
          {'type': 'thinking', 'thinking': ''},
          {'type': 'text', 'text': texto},
        ],
      }),
    ),
    200,
    headers: {'content-type': 'application/json'},
  );
}

http.Response respuestaDeError(int estado, String tipo, String mensaje) {
  return http.Response(
    jsonEncode({
      'type': 'error',
      'error': {'type': tipo, 'message': mensaje},
    }),
    estado,
  );
}

/// Cuerpo de eventos (SSE) como los envía la API en streaming.
String eventos(List<Map<String, Object?>> lista) {
  return lista
      .map((evento) => 'event: ${evento['type']}\ndata: ${jsonEncode(evento)}\n')
      .join('\n');
}

Map<String, Object?> deltaDeTexto(String texto) => {
  'type': 'content_block_delta',
  'index': 1,
  'delta': {'type': 'text_delta', 'text': texto},
};

const apunte = Apunte(
  id: 'a1',
  titulo: 'Pipeline "MIPS"',
  materiaId: 'm1',
  fecha: '1 Nov 2026',
  contenido: 'El pipeline tiene cinco etapas.',
);

MensajeChat mensaje(String texto, {required bool esUsuario}) => MensajeChat(
  id: texto,
  texto: texto,
  esUsuario: esUsuario,
  fecha: DateTime(2026, 11, 1),
);

void main() {
  /// Peticiones que recibió el cliente falso, en orden.
  late List<http.Request> peticiones;

  ServicioIaClaude servicioCon(MockClientHandler manejador) {
    peticiones = [];
    return ServicioIaClaude(
      clave: 'sk-prueba',
      cliente: MockClient((peticion) {
        peticiones.add(peticion);
        return manejador(peticion);
      }),
      azar: Random(7),
      pausaReintento: Duration.zero,
    );
  }

  Map<String, Object?> cuerpo(http.Request peticion) =>
      jsonDecode(peticion.body) as Map<String, Object?>;

  group('petición', () {
    test('lleva la clave, la versión de la API, el modelo y el esquema', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          jsonEncode({
            'resumen_corto': 'c',
            'resumen_medio': 'm',
            'resumen_detallado': 'd',
            'ideas_clave': ['i'],
          }),
        ),
      );

      await servicio.resumirApunte(
        materia: 'Arquitectura',
        titulo: 'Pipeline',
        contenido: 'Texto del apunte',
      );

      final peticion = peticiones.single;
      expect(peticion.method, 'POST');
      expect(peticion.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(peticion.headers['x-api-key'], 'sk-prueba');
      expect(peticion.headers['anthropic-version'], '2026-10-21');
      expect(
        peticion.headers['anthropic-beta'],
        'server-side-fallback-2026-07-01',
      );

      final datos = cuerpo(peticion);
      expect(datos['model'], 'claude-opus-5-5');
      expect(datos['fallbacks'], 'default');
      expect(datos['max_tokens'], greaterThanOrEqualTo(16000));
      // La versión actual de la API rechaza los parámetros de muestreo.
      expect(datos.containsKey('temperature'), isFalse);

      final salida = datos['output_config'] as Map;
      final formato = salida['format'] as Map;
      expect(formato['type'], 'json_schema');
      final esquema = formato['schema'] as Map;
      expect(esquema['additionalProperties'], false);
      expect(
        esquema['required'],
        containsAll(['resumen_corto', 'resumen_medio', 'ideas_clave']),
      );

      final contenido =
          ((datos['messages'] as List).single as Map)['content'] as List;
      expect((contenido.single as Map)['text'], contains('Texto del apunte'));
    });
  });

  group('resumirApunte', () {
    test('devuelve los tres niveles y las ideas clave', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          jsonEncode({
            'resumen_corto': ' Corto ',
            'resumen_medio': 'Medio con acentos: caché',
            'resumen_detallado': 'Detallado',
            'ideas_clave': ['Una', ' ', 'Dos'],
          }),
        ),
      );

      final resumen = await servicio.resumirApunte(
        materia: 'm',
        titulo: 't',
        contenido: 'c',
      );

      expect(resumen.corto, 'Corto');
      expect(resumen.medio, 'Medio con acentos: caché');
      expect(resumen.detallado, 'Detallado');
      expect(resumen.ideasClave, ['Una', 'Dos']);
    });

    test('una respuesta que no es JSON es un error de respuesta inválida', () {
      final servicio = servicioCon((_) async => respuestaConTexto('hola'));

      expect(
        servicio.resumirApunte(materia: 'm', titulo: 't', contenido: 'c'),
        throwsA(
          isA<ErrorIa>().having(
            (e) => e.tipo,
            'tipo',
            TipoErrorIa.respuestaInvalida,
          ),
        ),
      );
    });

    test('si el modelo declina, es un error de rechazo', () {
      final servicio = servicioCon(
        (_) async => respuestaConTexto('', motivo: 'refusal'),
      );

      expect(
        servicio.resumirApunte(materia: 'm', titulo: 't', contenido: 'c'),
        throwsA(
          isA<ErrorIa>().having((e) => e.tipo, 'tipo', TipoErrorIa.rechazo),
        ),
      );
    });

    test('una respuesta cortada por el tope de tokens es un error', () {
      final servicio = servicioCon(
        (_) async => respuestaConTexto('{"resumen', motivo: 'max_tokens'),
      );

      expect(
        servicio.resumirApunte(materia: 'm', titulo: 't', contenido: 'c'),
        throwsA(
          isA<ErrorIa>().having(
            (e) => e.tipo,
            'tipo',
            TipoErrorIa.respuestaInvalida,
          ),
        ),
      );
    });
  });

  group('generarQuiz', () {
    String quizJson(List<Map<String, Object?>> preguntas) =>
        jsonEncode({'preguntas': preguntas});

    test('baraja las opciones y conserva cuál es la correcta', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          quizJson([
            for (var i = 0; i < 6; i++)
              {
                'enunciado': 'Pregunta $i',
                'opciones': ['Correcta $i', 'B', 'C', 'D'],
                'indice_correcta': 0,
                'explicacion': 'Porque sí.',
              },
          ]),
        ),
      );

      final preguntas = await servicio.generarQuiz(
        materia: 'Arquitectura',
        apuntes: const [apunte],
        cantidad: 6,
      );

      expect(preguntas, hasLength(6));
      for (var i = 0; i < preguntas.length; i++) {
        final pregunta = preguntas[i];
        expect(pregunta.opciones, hasLength(4));
        expect(
          pregunta.opciones[pregunta.indiceRespuestaCorrecta],
          'Correcta $i',
        );
      }
      // Con seis preguntas, la correcta no puede quedar siempre en la primera posición.
      expect(
        preguntas.map((p) => p.indiceRespuestaCorrecta).toSet().length,
        greaterThan(1),
      );
    });

    test('envía los apuntes con su título', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          quizJson([
            {
              'enunciado': 'P',
              'opciones': ['A', 'B'],
              'indice_correcta': 1,
              'explicacion': '',
            },
          ]),
        ),
      );

      await servicio.generarQuiz(materia: 'Arquitectura', apuntes: const [apunte]);

      final contenido =
          ((cuerpo(peticiones.single)['messages'] as List).single
                  as Map)['content']
              as List;
      final texto = (contenido.single as Map)['text'] as String;
      // Las comillas del título se cambian para no romper el marcado.
      expect(texto, contains('<apunte titulo="Pipeline \'MIPS\'">'));
      expect(texto, contains('El pipeline tiene cinco etapas.'));
    });

    test('descarta las preguntas mal formadas', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          quizJson([
            {
              'enunciado': 'Índice fuera de rango',
              'opciones': ['A', 'B'],
              'indice_correcta': 5,
              'explicacion': '',
            },
            {
              'enunciado': '',
              'opciones': ['A', 'B'],
              'indice_correcta': 0,
              'explicacion': '',
            },
            {
              'enunciado': 'Una sola opción',
              'opciones': ['A'],
              'indice_correcta': 0,
              'explicacion': '',
            },
            {
              'enunciado': 'Buena',
              'opciones': ['A', 'B'],
              'indice_correcta': 1,
              'explicacion': 'x',
            },
          ]),
        ),
      );

      final preguntas = await servicio.generarQuiz(
        materia: 'm',
        apuntes: const [apunte],
      );

      expect(preguntas.map((p) => p.enunciado), ['Buena']);
      expect(preguntas.single.opciones[preguntas.single.indiceRespuestaCorrecta], 'B');
    });

    test('si ninguna pregunta sirve, es un error', () {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(quizJson(const [])),
      );

      expect(
        servicio.generarQuiz(materia: 'm', apuntes: const [apunte]),
        throwsA(isA<ErrorIa>()),
      );
    });
  });

  group('responderTutor', () {
    ServicioIaClaude servicioStreaming(
      Future<http.StreamedResponse> Function(http.BaseRequest, String) manejador,
    ) {
      peticiones = [];
      return ServicioIaClaude(
        clave: 'sk-prueba',
        cliente: MockClient.streaming((peticion, flujo) async {
          final texto = await flujo.bytesToString();
          peticiones.add(
            http.Request(peticion.method, peticion.url)
              ..headers.addAll(peticion.headers)
              ..body = texto,
          );
          return manejador(peticion, texto);
        }),
        pausaReintento: Duration.zero,
      );
    }

    http.StreamedResponse flujoDe(String texto, {int estado = 200}) =>
        http.StreamedResponse(Stream.value(utf8.encode(texto)), estado);

    test('entrega el texto por partes e ignora los demás eventos', () async {
      final servicio = servicioStreaming(
        (_, _) async => flujoDe(
          eventos([
            {'type': 'message_start', 'message': <String, Object?>{}},
            {
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'thinking_delta', 'thinking': 'razonando'},
            },
            {'type': 'ping'},
            deltaDeTexto('Hola, '),
            deltaDeTexto('¿qué dudas tienes?'),
            {
              'type': 'message_delta',
              'delta': {'stop_reason': 'end_turn'},
            },
            {'type': 'message_stop'},
          ]),
        ),
      );

      final partes = await servicio
          .responderTutor(
            materia: 'Arquitectura',
            nombreEstudiante: 'Edwin',
            apuntes: const [apunte],
            historial: [mensaje('¿Qué es el pipeline?', esUsuario: true)],
          )
          .toList();

      expect(partes, ['Hola, ', '¿qué dudas tienes?']);
    });

    test('pide streaming y manda los apuntes en el sistema, con caché', () async {
      final servicio = servicioStreaming(
        (_, _) async => flujoDe(eventos([deltaDeTexto('ok')])),
      );

      await servicio
          .responderTutor(
            materia: 'Arquitectura',
            nombreEstudiante: 'Edwin',
            apuntes: const [apunte],
            historial: [mensaje('Hola', esUsuario: true)],
          )
          .toList();

      final datos = cuerpo(peticiones.single);
      expect(datos['stream'], true);
      final sistema = (datos['system'] as List).single as Map;
      expect(sistema['text'], contains('Arquitectura'));
      expect(sistema['text'], contains('Edwin'));
      expect(sistema['text'], contains('El pipeline tiene cinco etapas.'));
      expect(sistema['cache_control'], {'type': 'ephemeral'});
    });

    test('la conversación empieza con el estudiante y alterna los turnos', () async {
      final servicio = servicioStreaming(
        (_, _) async => flujoDe(eventos([deltaDeTexto('ok')])),
      );

      await servicio
          .responderTutor(
            materia: 'm',
            nombreEstudiante: 'n',
            apuntes: const [],
            historial: [
              mensaje('Saludo del tutor', esUsuario: false),
              mensaje('Primera', esUsuario: true),
              // La respuesta a "Primera" falló: quedaron dos preguntas seguidas.
              mensaje('Segunda', esUsuario: true),
              mensaje('Respuesta', esUsuario: false),
              mensaje('Tercera', esUsuario: true),
            ],
          )
          .toList();

      final mensajes = cuerpo(peticiones.single)['messages'] as List;
      expect(mensajes.map((m) => (m as Map)['role']), [
        'user',
        'assistant',
        'user',
      ]);
      expect((mensajes.first as Map)['content'], 'Primera\n\nSegunda');
      expect((mensajes.last as Map)['content'], 'Tercera');
    });

    test('un error antes de empezar se reporta con su tipo', () {
      final servicio = servicioStreaming(
        (_, _) async => flujoDe(
          jsonEncode({
            'type': 'error',
            'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'},
          }),
          estado: 401,
        ),
      );

      expect(
        servicio
            .responderTutor(
              materia: 'm',
              nombreEstudiante: 'n',
              apuntes: const [],
              historial: [mensaje('Hola', esUsuario: true)],
            )
            .toList(),
        throwsA(
          isA<ErrorIa>().having(
            (e) => e.tipo,
            'tipo',
            TipoErrorIa.claveInvalida,
          ),
        ),
      );
    });

    test('un error a mitad de la respuesta corta el flujo', () {
      final servicio = servicioStreaming(
        (_, _) async => flujoDe(
          eventos([
            deltaDeTexto('Empiezo'),
            {
              'type': 'error',
              'error': {'type': 'overloaded_error', 'message': 'Overloaded'},
            },
          ]),
        ),
      );

      expect(
        servicio
            .responderTutor(
              materia: 'm',
              nombreEstudiante: 'n',
              apuntes: const [],
              historial: [mensaje('Hola', esUsuario: true)],
            )
            .toList(),
        throwsA(
          isA<ErrorIa>().having((e) => e.tipo, 'tipo', TipoErrorIa.servicio),
        ),
      );
    });

    test('si el modelo declina a mitad de la respuesta, es un rechazo', () {
      final servicio = servicioStreaming(
        (_, _) async => flujoDe(
          eventos([
            deltaDeTexto('Empiezo'),
            {
              'type': 'message_delta',
              'delta': {'stop_reason': 'refusal'},
            },
          ]),
        ),
      );

      expect(
        servicio
            .responderTutor(
              materia: 'm',
              nombreEstudiante: 'n',
              apuntes: const [],
              historial: [mensaje('Hola', esUsuario: true)],
            )
            .toList(),
        throwsA(
          isA<ErrorIa>().having((e) => e.tipo, 'tipo', TipoErrorIa.rechazo),
        ),
      );
    });
  });

  group('transcribirImagen', () {
    test('envía la imagen en base64 y devuelve el texto', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          jsonEncode({
            'titulo': 'DHCP',
            'contenido': 'Discover, Offer, Request, Ack',
            'legible': true,
          }),
        ),
      );

      final escaneado = await servicio.transcribirImagen(
        imagen: Uint8List.fromList([1, 2, 3]),
        tipoMime: 'image/png',
        materia: 'Redes',
      );

      expect(escaneado.titulo, 'DHCP');
      expect(escaneado.contenido, 'Discover, Offer, Request, Ack');

      final contenido =
          ((cuerpo(peticiones.single)['messages'] as List).single
                  as Map)['content']
              as List;
      final imagen = contenido.first as Map;
      expect(imagen['type'], 'image');
      expect(imagen['source'], {
        'type': 'base64',
        'media_type': 'image/png',
        'data': base64Encode([1, 2, 3]),
      });
    });

    test('una foto sin texto legible es un error con explicación', () {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          jsonEncode({'titulo': '', 'contenido': '', 'legible': false}),
        ),
      );

      expect(
        servicio.transcribirImagen(
          imagen: Uint8List.fromList([1]),
          tipoMime: 'image/jpeg',
          materia: 'Redes',
        ),
        throwsA(
          isA<ErrorIa>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('texto legible'),
          ),
        ),
      );
    });
  });

  group('sugerirPlan', () {
    test('devuelve las sesiones ordenadas y dentro de las fechas pedidas', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          jsonEncode({
            'sesiones': [
              {
                'fecha': '2026-11-12',
                'hora': '18:30',
                'duracion_minutos': 60,
                'tema': 'Repaso general',
              },
              {
                'fecha': '2026-11-10',
                'hora': '07:00',
                'duracion_minutos': 500,
                'tema': 'Pipeline',
              },
              // El día de la evaluación ya no se estudia: se descarta.
              {
                'fecha': '2026-11-13',
                'hora': '08:00',
                'duracion_minutos': 30,
                'tema': 'Tarde',
              },
              // Antes de hoy: se descarta.
              {
                'fecha': '2026-11-01',
                'hora': '08:00',
                'duracion_minutos': 30,
                'tema': 'Pasado',
              },
              // Hora imposible: se descarta.
              {
                'fecha': '2026-11-11',
                'hora': '25:00',
                'duracion_minutos': 30,
                'tema': 'Hora mala',
              },
            ],
          }),
        ),
      );

      final sesiones = await servicio.sugerirPlan(
        materia: 'Arquitectura',
        evaluacion: 'Parcial 1',
        temas: 'Pipeline',
        apuntes: const [apunte],
        hoy: DateTime(2026, 11, 10, 9),
        fechaEvaluacion: DateTime(2026, 11, 13),
      );

      expect(sesiones.map((s) => s.tema), ['Pipeline', 'Repaso general']);
      expect(sesiones.first.inicio, DateTime(2026, 11, 10, 7));
      expect(sesiones.first.duracionMinutos, 180); // se recorta al máximo
      expect(sesiones.last.inicio, DateTime(2026, 11, 12, 18, 30));
    });

    test('si la evaluación es hoy, solo se acepta estudiar hoy', () async {
      final servicio = servicioCon(
        (_) async => respuestaConTexto(
          jsonEncode({
            'sesiones': [
              {
                'fecha': '2026-11-10',
                'hora': '10:00',
                'duracion_minutos': 45,
                'tema': 'Último repaso',
              },
            ],
          }),
        ),
      );

      final sesiones = await servicio.sugerirPlan(
        materia: 'm',
        evaluacion: 'e',
        temas: '',
        apuntes: const [],
        hoy: DateTime(2026, 11, 10),
        fechaEvaluacion: DateTime(2026, 11, 10),
      );

      expect(sesiones.single.tema, 'Último repaso');
    });
  });

  group('probarConexion', () {
    test('consulta el modelo sin gastar saldo', () async {
      final servicio = servicioCon((_) async => http.Response('{}', 200));

      await servicio.probarConexion();

      final peticion = peticiones.single;
      expect(peticion.method, 'GET');
      expect(
        peticion.url.toString(),
        'https://api.anthropic.com/v1/models/claude-opus-5-5',
      );
      expect(peticion.headers['x-api-key'], 'sk-prueba');
    });

    test('una clave mala se reporta como clave inválida', () {
      final servicio = servicioCon(
        (_) async =>
            respuestaDeError(401, 'authentication_error', 'invalid x-api-key'),
      );

      expect(
        servicio.probarConexion(),
        throwsA(
          isA<ErrorIa>().having(
            (e) => e.tipo,
            'tipo',
            TipoErrorIa.claveInvalida,
          ),
        ),
      );
    });
  });

  group('errores', () {
    Future<void> resumir(ServicioIaClaude servicio) =>
        servicio.resumirApunte(materia: 'm', titulo: 't', contenido: 'c');

    Matcher errorDeTipo(TipoErrorIa tipo) =>
        throwsA(isA<ErrorIa>().having((e) => e.tipo, 'tipo', tipo));

    test('cada código de la API se traduce a su tipo de error', () async {
      final casos = {
        401: TipoErrorIa.claveInvalida,
        402: TipoErrorIa.sinSaldo,
        403: TipoErrorIa.sinSaldo,
        404: TipoErrorIa.sinSaldo,
        413: TipoErrorIa.respuestaInvalida,
        429: TipoErrorIa.limite,
        500: TipoErrorIa.servicio,
        529: TipoErrorIa.servicio,
      };
      for (final caso in casos.entries) {
        final servicio = servicioCon(
          (_) async => respuestaDeError(caso.key, 'x', 'detalle'),
        );
        await expectLater(
          resumir(servicio),
          errorDeTipo(caso.value),
          reason: 'código ${caso.key}',
        );
      }
    });

    test('la falta de saldo se reconoce aunque llegue como error 400', () {
      final servicio = servicioCon(
        (_) async => respuestaDeError(
          400,
          'invalid_request_error',
          'Your credit balance is too low to access the API.',
        ),
      );

      expect(resumir(servicio), errorDeTipo(TipoErrorIa.sinSaldo));
    });

    test('sin internet se reporta como falta de conexión', () {
      final servicio = servicioCon(
        (_) async => throw const SocketException('sin red'),
      );

      expect(resumir(servicio), errorDeTipo(TipoErrorIa.sinConexion));
    });

    test('un servicio saturado se reintenta hasta que responde', () async {
      var intentos = 0;
      final servicio = servicioCon((_) async {
        intentos++;
        if (intentos < 3) {
          return respuestaDeError(529, 'overloaded_error', 'Overloaded');
        }
        return respuestaConTexto(
          jsonEncode({
            'resumen_corto': 'c',
            'resumen_medio': 'm',
            'resumen_detallado': 'd',
            'ideas_clave': <String>[],
          }),
        );
      });

      await resumir(servicio);

      expect(intentos, 3);
    });

    test('un error que no es de saturación no se reintenta', () async {
      final servicio = servicioCon(
        (_) async => respuestaDeError(401, 'authentication_error', 'x'),
      );

      await expectLater(
        resumir(servicio),
        errorDeTipo(TipoErrorIa.claveInvalida),
      );
      expect(peticiones, hasLength(1));
    });

    test('si la cuenta no admite el modelo de respaldo, repite sin él', () async {
      final servicio = servicioCon((peticion) async {
        if (peticion.headers.containsKey('anthropic-beta')) {
          return respuestaDeError(
            400,
            'invalid_request_error',
            'Unexpected value(s) `server-side-fallback-2026-07-01` for the '
                '`anthropic-beta` header.',
          );
        }
        return respuestaConTexto(
          jsonEncode({
            'resumen_corto': 'c',
            'resumen_medio': 'm',
            'resumen_detallado': 'd',
            'ideas_clave': <String>[],
          }),
        );
      });

      await resumir(servicio);
      await resumir(servicio);

      // La primera petición falla, se repite sin respaldo y la siguiente ya va sin él.
      expect(peticiones, hasLength(3));
      expect(cuerpo(peticiones[0])['fallbacks'], 'default');
      expect(cuerpo(peticiones[1]).containsKey('fallbacks'), isFalse);
      expect(peticiones[2].headers.containsKey('anthropic-beta'), isFalse);
    });
  });
}
