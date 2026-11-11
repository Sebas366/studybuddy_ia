import 'dart:async';

import 'package:studybuddy_ia/data/catalogo_materia.dart';
import 'package:studybuddy_ia/data/materias_repository.dart';
import 'package:studybuddy_ia/models/apunte.dart';
import 'package:studybuddy_ia/models/estado_pomodoro.dart';
import 'package:studybuddy_ia/models/evaluacion.dart';
import 'package:studybuddy_ia/models/intento_quiz.dart';
import 'package:studybuddy_ia/models/materia.dart';
import 'package:studybuddy_ia/models/mensaje_chat.dart';
import 'package:studybuddy_ia/models/pregunta.dart';
import 'package:studybuddy_ia/models/resultados_ia.dart';
import 'package:studybuddy_ia/models/sesion_enfoque.dart';
import 'package:studybuddy_ia/models/sesion_estudio.dart';
import 'package:studybuddy_ia/utils/formato_fecha.dart';

/// Registro interno de una materia dentro de [RepositorioMemoria].
class _RegistroMateria {
  _RegistroMateria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorIndice,
    required this.iconoClave,
    required this.semestre,
  });

  final String id;
  String nombre;
  String descripcion;
  int colorIndice;
  String iconoClave;
  String semestre;

  /// Apuntes de la materia, el más nuevo primero.
  final List<Apunte> apuntes = [];

  /// Preguntas del último quiz generado.
  List<Pregunta> preguntas = const [];
}

/// Repositorio falso que guarda todo en memoria, para las pruebas de widgets.
///
/// Sigue las mismas reglas de orden y subtítulo que [MateriasRepositorySqflite]:
/// materias y apuntes del más nuevo al más viejo.
class RepositorioMemoria implements MateriasRepository {
  /// Registros en orden de creación inverso (el más nuevo en la posición 0).
  final List<_RegistroMateria> _materias = [];

  /// Sesiones e intentos en orden de registro (el más viejo primero).
  final List<SesionEnfoque> _sesiones = [];
  final List<IntentoQuiz> _intentos = [];

  /// Chat con el tutor por materia, evaluaciones y sesiones del plan (en orden de registro).
  final Map<String, List<MensajeChat>> _mensajes = {};
  final List<Evaluacion> _evaluaciones = [];
  final List<SesionEstudio> _sesionesPlan = [];

  /// Bloque de Pomodoro en curso y ajustes de la app.
  EstadoPomodoro? _pomodoroEnCurso;
  final Map<String, String> _ajustes = {};
  int _contador = 0;

  String _nuevoId(String prefijo) => '${prefijo}_${_contador++}';

  Materia _construir(_RegistroMateria registro) {
    final degradado = CatalogoMateria.degradadoPorIndice(registro.colorIndice);
    return Materia(
      id: registro.id,
      nombre: registro.nombre,
      subtitulo: Materia.subtituloPorConteo(registro.apuntes.length),
      descripcion: registro.descripcion,
      icono: CatalogoMateria.iconoPorClave(registro.iconoClave),
      colorInicio: degradado[0],
      colorFin: degradado[1],
      apuntes: List.unmodifiable(registro.apuntes),
      preguntas: List.unmodifiable(registro.preguntas),
      colorIndice: registro.colorIndice,
      iconoClave: registro.iconoClave,
      semestre: registro.semestre,
    );
  }

  _RegistroMateria _buscar(String id) =>
      _materias.firstWhere((registro) => registro.id == id);

  @override
  Future<List<Materia>> obtenerMaterias() async => [
    for (final registro in _materias) _construir(registro),
  ];

  @override
  Future<Materia> crearMateria({
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
    required String semestre,
  }) async {
    final registro = _RegistroMateria(
      id: _nuevoId('mat'),
      nombre: nombre,
      descripcion: descripcion,
      colorIndice: colorIndice,
      iconoClave: iconoClave,
      semestre: semestre,
    );
    _materias.insert(0, registro);
    return _construir(registro);
  }

  @override
  Future<void> actualizarMateria({
    required String id,
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
    required String semestre,
  }) async {
    final registro = _buscar(id);
    registro.nombre = nombre;
    registro.descripcion = descripcion;
    registro.colorIndice = colorIndice;
    registro.iconoClave = iconoClave;
    registro.semestre = semestre;
  }

  @override
  Future<void> borrarMateria(String id) async {
    _materias.removeWhere((registro) => registro.id == id);
    _sesiones.removeWhere((sesion) => sesion.materiaId == id);
    _intentos.removeWhere((intento) => intento.materiaId == id);
    _mensajes.remove(id);
    _evaluaciones.removeWhere((evaluacion) => evaluacion.materiaId == id);
    _sesionesPlan.removeWhere((sesion) => sesion.materiaId == id);
  }

