import 'dart:async';

import 'package:studybuddy_ia/data/catalogo_materia.dart';
import 'package:studybuddy_ia/data/materias_repository.dart';
import 'package:studybuddy_ia/models/apunte.dart';
import 'package:studybuddy_ia/models/materia.dart';
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
  Future<List<Materia>> obtenerMaterias() async =>
      [for (final registro in _materias) _construir(registro)];

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
}

/// Repositorio en memoria cuyas altas esperan a que la prueba abra la [compuerta].
///
/// Permite simular un guardado lento para comprobar qué pasa si el usuario
/// vuelve a tocar "Guardar" mientras el primer guardado sigue en curso.
class RepositorioLento extends RepositorioMemoria {
  /// Las altas de materias y apuntes quedan detenidas hasta que se complete.
  final Completer<void> compuerta = Completer<void>();

  @override
  Future<Materia> crearMateria({
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
  }) async {
    await compuerta.future;
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
    await compuerta.future;
    return super.crearApunte(
      materiaId: materiaId,
      titulo: titulo,
      contenido: contenido,
    );
  }
}
