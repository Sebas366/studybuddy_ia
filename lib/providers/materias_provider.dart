import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/catalogo_materia.dart';
import '../data/materias_repository.dart';
import '../models/materia.dart';
import '../utils/validadores.dart';

/// Estado de las materias y apuntes reales del usuario.
///
/// Después de cada cambio recarga la lista completa desde el repositorio y
/// notifica a las pantallas. Las operaciones recortan los textos y validan los
/// datos: si algo no es válido lanzan [ArgumentError] sin tocar el repositorio.
class MateriasProvider extends ChangeNotifier {
  MateriasProvider(this._repositorio);

  final MateriasRepository _repositorio;

  List<Materia> _materias = const [];
  bool _cargando = true;
  String? _error;

  /// Número de la última recarga iniciada; una recarga vieja no pisa a una más nueva.
  int _generacion = 0;

  /// Materias reales, la más nueva primero (lista no modificable).
  List<Materia> get materias => UnmodifiableListView(_materias);

  /// `true` hasta que termina la primera lectura del repositorio.
  bool get cargando => _cargando;

  /// Mensaje para el usuario si la última lectura falló; `null` si todo va bien.
  String? get error => _error;

  /// Lee las materias del repositorio y notifica a los oyentes.
  ///
  /// Nunca lanza: si la lectura falla deja un [error] para que la pantalla
  /// ofrezca reintentar. Así, un guardado que ya se completó no se reporta
  /// como fallido solo porque la recarga posterior falló.
  Future<void> cargar() async {
    final miGeneracion = ++_generacion;
    try {
      final materias = await _repositorio.obtenerMaterias();
      if (miGeneracion != _generacion) return; // ya hay una recarga más nueva
      _materias = materias;
      _error = null;
    } catch (_) {
      if (miGeneracion != _generacion) return;
      _error = 'No se pudieron cargar tus materias.';
    }
    _cargando = false;
    notifyListeners();
  }

  /// Devuelve la materia con ese [id] o `null` si no existe.
  Materia? porId(String id) {
    for (final materia in _materias) {
      if (materia.id == id) return materia;
    }
    return null;
  }

  /// Lanza [ArgumentError] con el [mensaje] si la validación encontró un error.
  void _exigirValido(String? mensaje) {
    if (mensaje != null) throw ArgumentError(mensaje);
  }

  /// Crea una materia nueva.
  Future<void> crearMateria({
    required String nombre,
    String descripcion = '',
    int colorIndice = 0,
    String iconoClave = CatalogoMateria.iconoPorDefecto,
  }) async {
    _exigirValido(validarNombreMateria(nombre));
    await _repositorio.crearMateria(
      nombre: nombre.trim(),
      descripcion: descripcion.trim(),
      colorIndice: colorIndice,
      iconoClave: iconoClave,
    );
    await cargar();
  }

  /// Cambia los datos de una materia existente.
  Future<void> actualizarMateria({
    required String id,
    required String nombre,
    String descripcion = '',
    int colorIndice = 0,
    String iconoClave = CatalogoMateria.iconoPorDefecto,
  }) async {
    _exigirValido(validarNombreMateria(nombre));
    await _repositorio.actualizarMateria(
      id: id,
      nombre: nombre.trim(),
      descripcion: descripcion.trim(),
      colorIndice: colorIndice,
      iconoClave: iconoClave,
    );
    await cargar();
  }

  /// Borra una materia y todos sus apuntes.
  Future<void> borrarMateria(String id) async {
    await _repositorio.borrarMateria(id);
    await cargar();
  }

  /// Crea un apunte nuevo dentro de una materia.
  Future<void> crearApunte({
    required String materiaId,
    required String titulo,
    required String contenido,
  }) async {
    _exigirValido(validarTituloApunte(titulo));
    _exigirValido(validarTextoApunte(contenido));
    await _repositorio.crearApunte(
      materiaId: materiaId,
      titulo: titulo.trim(),
      contenido: contenido.trim(),
    );
    await cargar();
  }

  /// Cambia el título y el texto de un apunte existente.
  Future<void> actualizarApunte({
    required String id,
    required String titulo,
    required String contenido,
  }) async {
    _exigirValido(validarTituloApunte(titulo));
    _exigirValido(validarTextoApunte(contenido));
    await _repositorio.actualizarApunte(
      id: id,
      titulo: titulo.trim(),
      contenido: contenido.trim(),
    );
    await cargar();
  }

  /// Borra un apunte.
  Future<void> borrarApunte(String id) async {
    await _repositorio.borrarApunte(id);
    await cargar();
  }
}