  @override
  Future<Apunte> crearApunte({
    required String materiaId,
    required String titulo,
    required String contenido,
  }) async {
    final apunte = Apunte(
      id: _nuevoId('apu'),
      titulo: titulo,
      materiaId: materiaId,
      fecha: formatearFecha(DateTime.now()),
      contenido: contenido,
    );
    _buscar(materiaId).apuntes.insert(0, apunte);
    return apunte;
  }

  @override
  Future<void> actualizarApunte({
    required String id,
    required String titulo,
    required String contenido,
  }) async {
    for (final registro in _materias) {
      final indice = registro.apuntes.indexWhere((a) => a.id == id);
      if (indice == -1) continue;
      final anterior = registro.apuntes[indice];
      // Si cambia el texto, el resumen de la IA se descarta.
      final conservar = anterior.contenido == contenido;
      registro.apuntes[indice] = Apunte(
        id: anterior.id,
        titulo: titulo,
        materiaId: anterior.materiaId,
        fecha: anterior.fecha,
        contenido: contenido,
        ideasClave: conservar ? anterior.ideasClave : const [],
        resumenCorto: conservar ? anterior.resumenCorto : '',
        resumenMedio: conservar ? anterior.resumenMedio : '',
        resumenDetallado: conservar ? anterior.resumenDetallado : '',
      );
      return;
    }
  }

  @override
  Future<void> guardarResumenApunte(
    String apunteId,
    ResumenApunte resumen,
  ) async {
    for (final registro in _materias) {
      final indice = registro.apuntes.indexWhere((a) => a.id == apunteId);
      if (indice == -1) continue;
      final anterior = registro.apuntes[indice];
      registro.apuntes[indice] = Apunte(
        id: anterior.id,
        titulo: anterior.titulo,
        materiaId: anterior.materiaId,
        fecha: anterior.fecha,
        contenido: anterior.contenido,
        ideasClave: resumen.ideasClave,
        resumenCorto: resumen.corto,
        resumenMedio: resumen.medio,
        resumenDetallado: resumen.detallado,
      );
      return;
    }
  }

  @override
  Future<void> reemplazarPreguntas(
    String materiaId,
    List<Pregunta> preguntas,
  ) async {
    _buscar(materiaId).preguntas = [
      for (final pregunta in preguntas)
        Pregunta(
          id: _nuevoId('pre'),
          enunciado: pregunta.enunciado,
          opciones: pregunta.opciones,
          indiceRespuestaCorrecta: pregunta.indiceRespuestaCorrecta,
          explicacionIa: pregunta.explicacionIa,
        ),
    ];
  }

  @override
  Future<List<MensajeChat>> obtenerMensajesChat(String materiaId) async => [
    ...?_mensajes[materiaId],
  ];

  @override
  Future<MensajeChat> agregarMensajeChat({
    required String materiaId,
    required String texto,
    required bool esUsuario,
  }) async {
    final mensaje = MensajeChat(
      id: _nuevoId('msg'),
      texto: texto,
      esUsuario: esUsuario,
      fecha: DateTime.now(),
    );
    _mensajes.putIfAbsent(materiaId, () => []).add(mensaje);
    return mensaje;
  }

  @override
  Future<void> borrarMensajesChat(String materiaId) async {
    _mensajes.remove(materiaId);
  }

  @override
  Future<List<Evaluacion>> obtenerEvaluaciones() async {
    // La de fecha más cercana primero; en un empate, la registrada antes.
    final indices = List<int>.generate(_evaluaciones.length, (i) => i);
    indices.sort((a, b) {
      final porFecha = _evaluaciones[a].fecha.compareTo(_evaluaciones[b].fecha);
      return porFecha != 0 ? porFecha : a.compareTo(b);
    });
    return [for (final i in indices) _evaluaciones[i]];
  }

  @override
  Future<Evaluacion> crearEvaluacion({
    required String materiaId,
    required String titulo,
    required DateTime fecha,
    required String temas,
  }) async {
    final evaluacion = Evaluacion(
      id: _nuevoId('eva'),
      materiaId: materiaId,
      titulo: titulo,
      fecha: fecha,
      temas: temas,
    );
    _evaluaciones.add(evaluacion);
    return evaluacion;
  }

