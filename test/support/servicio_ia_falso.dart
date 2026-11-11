import 'dart:async';
import 'dart:typed_data';

import 'package:studybuddy_ia/models/apunte.dart';
import 'package:studybuddy_ia/models/mensaje_chat.dart';
import 'package:studybuddy_ia/models/pregunta.dart';
import 'package:studybuddy_ia/models/resultados_ia.dart';
import 'package:studybuddy_ia/services/selector_imagen.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';

/// Servicio de IA de pruebas: responde al instante con datos fijos y anota lo que se le pide.
class ServicioIaFalso implements ServicioIa {
  /// Si no es nulo, todas las operaciones fallan con este error.
  ErrorIa? error;

  /// Si no es nulo, las operaciones esperan a que se complete (simula la red lenta).
  Completer<void>? compuerta;

  /// Nombres de las operaciones pedidas, en orden.
  final List<String> llamadas = [];

  /// Historial recibido en la última pregunta al tutor.
  List<MensajeChat> ultimoHistorial = const [];

  /// Apuntes recibidos en la última operación que los usa.
  List<Apunte> ultimosApuntes = const [];

  /// Partes en que llega la respuesta del tutor.
  List<String> partesTutor = ['El pipeline ', 'tiene cinco etapas.'];

  /// Sesiones que devuelve el plan sugerido; `null` usa una sola sesión de ejemplo.
  List<SesionSugerida>? plan;

  static const ResumenApunte resumen = ResumenApunte(
    corto: 'Resumen corto de prueba.',
    medio: 'Resumen medio de prueba.',
    detallado: 'Resumen detallado de prueba.',
    ideasClave: ['Primera idea clave.', 'Segunda idea clave.'],
  );

  /// Quiz fijo de dos preguntas; la respuesta correcta es siempre "Correcta N".
  static const List<Pregunta> quiz = [
    Pregunta(
      id: 'p0',
      enunciado: 'Pregunta uno',
      opciones: ['Correcta 1', 'Mala 1a', 'Mala 1b', 'Mala 1c'],
      indiceRespuestaCorrecta: 0,
      explicacionIa: 'Explicación uno.',
    ),
    Pregunta(
      id: 'p1',
      enunciado: 'Pregunta dos',
      opciones: ['Mala 2a', 'Correcta 2', 'Mala 2b', 'Mala 2c'],
      indiceRespuestaCorrecta: 1,
      explicacionIa: 'Explicación dos.',
    ),
  ];

  Future<void> _atender(String operacion) async {
    llamadas.add(operacion);
    await compuerta?.future;
    final fallo = error;
    if (fallo != null) throw fallo;
  }

  @override
  Future<ResumenApunte> resumirApunte({
    required String materia,
    required String titulo,
    required String contenido,
  }) async {
    await _atender('resumir');
    return resumen;
  }

  @override
  Future<List<Pregunta>> generarQuiz({
    required String materia,
    required List<Apunte> apuntes,
    int cantidad = 5,
  }) async {
    ultimosApuntes = apuntes;
    await _atender('quiz');
    return quiz;
  }

  @override
  Stream<String> responderTutor({
    required String materia,
    required String nombreEstudiante,
    required List<Apunte> apuntes,
    required List<MensajeChat> historial,
  }) async* {
    ultimoHistorial = historial;
    ultimosApuntes = apuntes;
    await _atender('tutor');
    for (final parte in partesTutor) {
      yield parte;
    }
  }

  @override
  Future<ApunteEscaneado> transcribirImagen({
    required Uint8List imagen,
    required String tipoMime,
    required String materia,
  }) async {
    await _atender('escanear');
    return const ApunteEscaneado(
      titulo: 'Título escaneado',
      contenido: 'Texto leído de la foto.',
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
    await _atender('plan');
    return plan ??
        [
          SesionSugerida(
            inicio: DateTime(hoy.year, hoy.month, hoy.day, 18),
            duracionMinutos: 45,
            tema: 'Repaso sugerido por la IA',
          ),
        ];
  }

  @override
  Future<void> probarConexion() => _atender('probar');
}

/// Selector de imágenes de pruebas: devuelve una foto fija sin abrir la cámara.
class SelectorImagenFalso implements SelectorImagen {
  /// Si es `true`, simula que el usuario canceló.
  bool cancelar = false;

  /// Orígenes pedidos, en orden.
  final List<OrigenImagen> pedidos = [];

  @override
  Future<ImagenElegida?> elegir(OrigenImagen origen) async {
    pedidos.add(origen);
    if (cancelar) return null;
    return ImagenElegida(
      bytes: Uint8List.fromList([1, 2, 3]),
      tipoMime: 'image/jpeg',
    );
  }
}
