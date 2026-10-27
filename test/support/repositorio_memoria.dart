import 'dart:async';

import 'package:studybuddy_ia/data/catalogo_materia.dart';
import 'package:studybuddy_ia/data/materias_repository.dart';
import 'package:studybuddy_ia/models/apunte.dart';
import 'package:studybuddy_ia/models/intento_quiz.dart';
import 'package:studybuddy_ia/models/materia.dart';
import 'package:studybuddy_ia/models/sesion_enfoque.dart';
import 'package:studybuddy_ia/utils/formato_fecha.dart';

/// Registro interno de una materia dentro de [RepositorioMemoria].
class _RegistroMateria {
  _RegistroMateria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorIndice,
    required this.iconoClave,
  });

  final String id;
  String nombre;
  String descripcion;
  int colorIndice;
  String iconoClave;

  /// Apuntes de la materia, el más nuevo primero.
  final List<Apunte> apuntes = [];
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
  int _contador = 0;

  String _nuevoId(String prefijo) => '${prefijo}_${_contador++}';

  Materia _construir(_RegistroMateria registro) {
    final degradado = CatalogoMateria.degradadoPorIndice(registro.colorIndice);
    return Materia(
      id: registro.id,
      nombre: registro.nombre,
      subtitulo: Materia.subtituloPorConteo(registro.apuntes.length),
      descripcion: registro.descripcion,
      progreso: 0,
      icono: CatalogoMateria.iconoPorClave(registro.iconoClave),
      colorInicio: degradado[0],
      colorFin: degradado[1],
      apuntes: List.unmodifiable(registro.apuntes),
      preguntas: const [],
      respuestasSimuladasIa: const [],
      colorIndice: registro.colorIndice,
      iconoClave: registro.iconoClave,
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
  }) async {
    final registro = _RegistroMateria(
      id: _nuevoId('mat'),
      nombre: nombre,
      descripcion: descripcion,
      colorIndice: colorIndice,
      iconoClave: iconoClave,
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
  }) async {
    final registro = _buscar(id);
    registro.nombre = nombre;
    registro.descripcion = descripcion;
    registro.colorIndice = colorIndice;
    registro.iconoClave = iconoClave;
  }

  @override
  Future<void> borrarMateria(String id) async {
    _materias.removeWhere((registro) => registro.id == id);
    _sesiones.removeWhere((sesion) => sesion.materiaId == id);
    _intentos.removeWhere((intento) => intento.materiaId == id);
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
      registro.apuntes[indice] = Apunte(
        id: anterior.id,
        titulo: titulo,
        materiaId: anterior.materiaId,
        fecha: anterior.fecha,
        contenido: contenido,
      );
      return;
    }
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
  }) async {
    await compuertaMaterias.future;
    return super.crearMateria(
      nombre: nombre,
      descripcion: descripcion,
      colorIndice: colorIndice,
      iconoClave: iconoClave,
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