  @override
  Future<void> actualizarEvaluacion({
    required String id,
    required String materiaId,
    required String titulo,
    required DateTime fecha,
    required String temas,
  }) async {
    final indice = _evaluaciones.indexWhere((e) => e.id == id);
    if (indice == -1) return;
    _evaluaciones[indice] = Evaluacion(
      id: id,
      materiaId: materiaId,
      titulo: titulo,
      fecha: fecha,
      temas: temas,
    );
  }

  @override
  Future<void> borrarEvaluacion(String id) async {
    _evaluaciones.removeWhere((evaluacion) => evaluacion.id == id);
  }

  @override
  Future<List<SesionEstudio>> obtenerSesionesPlan() async {
    final indices = List<int>.generate(_sesionesPlan.length, (i) => i);
    indices.sort((a, b) {
      final porInicio = _sesionesPlan[a].inicio.compareTo(
        _sesionesPlan[b].inicio,
      );
      return porInicio != 0 ? porInicio : a.compareTo(b);
    });
    return [for (final i in indices) _sesionesPlan[i]];
  }

  @override
  Future<SesionEstudio> crearSesionPlan({
    String? materiaId,
    required String tema,
    required DateTime inicio,
    required int duracionMinutos,
  }) async {
    final sesion = SesionEstudio(
      id: _nuevoId('pla'),
      materiaId: materiaId,
      tema: tema,
      inicio: inicio,
      duracionMinutos: duracionMinutos,
    );
    _sesionesPlan.add(sesion);
    return sesion;
  }

  @override
  Future<void> actualizarSesionPlan({
    required String id,
    String? materiaId,
    required String tema,
    required DateTime inicio,
    required int duracionMinutos,
  }) async {
    final indice = _sesionesPlan.indexWhere((s) => s.id == id);
    if (indice == -1) return;
    _sesionesPlan[indice] = SesionEstudio(
      id: id,
      materiaId: materiaId,
      tema: tema,
      inicio: inicio,
      duracionMinutos: duracionMinutos,
      completada: _sesionesPlan[indice].completada,
    );
  }

  @override
  Future<void> marcarSesionPlan(String id, {required bool completada}) async {
    final indice = _sesionesPlan.indexWhere((s) => s.id == id);
    if (indice == -1) return;
    final anterior = _sesionesPlan[indice];
    _sesionesPlan[indice] = SesionEstudio(
      id: id,
      materiaId: anterior.materiaId,
      tema: anterior.tema,
      inicio: anterior.inicio,
      duracionMinutos: anterior.duracionMinutos,
      completada: completada,
    );
  }

  @override
  Future<void> borrarSesionPlan(String id) async {
    _sesionesPlan.removeWhere((sesion) => sesion.id == id);
  }

  @override
  Future<void> borrarApunte(String id) async {
    for (final registro in _materias) {
      registro.apuntes.removeWhere((apunte) => apunte.id == id);
    }
  }

  @override
  Future<SesionEnfoque> registrarSesionEnfoque({
    String? materiaId,
    required DateTime inicio,
    required int duracionSegundos,
  }) async {
    final sesion = SesionEnfoque(
      id: _nuevoId('ses'),
      materiaId: materiaId,
      inicio: inicio,
      duracionSegundos: duracionSegundos,
    );
    _sesiones.add(sesion);
    return sesion;
  }

  @override
  Future<List<SesionEnfoque>> obtenerSesionesEnfoque() async {
    // Más reciente primero; en un empate, la registrada después.
    final indices = List<int>.generate(_sesiones.length, (i) => i);
    indices.sort((a, b) {
      final porInicio = _sesiones[b].inicio.compareTo(_sesiones[a].inicio);
      return porInicio != 0 ? porInicio : b.compareTo(a);
    });
    return [for (final i in indices) _sesiones[i]];
  }

  @override
  Future<IntentoQuiz> registrarIntentoQuiz({
    required String materiaId,
    required int aciertos,
    required int total,
  }) async {
    final intento = IntentoQuiz(
      id: _nuevoId('qz'),
      materiaId: materiaId,
      aciertos: aciertos,
      total: total,
      fecha: DateTime.now(),
    );
    _intentos.add(intento);
    return intento;
  }

  @override
  Future<List<IntentoQuiz>> obtenerIntentosQuiz() async {
    final indices = List<int>.generate(_intentos.length, (i) => i);
    indices.sort((a, b) {
      final porFecha = _intentos[b].fecha.compareTo(_intentos[a].fecha);
      return porFecha != 0 ? porFecha : b.compareTo(a);
    });
    return [for (final i in indices) _intentos[i]];
  }

  @override
  Future<EstadoPomodoro?> obtenerPomodoroEnCurso() async => _pomodoroEnCurso;

