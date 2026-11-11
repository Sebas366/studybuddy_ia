import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/materias_repository.dart';
import '../models/evaluacion.dart';
import '../models/materia.dart';
import '../models/resultados_ia.dart';
import '../models/sesion_estudio.dart';
import '../utils/plan.dart';
import '../utils/validadores.dart';

/// Estado del plan de estudio: las evaluaciones y las sesiones planeadas.
///
/// Después de cada cambio recarga todo desde el repositorio y notifica a las
/// pantallas. Las operaciones validan los datos: si algo no es válido lanzan
/// [ArgumentError] sin tocar el repositorio.
class PlanProvider extends ChangeNotifier {
  PlanProvider(this._repositorio);

  final MateriasRepository _repositorio;

  List<Evaluacion> _evaluaciones = const [];
  List<SesionEstudio> _sesiones = const [];
  bool _cargando = true;
  String? _error;

  /// Número de la última recarga iniciada; una recarga vieja no pisa a una más nueva.
  int _generacion = 0;

  /// Conjunto de ids de materias visto en la última sincronización.
  Set<String>? _idsMaterias;

  /// Todas las evaluaciones, la de fecha más cercana primero (no modificable).
  List<Evaluacion> get evaluaciones => UnmodifiableListView(_evaluaciones);

  /// Todas las sesiones planeadas, la más próxima primero (no modificable).
  List<SesionEstudio> get sesiones => UnmodifiableListView(_sesiones);

  /// `true` hasta que termina la primera lectura.
  bool get cargando => _cargando;

  /// Mensaje para el usuario si la última lectura falló; `null` si todo va bien.
  String? get error => _error;

  /// Lee el plan del repositorio y notifica a los oyentes. Nunca lanza.
  Future<void> cargar() async {
    final miGeneracion = ++_generacion;
    try {
      final evaluaciones = await _repositorio.obtenerEvaluaciones();
      final sesiones = await _repositorio.obtenerSesionesPlan();
      if (miGeneracion != _generacion) return; // ya hay una recarga más nueva
      _evaluaciones = evaluaciones;
      _sesiones = sesiones;
      _error = null;
    } catch (_) {
      if (miGeneracion != _generacion) return;
      _error = 'No se pudo cargar tu plan de estudio.';
    }
    _cargando = false;
    notifyListeners();
  }

  /// Recarga el plan cuando cambia el conjunto de materias.
  ///
  /// Al borrar una materia, el repositorio también borra sus evaluaciones y
  /// sesiones. La primera llamada solo fija la referencia.
  void sincronizarConMaterias(List<Materia> materias) {
    final ids = {for (final materia in materias) materia.id};
    final anteriores = _idsMaterias;
    _idsMaterias = ids;
    if (anteriores != null && !setEquals(anteriores, ids)) {
      cargar();
    }
  }

  /// Lanza [ArgumentError] con el [mensaje] si la validación encontró un error.
  void _exigirValido(String? mensaje) {
    if (mensaje != null) throw ArgumentError(mensaje);
  }

  void _exigirDuracion(int minutos) {
    if (minutos < 5 || minutos > 600) {
      throw ArgumentError('La duración debe estar entre 5 y 600 minutos.');
    }
  }

  /// Crea una evaluación; la [fecha] se guarda sin hora.
  Future<void> crearEvaluacion({
    required String materiaId,
    required String titulo,
    required DateTime fecha,
    String temas = '',
  }) async {
    _exigirValido(validarTituloEvaluacion(titulo));
    await _repositorio.crearEvaluacion(
      materiaId: materiaId,
      titulo: titulo.trim(),
      fecha: soloFecha(fecha),
      temas: temas.trim(),
    );
    await cargar();
  }

  /// Cambia los datos de una evaluación.
  Future<void> actualizarEvaluacion({
    required String id,
    required String materiaId,
    required String titulo,
    required DateTime fecha,
    String temas = '',
  }) async {
    _exigirValido(validarTituloEvaluacion(titulo));
    await _repositorio.actualizarEvaluacion(
      id: id,
      materiaId: materiaId,
      titulo: titulo.trim(),
      fecha: soloFecha(fecha),
      temas: temas.trim(),
    );
    await cargar();
  }

  /// Borra una evaluación.
  Future<void> borrarEvaluacion(String id) async {
    await _repositorio.borrarEvaluacion(id);
    await cargar();
  }

  /// Agrega una sesión de estudio al plan.
  Future<void> crearSesion({
    String? materiaId,
    required String tema,
    required DateTime inicio,
    required int duracionMinutos,
  }) async {
    _exigirValido(validarTemaSesion(tema));
    _exigirDuracion(duracionMinutos);
    await _repositorio.crearSesionPlan(
      materiaId: materiaId,
      tema: tema.trim(),
      inicio: inicio,
      duracionMinutos: duracionMinutos,
    );
    await cargar();
  }

  /// Cambia los datos de una sesión del plan.
  Future<void> actualizarSesion({
    required String id,
    String? materiaId,
    required String tema,
    required DateTime inicio,
    required int duracionMinutos,
  }) async {
    _exigirValido(validarTemaSesion(tema));
    _exigirDuracion(duracionMinutos);
    await _repositorio.actualizarSesionPlan(
      id: id,
      materiaId: materiaId,
      tema: tema.trim(),
      inicio: inicio,
      duracionMinutos: duracionMinutos,
    );
    await cargar();
  }

  /// Marca o desmarca una sesión como completada.
  Future<void> marcarSesion(String id, {required bool completada}) async {
    await _repositorio.marcarSesionPlan(id, completada: completada);
    await cargar();
  }

  /// Borra una sesión del plan.
  Future<void> borrarSesion(String id) async {
    await _repositorio.borrarSesionPlan(id);
    await cargar();
  }

  /// Agrega al plan las sesiones que propuso la IA para una materia.
  Future<void> agregarSesionesSugeridas(
    String materiaId,
    List<SesionSugerida> sugeridas,
  ) async {
    for (final sugerida in sugeridas) {
      final tema = sugerida.tema.trim();
      await _repositorio.crearSesionPlan(
        materiaId: materiaId,
        tema: tema.length > maxTextoPlan ? tema.substring(0, maxTextoPlan) : tema,
        inicio: sugerida.inicio,
        duracionMinutos: sugerida.duracionMinutos,
      );
    }
    await cargar();
  }
}
