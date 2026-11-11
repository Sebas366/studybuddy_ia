import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studybuddy_ia/models/apunte.dart';
import 'package:studybuddy_ia/models/mensaje_chat.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';
import 'package:studybuddy_ia/services/servicio_ia_gemini.dart';

/// Interacción terminada cuyo modelo respondió [texto].
http.Response interaccionConTexto(String texto, {String estado = 'completed'}) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'id': 'v1_abc',
        'object': 'interaction',
        'status': estado,
        'model': 'gemini-3.6-flash',
        'steps': [
          // El modelo razona antes de responder; ese paso no trae la respuesta.
          {'type': 'thought'},
          {
            'type': 'model_output',
            'content': [
              {'type': 'text', 'text': texto},
            ],
          },
        ],
      }),
    ),
    200,
    headers: {'content-type': 'application/json'},
  );
}

http.Response errorDeGoogle(int estado, String codigo, String mensaje) {
  return http.Response(
    jsonEncode({
      'error': {'code': estado, 'message': mensaje, 'status': codigo},
    }),
    estado,
  );
}

/// Cuerpo de eventos (SSE) como los envía la API en streaming.
String eventos(List<Map<String, Object?>> lista) {
  return lista.map((evento) => 'data: ${jsonEncode(evento)}\n').join('\n');
}

Map<String, Object?> deltaDeTexto(String texto) => {
  'event_type': 'step.delta',
  'index': 1,
  'delta': {'type': 'text', 'text': texto},
};