  @override
  Future<void> guardarPomodoroEnCurso(EstadoPomodoro estado) async {
    _pomodoroEnCurso = estado;
  }

  @override
  Future<void> borrarPomodoroEnCurso() async {
    _pomodoroEnCurso = null;
  }

  @override
  Future<String?> obtenerAjuste(String clave) async => _ajustes[clave];

  @override
  Future<void> guardarAjuste(String clave, String valor) async {
    _ajustes[clave] = valor;
  }
}

/// Repositorio en memoria cuyas altas esperan a que la prueba abra una compuerta.
///
/// Permite simular un guardado lento para comprobar qué pasa si el usuario
/// vuelve a tocar "Guardar" mientras el primer guardado sigue en curso.
class RepositorioLento extends RepositorioMemoria {
  /// Las altas de materias quedan detenidas hasta que se complete.
  final Completer<void> compuertaMaterias = Completer<void>();

  /// Las altas de apuntes quedan detenidas hasta que se complete.
  final Completer<void> compuertaApuntes = Completer<void>();

  @override
  Future<Materia> crearMateria({
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
    required String semestre,
  }) async {
    await compuertaMaterias.future;
    return super.crearMateria(
      nombre: nombre,
      descripcion: descripcion,
      colorIndice: colorIndice,
      iconoClave: iconoClave,
      semestre: semestre,
    );
  }

  @override
  Future<Apunte> crearApunte({
    required String materiaId,
    required String titulo,
    required String contenido,
  }) async {
    await compuertaApuntes.future;
    return super.crearApunte(
      materiaId: materiaId,
      titulo: titulo,
      contenido: contenido,
    );
  }
}

/// Repositorio en memoria cuya lectura y escritura pueden fallar a demanda.
///
/// Sirve para probar qué pasa cuando la base de datos no responde, sin impedir
/// que el resto de operaciones sigan funcionando.
class RepositorioInestable extends RepositorioMemoria {
  /// Mientras sea `true`, las lecturas lanzan una excepción.
  bool fallarLectura = false;

  /// Mientras sea `true`, registrar sesiones e intentos lanza una excepción.
  bool fallarEscritura = false;

  @override
  Future<List<Materia>> obtenerMaterias() async {
    if (fallarLectura) throw StateError('Fallo simulado de lectura');
    return super.obtenerMaterias();
  }

  @override
  Future<List<SesionEnfoque>> obtenerSesionesEnfoque() async {
    if (fallarLectura) throw StateError('Fallo simulado de lectura');
    return super.obtenerSesionesEnfoque();
  }

  @override
  Future<List<IntentoQuiz>> obtenerIntentosQuiz() async {
    if (fallarLectura) throw StateError('Fallo simulado de lectura');
    return super.obtenerIntentosQuiz();
  }

  @override
  Future<SesionEnfoque> registrarSesionEnfoque({
    String? materiaId,
    required DateTime inicio,
    required int duracionSegundos,
  }) async {
    if (fallarEscritura) throw StateError('Fallo simulado de escritura');
    return super.registrarSesionEnfoque(
      materiaId: materiaId,
      inicio: inicio,
      duracionSegundos: duracionSegundos,
    );
  }

  @override
  Future<IntentoQuiz> registrarIntentoQuiz({
    required String materiaId,
    required int aciertos,
    required int total,
  }) async {
    if (fallarEscritura) throw StateError('Fallo simulado de escritura');
    return super.registrarIntentoQuiz(
      materiaId: materiaId,
      aciertos: aciertos,
      total: total,
    );
  }
}

/// Repositorio en memoria cuya próxima lectura se entrega tarde, a voluntad de la prueba.
///
/// La lectura retenida toma su "foto" de los datos en el momento de empezar y
/// la devuelve cuando la prueba completa la compuerta; sirve para simular una
/// recarga lenta que termina después de otra más nueva.
class RepositorioLecturaLenta extends RepositorioMemoria {
  Completer<void>? _retenida;

  /// La próxima lectura de materias o sesiones queda en espera hasta completar lo devuelto.
  Completer<void> retenerProximaLectura() => _retenida = Completer<void>();

  Future<T> _conRetencion<T>(Future<T> foto) async {
    final resultado = await foto;
    final compuerta = _retenida;
    _retenida = null;
    if (compuerta != null) await compuerta.future;
    return resultado;
  }

  @override
  Future<List<Materia>> obtenerMaterias() =>
      _conRetencion(super.obtenerMaterias());

  @override
  Future<List<SesionEnfoque>> obtenerSesionesEnfoque() =>
      _conRetencion(super.obtenerSesionesEnfoque());
}
