import 'dart:convert';

import 'package:http/http.dart' as http;

import 'servicio_ia.dart';
import 'servicio_ia_base.dart';

/// Servicio de IA sobre la API de Gemini (Interactions API), que tiene un
/// nivel gratuito.
///
/// Las instrucciones y las validaciones están en [ServicioIaBase]; aquí solo va
/// cómo se habla con esta API. Cada petición lleva la conversación completa y
/// pide que no se guarde en el servidor (`store: false`).
class ServicioIaGemini extends ServicioIaBase {
  ServicioIaGemini({
    required this._clave,
    super.cliente,
    super.azar,
    super.pausaReintento,
  });

  final String _clave;

  /// Modelo que atiende todas las peticiones (incluido en el nivel gratuito).
  static const String modelo = 'gemini-3.6-flash';

  static const String _base = 'https://generativelanguage.googleapis.com/v1beta';
  static final Uri _urlInteracciones = Uri.parse('$_base/interactions');
  static final Uri _urlStreaming = Uri.parse('$_base/interactions?alt=sse');
  static final Uri _urlModelo = Uri.parse('$_base/models/$modelo');

  Map<String, String> get _cabeceras => {
    'content-type': 'application/json',
    'x-goog-api-key': _clave,
  };

  http.Request _peticion(Uri url, Map<String, Object?> cuerpo) {
    return http.Request('POST', url)
      ..headers.addAll(_cabeceras)
      ..body = jsonEncode({'model': modelo, 'store': false, ...cuerpo});
  }

  @override
  Future<Map<String, Object?>> pedirJson({
    required String sistema,
    required String texto,
    ImagenIa? imagen,
    required Map<String, Object?> esquema,
  }) async {
    final cuerpo = {
      'system_instruction': sistema,
      'input': [
        if (imagen != null)
          {
            'type': 'image',
            'data': base64Encode(imagen.bytes),
            'mime_type': imagen.tipoMime,
          },
        {'type': 'text', 'text': texto},
      ],
      'response_format': {
        'type': 'text',
        'mime_type': 'application/json',
        'schema': esquema,
      },
    };
    final interaccion = _interaccionDe(
      await leerCuerpo(
        await enviar(
          () => _peticion(_urlInteracciones, cuerpo),
          errorDeEstado: _errorDeEstado,
        ),
      ),
    );

    _exigirCompletada(interaccion);
    final respuesta = _textoDe(interaccion);
    // Sin texto y sin error: el modelo no quiso o no pudo responder.
    if (respuesta.trim().isEmpty) throw rechazo();
    return decodificarObjeto(respuesta);
  }

  @override
  Stream<String> pedirRespuesta({
    required String sistema,
    required List<TurnoChat> turnos,
  }) async* {
    final cuerpo = {
      'system_instruction': sistema,
      'input': [
        for (final turno in turnos)
          {
            'type': turno.esUsuario ? 'user_input' : 'model_output',
            'content': [
              {'type': 'text', 'text': turno.texto},
            ],
          },
      ],
      'stream': true,
    };
    final respuesta = await enviar(
      () => _peticion(_urlStreaming, cuerpo),
      errorDeEstado: _errorDeEstado,
    );

    await for (final evento in leerEventos(respuesta)) {
      switch (evento['event_type']) {
        case 'step.delta':
          final delta = evento['delta'];
          if (delta is Map && delta['type'] == 'text') {
            final parte = delta['text'];
            if (parte is String && parte.isNotEmpty) yield parte;
          }
        case 'interaction.completed':
          final interaccion = evento['interaction'];
          if (interaccion is Map<String, Object?>) {
            _exigirCompletada(interaccion);
          }
        case 'interaction.status_update':
          _exigirCompletada({'status': evento['status']});
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
    // Consultar el modelo no gasta cuota y confirma que la clave sirve.
    final http.Response respuesta;
    try {
      respuesta = await cliente
          .get(_urlModelo, headers: {'x-goog-api-key': _clave})
          .timeout(const Duration(seconds: 30));
    } on Exception catch (error) {
      throw errorDeRed(error);
    }
    if (respuesta.statusCode != 200) {
      throw _errorDeEstado(respuesta.statusCode, respuesta.bodyBytes);
    }
  }

  /// Decodifica el cuerpo de una respuesta y devuelve la interacción que trae.
  ///
  /// Esta API a veces envuelve su respuesta en una lista (lo hace con los
  /// errores), así que se acepta el objeto suelto o dentro de una lista.
  Map<String, Object?> _interaccionDe(String cuerpo) {
    final Object? datos;
    try {
      datos = jsonDecode(cuerpo);
    } on FormatException {
      throw respuestaInvalida();
    }
    for (final candidato in datos is List ? datos : [datos]) {
      if (candidato is! Map<String, Object?>) continue;
      final envuelta = candidato['interaction'];
      if (envuelta is Map<String, Object?>) return envuelta;
      if (candidato.containsKey('steps') || candidato.containsKey('status')) {
        return candidato;
      }
    }
    throw respuestaInvalida();
  }

  /// Lanza el error que corresponda si la interacción no terminó bien.
  ///
  /// Los estados intermedios (`in_progress`) y `completed` no lanzan.
  void _exigirCompletada(Map<String, Object?> interaccion) {
    switch (interaccion['status']) {
      case 'incomplete' || 'requires_continuation':
        throw respuestaIncompleta();
      case 'failed' || 'cancelled':
        throw const ErrorIa(
          TipoErrorIa.servicio,
          'La IA no pudo terminar la respuesta. Inténtalo de nuevo.',
        );
    }
  }

  /// Junta el texto que escribió el modelo en una interacción.
  String _textoDe(Map<String, Object?> interaccion) {
    final texto = StringBuffer();
    final pasos = interaccion['steps'];
    for (final paso in pasos is List ? pasos : const []) {
      if (paso is! Map || paso['type'] != 'model_output') continue;
      final partes = paso['content'];
      for (final parte in partes is List ? partes : const []) {
        if (parte is Map && parte['type'] == 'text') {
          texto.write(parte['text']);
        }
      }
    }
    return texto.toString();
  }

  /// Extrae el mensaje de error que devuelve la API (vacío si no se entiende).
  String _detalleDelError(List<int> cuerpo) {
    try {
      var datos = jsonDecode(utf8.decode(cuerpo, allowMalformed: true));
      // Esta API envuelve el error en una lista: [{"error": {...}}].
      if (datos is List && datos.isNotEmpty) datos = datos.first;
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
    // Una clave mal copiada llega como error 400, no como 401.
    if (estado == 401 || detalle.toLowerCase().contains('api key')) {
      return const ErrorIa(
        TipoErrorIa.claveInvalida,
        'La clave de la API no es válida. Revísala en Perfil.',
      );
    }
    return switch (estado) {
      403 => const ErrorIa(
        TipoErrorIa.sinSaldo,
        'Tu clave no tiene permiso para usar la IA desde esta cuenta o región.',
      ),
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
        'Llegaste al límite del plan gratuito por ahora. Espera un minuto e inténtalo de nuevo.',
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
}
