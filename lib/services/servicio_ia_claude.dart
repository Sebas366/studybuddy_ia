import 'dart:convert';

import 'package:http/http.dart' as http;

import 'servicio_ia.dart';
import 'servicio_ia_base.dart';

/// Servicio de IA sobre la API de mensajes de Claude (de pago por uso).
///
/// No hay SDK oficial para Dart, así que arma las peticiones HTTP a mano. Las
/// instrucciones y las validaciones están en [ServicioIaBase]; aquí solo va
/// cómo se habla con esta API.
class ServicioIaClaude extends ServicioIaBase {
  ServicioIaClaude({
    required this._clave,
    super.cliente,
    super.azar,
    super.pausaReintento,
  });

  final String _clave;

  /// Modelo que atiende todas las peticiones.
  static const String modelo = 'claude-opus-5-5';

  static const String _versionApi = '2026-10-21';
  static const String _betaRespaldo = 'server-side-fallback-2026-07-01';
  static final Uri _urlMensajes = Uri.parse(
    'https://api.anthropic.com/v1/messages',
  );
  static final Uri _urlModelo = Uri.parse(
    'https://api.anthropic.com/v1/models/$modelo',
  );

  /// Tope de la respuesta. El razonamiento interno del modelo también cuenta,
  /// así que se deja holgado para no cortar respuestas a la mitad.
  static const int _maxTokens = 16000;

  /// Si es `true`, se pide que otro modelo atienda la petición cuando el
  /// principal la decline. Se apaga solo si la cuenta no admite esa opción.
  bool _conRespaldo = true;

  /// Arma la petición; se llama en cada intento porque el respaldo puede apagarse.
  http.Request _peticion(Map<String, Object?> cuerpo) {
    return http.Request('POST', _urlMensajes)
      ..headers.addAll({
        'content-type': 'application/json',
        'x-api-key': _clave,
        'anthropic-version': _versionApi,
        if (_conRespaldo) 'anthropic-beta': _betaRespaldo,
      })
      ..body = jsonEncode({
        'model': modelo,
        'max_tokens': _maxTokens,
        if (_conRespaldo) 'fallbacks': 'default',
        ...cuerpo,
      });
  }

