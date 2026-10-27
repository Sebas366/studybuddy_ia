import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/materias_repository.dart';
import '../models/intento_quiz.dart';
import '../models/materia.dart';
import '../models/sesion_enfoque.dart';

/// Estado de las sesiones de enfoque y los intentos de quiz del usuario.
///
/// Es la fuente de datos de la pantalla de estadísticas y de la racha de
/// Inicio. Ninguna operación lanza: si algo falla deja un [error] (lectura) o
/// devuelve `false` (escritura), para que ni el Pomodoro ni el quiz se caigan.
class EstadisticasProvider extends ChangeNotifier {
  EstadisticasProvider(this._repositorio);

  final MateriasRepository _repositorio;

  List<SesionEnfoque> _sesiones = const [];
  List<IntentoQuiz> _intentos = const [];
  bool _cargando = true;
  String? _error;

  /// Número de la última recarga iniciada; una recarga vieja no pisa a una más nueva.
  int _generacion = 0;

  /// Conjunto de ids de materias visto en la última sincronización.
  Set<String>? _idsMaterias;

  /// Sesiones de enfoque guardadas, la más reciente primero (no modificable).
  List<SesionEnfoque> get sesiones => UnmodifiableListView(_sesiones);

  /// Intentos de quiz guardados, el más reciente primero (no modificable).
  List<IntentoQuiz> get intentos => UnmodifiableListView(_intentos);

  /// `true` hasta que termina la primera lectura.
  bool get cargando => _cargando;

  /// Mensaje para el usuario si la última lectura falló; `null` si todo va bien.
  String? get error => _error;

  /// Lee sesiones e intentos del repositorio y notifica a los oyentes.
  Future<void> cargar() async {
    final miGeneracion = ++_generacion;
    try {
      final sesiones = await _repositorio.obtenerSesionesEnfoque();
      final intentos = await _repositorio.obtenerIntentosQuiz();
      if (miGeneracion != _generacion) return; // ya hay una recarga más nueva
      _sesiones = sesiones;
      _intentos = intentos;
      _error = null;
    } catch (_) {
      if (miGeneracion != _generacion) return;
      _error = 'No se pudieron cargar tus estadísticas.';
    }
    _cargando = false;
    notifyListeners();
  }

  /// Guarda un bloque de enfoque completado. Devuelve `true` si se guardó.
  Future<bool> registrarSesionEnfoque({
    String? materiaId,
    required DateTime inicio,
    required int duracionSegundos,
  }) async {
    try {
      await _repositorio.registrarSesionEnfoque(
        materiaId: materiaId,
        inicio: inicio,
        duracionSegundos: duracionSegundos,
      );
    } catch (_) {
      return false;
    }
    await cargar();
    return true;
  }

  /// Guarda el resultado de un quiz terminado. Devuelve `true` si se guardó.
  Future<bool> registrarIntentoQuiz({
    required String materiaId,
    required int aciertos,
    required int total,
  }) async {
    try {
      await _repositorio.registrarIntentoQuiz(
        materiaId: materiaId,
        aciertos: aciertos,
        total: total,
      );
    } catch (_) {
      return false;
    }
    await cargar();
    return true;
  }

  /// Recarga los datos cuando cambia el conjunto de materias reales.
  ///
  /// Al borrar una materia, el repositorio también borra sus sesiones e
  /// intentos; esto mantiene el estado en pantalla al día. La primera llamada
  /// solo fija la referencia.
  void sincronizarConMaterias(List<Materia> materias) {
    final ids = {for (final materia in materias) materia.id};
    final anteriores = _idsMaterias;
    _idsMaterias = ids;
    if (anteriores != null && !setEquals(anteriores, ids)) {
      cargar();
    }
  }
}