const apunte = Apunte(
  id: 'a1',
  titulo: 'Pipeline',
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

const resumenJson = {
  'resumen_corto': 'c',
  'resumen_medio': 'm',
  'resumen_detallado': 'd',
  'ideas_clave': ['i'],
};

void main() {
  /// Peticiones que recibió el cliente falso, en orden.
  late List<http.Request> peticiones;

  ServicioIaGemini servicioCon(MockClientHandler manejador) {
    peticiones = [];
    return ServicioIaGemini(
      clave: 'AIza-prueba',
      cliente: MockClient((peticion) {
        peticiones.add(peticion);
        return manejador(peticion);
      }),
      pausaReintento: Duration.zero,
    );
  }

  ServicioIaGemini servicioStreaming(String cuerpo, {int estado = 200}) {
    peticiones = [];
    return ServicioIaGemini(
      clave: 'AIza-prueba',
      cliente: MockClient.streaming((peticion, flujo) async {
        peticiones.add(
          http.Request(peticion.method, peticion.url)
            ..headers.addAll(peticion.headers)
            ..body = await flujo.bytesToString(),
        );
        return http.StreamedResponse(Stream.value(utf8.encode(cuerpo)), estado);
      }),
      pausaReintento: Duration.zero,
    );
  }

  Map<String, Object?> cuerpo(http.Request peticion) =>
      jsonDecode(peticion.body) as Map<String, Object?>;

  Future<void> resumir(ServicioIaGemini servicio) =>
      servicio.resumirApunte(materia: 'm', titulo: 't', contenido: 'c');

  Matcher errorDeTipo(TipoErrorIa tipo) =>
      throwsA(isA<ErrorIa>().having((e) => e.tipo, 'tipo', tipo));

  group('petición con datos', () {
    test('lleva la clave, el modelo, el esquema y no guarda la conversación', () async {
      final servicio = servicioCon(
        (_) async => interaccionConTexto(jsonEncode(resumenJson)),
      );

      final resumen = await servicio.resumirApunte(
        materia: 'Arquitectura',
        titulo: 'Pipeline',
        contenido: 'Texto del apunte',
      );
      expect(resumen.medio, 'm');
      expect(resumen.ideasClave, ['i']);

      final peticion = peticiones.single;
      expect(peticion.method, 'POST');
      expect(
        peticion.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/interactions',
      );
      expect(peticion.headers['x-goog-api-key'], 'AIza-prueba');

      final datos = cuerpo(peticion);
      expect(datos['model'], 'gemini-3.6-flash');
      expect(datos['store'], false);
      expect(datos['system_instruction'], contains('Resumes apuntes'));

      final formato = datos['response_format'] as Map;
      expect(formato['type'], 'text');
      expect(formato['mime_type'], 'application/json');
      expect(
        (formato['schema'] as Map)['required'],
        containsAll(['resumen_corto', 'resumen_medio', 'ideas_clave']),
      );

      final entrada = (datos['input'] as List).single as Map;
      expect(entrada['type'], 'text');
      expect(entrada['text'], contains('Texto del apunte'));
    });

    test('la foto de un apunte va en base64 antes del texto', () async {
      final servicio = servicioCon(
        (_) async => interaccionConTexto(
          jsonEncode({'titulo': 'DHCP', 'contenido': 'DORA', 'legible': true}),
        ),
      );

      final escaneado = await servicio.transcribirImagen(
        imagen: Uint8List.fromList([1, 2, 3]),
        tipoMime: 'image/png',
        materia: 'Redes',
      );

      expect(escaneado.titulo, 'DHCP');
      final entrada = cuerpo(peticiones.single)['input'] as List;
      expect(entrada.first, {
        'type': 'image',
        'data': base64Encode([1, 2, 3]),
        'mime_type': 'image/png',
      });
      expect((entrada.last as Map)['type'], 'text');
    });

    test('el quiz se arma con los apuntes y las opciones quedan barajadas', () async {
      final servicio = servicioCon(
        (_) async => interaccionConTexto(
          jsonEncode({
            'preguntas': [
              {
                'enunciado': 'P',
                'opciones': ['Correcta', 'B', 'C', 'D'],
                'indice_correcta': 0,
                'explicacion': 'Porque sí.',
              },
            ],
          }),
        ),
      );

      final preguntas = await servicio.generarQuiz(
        materia: 'Arquitectura',
        apuntes: const [apunte],
      );

      final pregunta = preguntas.single;
      expect(pregunta.opciones[pregunta.indiceRespuestaCorrecta], 'Correcta');
      final entrada = (cuerpo(peticiones.single)['input'] as List).single as Map;
      expect(entrada['text'], contains('El pipeline tiene cinco etapas.'));
    });

    test('acepta la interacción envuelta en una lista', () async {
      final servicio = servicioCon((_) async {
        final suelta = interaccionConTexto(jsonEncode(resumenJson));
        return http.Response.bytes(
          utf8.encode('[${utf8.decode(suelta.bodyBytes)}]'),
          200,
        );
      });

      final resumen = await servicio.resumirApunte(
        materia: 'm',
        titulo: 't',
        contenido: 'c',
      );

      expect(resumen.medio, 'm');
    });

    test('una respuesta que no es JSON es un error de respuesta inválida', () {
      final servicio = servicioCon((_) async => interaccionConTexto('hola'));

      expect(resumir(servicio), errorDeTipo(TipoErrorIa.respuestaInvalida));
    });

    test('una interacción incompleta es un error', () {
      final servicio = servicioCon(
        (_) async => interaccionConTexto('{"resumen', estado: 'incomplete'),
      );

      expect(resumir(servicio), errorDeTipo(TipoErrorIa.respuestaInvalida));
    });

    test('una interacción fallida es un error del servicio', () {
      final servicio = servicioCon(
        (_) async => interaccionConTexto('', estado: 'failed'),
      );

      expect(resumir(servicio), errorDeTipo(TipoErrorIa.servicio));
    });

    test('si el modelo no escribe nada, es un rechazo', () {
      final servicio = servicioCon((_) async => interaccionConTexto(''));

      expect(resumir(servicio), errorDeTipo(TipoErrorIa.rechazo));
    });
  });

  group('responderTutor', () {
    Future<List<String>> preguntar(
      ServicioIaGemini servicio,
      List<MensajeChat> historial,
    ) {
      return servicio
          .responderTutor(
            materia: 'Arquitectura',
            nombreEstudiante: 'Edwin',
            apuntes: const [apunte],
            historial: historial,
          )
          .toList();
    }

    test('entrega el texto por partes e ignora los demás eventos', () async {
      final servicio = servicioStreaming(
        eventos([
          {
            'event_type': 'interaction.created',
            'interaction': {'id': 'v1_abc', 'status': 'in_progress'},
          },
          {
            'event_type': 'step.start',
            'index': 0,
            'step': {'type': 'thought'},
          },
          {
            'event_type': 'step.delta',
            'index': 0,
            'delta': {'type': 'thought_summary', 'text': 'razonando'},
          },
          {'event_type': 'step.stop', 'index': 0},
          deltaDeTexto('Hola, '),
          deltaDeTexto('¿qué dudas tienes?'),
          {
            'event_type': 'interaction.completed',
            'interaction': {'id': 'v1_abc', 'status': 'completed'},
          },
        ]),
      );

      final partes = await preguntar(servicio, [
        mensaje('¿Qué es el pipeline?', esUsuario: true),
      ]);

      expect(partes, ['Hola, ', '¿qué dudas tienes?']);
    });

    test('pide streaming y manda la conversación completa por turnos', () async {
      final servicio = servicioStreaming(eventos([deltaDeTexto('ok')]));

      await preguntar(servicio, [
        mensaje('Saludo del tutor', esUsuario: false),
        mensaje('Primera', esUsuario: true),
        mensaje('Respuesta', esUsuario: false),
        mensaje('Segunda', esUsuario: true),
      ]);

      final peticion = peticiones.single;
      expect(
        peticion.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/interactions?alt=sse',
      );
      final datos = cuerpo(peticion);
      expect(datos['stream'], true);
      expect(datos['store'], false);
      expect(datos['system_instruction'], contains('Edwin'));
      expect(
        datos['system_instruction'],
        contains('El pipeline tiene cinco etapas.'),
      );

      final turnos = datos['input'] as List;
      expect(turnos.map((t) => (t as Map)['type']), [
        'user_input',
        'model_output',
        'user_input',
      ]);
      expect(((turnos.first as Map)['content'] as List).single, {
        'type': 'text',
        'text': 'Primera',
      });
    });

    test('un error a mitad de la respuesta corta el flujo', () {
      final servicio = servicioStreaming(
        eventos([
          deltaDeTexto('Empiezo'),
          {
            'event_type': 'error',
            'error': {'code': 'unavailable', 'message': 'Overloaded'},
          },
        ]),
      );

      expect(
        preguntar(servicio, [mensaje('Hola', esUsuario: true)]),
        errorDeTipo(TipoErrorIa.servicio),
      );
    });

    test('si la interacción termina fallida, es un error del servicio', () {
      final servicio = servicioStreaming(
        eventos([
          deltaDeTexto('Empiezo'),
          {
            'event_type': 'interaction.status_update',
            'interaction_id': 'v1_abc',
            'status': 'failed',
          },
        ]),
      );

      expect(
        preguntar(servicio, [mensaje('Hola', esUsuario: true)]),
        errorDeTipo(TipoErrorIa.servicio),
      );
    });

    test('una clave mala se reporta antes de empezar', () {
      final servicio = servicioStreaming(
        jsonEncode({
          'error': {
            'code': 400,
            'message': 'API key not valid. Please pass a valid API key.',
            'status': 'INVALID_ARGUMENT',
          },
        }),
        estado: 400,
      );

      expect(
        preguntar(servicio, [mensaje('Hola', esUsuario: true)]),
        errorDeTipo(TipoErrorIa.claveInvalida),
      );
    });
  });

  group('probarConexion', () {
    test('consulta el modelo sin gastar cuota', () async {
      final servicio = servicioCon((_) async => http.Response('{}', 200));

      await servicio.probarConexion();

      final peticion = peticiones.single;
      expect(peticion.method, 'GET');
      expect(
        peticion.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash',
      );
      expect(peticion.headers['x-goog-api-key'], 'AIza-prueba');
    });

    test('una clave mala se reporta como clave inválida', () {
      final servicio = servicioCon(
        (_) async => errorDeGoogle(
          400,
          'INVALID_ARGUMENT',
          'API key not valid. Please pass a valid API key.',
        ),
      );

      expect(servicio.probarConexion(), errorDeTipo(TipoErrorIa.claveInvalida));
    });
  });

  group('errores', () {
    test('cada código de la API se traduce a su tipo de error', () async {
      final casos = {
        401: TipoErrorIa.claveInvalida,
        403: TipoErrorIa.sinSaldo,
        404: TipoErrorIa.sinSaldo,
        413: TipoErrorIa.respuestaInvalida,
        429: TipoErrorIa.limite,
        500: TipoErrorIa.servicio,
        503: TipoErrorIa.servicio,
      };
      for (final caso in casos.entries) {
        final servicio = servicioCon(
          (_) async => errorDeGoogle(caso.key, 'X', 'detalle'),
        );
        await expectLater(
          resumir(servicio),
          errorDeTipo(caso.value),
          reason: 'código ${caso.key}',
        );
      }
    });

    test('una clave mala se reconoce con el error real de la API', () {
      // Así responde hoy la API a una clave inválida: error 400 dentro de una lista.
      final servicio = servicioCon(
        (_) async => http.Response(
          jsonEncode([
            {
              'error': {
                'code': 400,
                'message': 'API key not valid. Please pass a valid API key.',
                'status': 'INVALID_ARGUMENT',
              },
            },
          ]),
          400,
        ),
      );

      expect(resumir(servicio), errorDeTipo(TipoErrorIa.claveInvalida));
    });

    test('el límite del plan gratuito lo dice con sus palabras', () {
      final servicio = servicioCon(
        (_) async => errorDeGoogle(429, 'RESOURCE_EXHAUSTED', 'Quota exceeded'),
      );

      expect(
        resumir(servicio),
        throwsA(
          isA<ErrorIa>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('plan gratuito'),
          ),
        ),
      );
    });

    test('un error 400 que no es de la clave muestra el detalle', () {
      final servicio = servicioCon(
        (_) async => errorDeGoogle(400, 'INVALID_ARGUMENT', 'Schema too complex'),
      );

      expect(
        resumir(servicio),
        throwsA(
          isA<ErrorIa>()
              .having((e) => e.tipo, 'tipo', TipoErrorIa.respuestaInvalida)
              .having((e) => e.mensaje, 'mensaje', contains('Schema too complex')),
        ),
      );
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
        if (intentos < 3) return errorDeGoogle(503, 'UNAVAILABLE', 'Overloaded');
        return interaccionConTexto(jsonEncode(resumenJson));
      });

      await resumir(servicio);

      expect(intentos, 3);
    });
  });
}