  @override
  Future<Map<String, Object?>> pedirJson({
    required String sistema,
    required String texto,
    ImagenIa? imagen,
    required Map<String, Object?> esquema,
  }) async {
    final cuerpo = {
      'system': sistema,
      'messages': [
        {
          'role': 'user',
          'content': [
            if (imagen != null)
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': imagen.tipoMime,
                  'data': base64Encode(imagen.bytes),
                },
              },
            {'type': 'text', 'text': texto},
          ],
        },
      ],
      'output_config': {
        'effort': 'medium',
        'format': {'type': 'json_schema', 'schema': esquema},
      },
    };
    final mensaje = await leerJson(
      await enviar(
        () => _peticion(cuerpo),
        errorDeEstado: _errorDeEstado,
        corregir: _apagarRespaldoSiNoSeAdmite,
      ),
    );

    // Antes de leer el contenido hay que mirar por qué terminó la respuesta.
    switch (mensaje['stop_reason']) {
      case 'refusal':
        throw rechazo();
      case 'max_tokens':
        throw respuestaIncompleta();
    }

    final respuesta = StringBuffer();
    final bloques = mensaje['content'];
    for (final bloque in bloques is List ? bloques : const []) {
      if (bloque is Map && bloque['type'] == 'text') {
        respuesta.write(bloque['text']);
      }
    }
    return decodificarObjeto(respuesta.toString());
  }

  @override
  Stream<String> pedirRespuesta({
    required String sistema,
    required List<TurnoChat> turnos,
  }) async* {
    final cuerpo = {
      // Los apuntes no cambian entre mensajes: se marcan para la caché de la API.
      'system': [
        {
          'type': 'text',
          'text': sistema,
          'cache_control': {'type': 'ephemeral'},
        },
      ],
      'messages': [
        for (final turno in turnos)
          {
            'role': turno.esUsuario ? 'user' : 'assistant',
            'content': turno.texto,
          },
      ],
      'output_config': {'effort': 'low'},
      'stream': true,
    };
    final respuesta = await enviar(
      () => _peticion(cuerpo),
      errorDeEstado: _errorDeEstado,
      corregir: _apagarRespaldoSiNoSeAdmite,
    );

    await for (final evento in leerEventos(respuesta)) {
      switch (evento['type']) {
        case 'content_block_delta':
          final delta = evento['delta'];
          if (delta is Map && delta['type'] == 'text_delta') {
            final parte = delta['text'];
            if (parte is String && parte.isNotEmpty) yield parte;
          }
        case 'message_delta':
          final delta = evento['delta'];
          if (delta is Map && delta['stop_reason'] == 'refusal') {
            throw rechazo();
          }
        case 'error':
          throw const ErrorIa(
            TipoErrorIa.servicio,
            'El servicio de IA se interrumpió. Inténtalo de nuevo.',
          );
      }
    }
  }

  @override
  Future<void> probarConexion() async {
    // Consultar el modelo no gasta saldo y confirma que la clave sirve y que
    // la cuenta tiene acceso al modelo.
    final http.Response respuesta;
    try {
      respuesta = await cliente
          .get(
            _urlModelo,
            headers: {'x-api-key': _clave, 'anthropic-version': _versionApi},
          )
          .timeout(const Duration(seconds: 30));
    } on Exception catch (error) {
      throw errorDeRed(error);
    }
    if (respuesta.statusCode != 200) {
      throw _errorDeEstado(respuesta.statusCode, respuesta.bodyBytes);
    }
  }

  /// Si la cuenta no admite el modelo de respaldo, lo apaga para reintentar sin él.
  ///
  /// Devuelve `true` cuando hay que repetir la petición.
  bool _apagarRespaldoSiNoSeAdmite(int estado, List<int> cuerpo) {
    if (estado != 400 || !_conRespaldo) return false;
    final detalle = _detalleDelError(cuerpo);
    if (!detalle.contains('anthropic-beta') && !detalle.contains('fallbacks')) {
      return false;
    }
    _conRespaldo = false;
    return true;
  }

  /// Extrae el mensaje de error que devuelve la API (vacío si no se entiende).
  String _detalleDelError(List<int> cuerpo) {
    try {
      final datos = jsonDecode(utf8.decode(cuerpo, allowMalformed: true));
      if (datos is Map && datos['error'] is Map) {
        final mensaje = (datos['error'] as Map)['message'];
        if (mensaje is String) return mensaje;
      }
    } on FormatException {
      // Un cuerpo que no es JSON no aporta detalle.
    }
    return '';
  }

  ErrorIa _errorDeEstado(int estado, List<int> cuerpo) {
    final detalle = _detalleDelError(cuerpo);
    if (detalle.toLowerCase().contains('credit balance')) {
      return _sinSaldo();
    }
    return switch (estado) {
      401 => const ErrorIa(
        TipoErrorIa.claveInvalida,
        'La clave de la API no es válida. Revísala en Perfil.',
      ),
      402 || 403 => _sinSaldo(),
      404 => const ErrorIa(
        TipoErrorIa.sinSaldo,
        'Tu cuenta no tiene acceso al modelo de IA que usa la app.',
      ),
      413 => const ErrorIa(
        TipoErrorIa.respuestaInvalida,
        'El contenido es demasiado grande para enviarlo a la IA.',
      ),
      429 => const ErrorIa(
        TipoErrorIa.limite,
        'Hiciste muchas peticiones seguidas. Espera un momento e inténtalo de nuevo.',
      ),
      >= 500 => const ErrorIa(
        TipoErrorIa.servicio,
        'El servicio de IA está saturado. Inténtalo de nuevo en un momento.',
      ),
      _ => ErrorIa(
        TipoErrorIa.respuestaInvalida,
        detalle.isEmpty
            ? 'La IA no aceptó la petición (error $estado).'
            : 'La IA no aceptó la petición: $detalle',
      ),
    };
  }

  ErrorIa _sinSaldo() => const ErrorIa(
    TipoErrorIa.sinSaldo,
    'Tu cuenta de la API no tiene saldo o permiso para esta petición.',
  );
}
