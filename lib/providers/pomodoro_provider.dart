import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/materias_repository.dart';
import '../models/estado_pomodoro.dart';
import '../models/modo_pomodoro.dart';
import '../services/notificador_pomodoro.dart';

/// Guarda una sesión de enfoque completada; devuelve `true` si se guardó.
typedef RegistrarSesion = Future<bool> Function({
  String? materiaId,
  required DateTime inicio,
  required int duracionSegundos,
});

/// Temporizador Pomodoro de toda la app.
///
/// Vive fuera de la pantalla, así que el tiempo sigue corriendo aunque el
/// usuario salga de ella. Calcula el tiempo contra una hora de fin, guarda el
/// bloque en curso para retomarlo si Android cierra la app, y programa un aviso
/// del sistema (con vibración repetida) para cuando termine.
class PomodoroProvider extends ChangeNotifier {
  PomodoroProvider({
    required this._repositorio,
    required this._notificador,
    required this._registrarSesion,
    this._ahora = DateTime.now,
  }) {
    _segundosTotales = _modo.segundos(demo: _modoDemo);
    _segundosRestantes = _segundosTotales;
  }

  final MateriasRepository _repositorio;
  final NotificadorPomodoro _notificador;
  final RegistrarSesion _registrarSesion;
  final DateTime Function() _ahora;

  /// Clave del ajuste que guarda si el modo demostración está activado.
  static const String _claveModoDemo = 'modo_demo';

  ModoPomodoro _modo = ModoPomodoro.enfoque;
  bool _modoDemo = true;
  late int _segundosTotales;
  late int _segundosRestantes;
  bool _corriendo = false;
  DateTime? _fin;
  int _ciclos = 0;
  String? _materiaId;
  String? _materiaNombre;
  Timer? _temporizador;
  bool _permisosPedidos = false;
  bool _liberado = false;

  /// Modo del bloque actual.
  ModoPomodoro get modo => _modo;

  /// Segundos que faltan para terminar el bloque.
  int get segundosRestantes => _segundosRestantes;

  /// Duración total del bloque actual en segundos.
  int get segundosTotales => _segundosTotales;

  /// `true` mientras el temporizador corre.
  bool get corriendo => _corriendo;

  /// Bloques de enfoque completados en la ronda actual.
  int get ciclosCompletados => _ciclos;

  /// Materia del bloque actual; `null` si se estudia sin materia.
  String? get materiaId => _materiaId;

  /// Nombre de la materia del bloque actual.
  String? get materiaNombre => _materiaNombre;

  /// `true` si se usan las duraciones cortas de la demostración.
  bool get modoDemo => _modoDemo;

  /// `true` si hay un bloque corriendo o en pausa con tiempo ya consumido.
  bool get hayBloqueActivo =>
      _corriendo || _segundosRestantes != _segundosTotales;

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    _temporizador?.cancel();
    super.dispose();
  }

  /// Lee el ajuste y el bloque en curso guardados y los retoma.
  ///
  /// Un bloque que ya venció mientras la app estaba cerrada se completa (y
  /// registra su sesión); uno que sigue en marcha continúa corriendo.
  Future<void> restaurar() async {
    try {
      final ajuste = await _repositorio.obtenerAjuste(_claveModoDemo);
      if (ajuste != null) _modoDemo = ajuste == '1';
      final estado = await _repositorio.obtenerPomodoroEnCurso();
      if (estado == null) {
        _segundosTotales = _modo.segundos(demo: _modoDemo);
        _segundosRestantes = _segundosTotales;
        notifyListeners();
        return;
      }

      _modo = estado.modo;
      _segundosTotales = estado.segundosTotales;
      _segundosRestantes = estado.segundosRestantes;
      _ciclos = estado.ciclos;
      _materiaId = estado.materiaId;
      _materiaNombre = estado.materiaNombre;

      final fin = estado.fin;
      if (estado.corriendo && fin != null) {
        _fin = fin;
        _corriendo = true;
        if (!fin.isAfter(_ahora())) {
          await _completar(fin);
        } else {
          _segundosRestantes = _restantesHasta(fin);
          _arrancarTemporizador();
          notifyListeners();
          await _programarAviso();
        }
      } else {
        notifyListeners();
      }
    } catch (_) {
      // Si no se puede leer lo guardado, la app arranca con un Pomodoro limpio.
      notifyListeners();
    }
  }

  /// Se llama al volver la app a primer plano.
  ///
  /// Actualiza el tiempo, descarta el aviso que esté sonando y, si el bloque
  /// sigue corriendo, vuelve a programar su alarma.
  Future<void> alReanudarApp() async {
    actualizarTiempo();
    await _notificador.cancelar();
    if (_corriendo) await _programarAviso();
  }

  /// Elige la materia del bloque; se ignora si ya hay un bloque activo.
  void seleccionarMateria(String? id, String? nombre) {
    if (hayBloqueActivo) return;
    if (_materiaId == id && _materiaNombre == nombre) return;
    _materiaId = id;
    _materiaNombre = nombre;
    notifyListeners();
  }

  /// Inicia el bloque, o lo pausa si ya está corriendo.
  Future<void> alternar() async {
    if (_corriendo) {
      // Se pone al día antes de pausar; si el bloque ya había vencido, se completa.
      actualizarTiempo();
      if (!_corriendo) return;
      _temporizador?.cancel();
      _temporizador = null;
      _corriendo = false;
      _fin = null;
      notifyListeners();
      await _notificador.cancelar();
      await _guardarEstado();
      return;
    }

    final fin = _ahora().add(Duration(seconds: _segundosRestantes));
    _fin = fin;
    _corriendo = true;
    _arrancarTemporizador();
    notifyListeners();
    await _guardarEstado();
    // La alarma se programa sin esperar el permiso: si el diálogo sigue abierto,
    // el bloque no puede terminar sin tener su aviso listo.
    if (_corriendo && _fin == fin) await _programarAviso();
    unawaited(prepararAvisos());
  }

  /// Pide el permiso de notificaciones, una sola vez por sesión de la app.
  ///
  /// Se llama al abrir la pantalla del Pomodoro, para que el diálogo no
  /// interrumpa un bloque ya iniciado.
  Future<void> prepararAvisos() async {
    if (_permisosPedidos) return;
    _permisosPedidos = true;
    await _notificador.pedirPermisos();
  }

  /// Vuelve al inicio del modo actual, detenido.
  Future<void> reiniciar() => cambiarModo(_modo);

  /// Salta al otro tipo de bloque (enfoque ↔ descanso corto).
  Future<void> saltar() => cambiarModo(
    _modo == ModoPomodoro.enfoque
        ? ModoPomodoro.descansoCorto
        : ModoPomodoro.enfoque,
  );

  /// Cambia de modo, detenido y con la duración completa. No guarda sesión.
  Future<void> cambiarModo(ModoPomodoro modo) async {
    _temporizador?.cancel();
    _temporizador = null;
    _corriendo = false;
    _fin = null;
    _modo = modo;
    _segundosTotales = modo.segundos(demo: _modoDemo);
    _segundosRestantes = _segundosTotales;
    notifyListeners();
    await _notificador.cancelar();
    await _borrarEstado();
  }

  /// Activa o desactiva las duraciones cortas de la demostración.
  ///
  /// Un bloque ya iniciado no cambia; el nuevo modo aplica al siguiente.
  Future<void> alternarModoDemo(bool activado) async {
    final habiaBloque = hayBloqueActivo;
    _modoDemo = activado;
    if (!habiaBloque) {
      _segundosTotales = _modo.segundos(demo: _modoDemo);
      _segundosRestantes = _segundosTotales;
    }
    notifyListeners();
    try {
      await _repositorio.guardarAjuste(_claveModoDemo, activado ? '1' : '0');
    } catch (_) {}
  }

  /// Recalcula los segundos restantes contra la hora de fin y completa el bloque si ya venció.
  void actualizarTiempo() {
    final fin = _fin;
    if (fin == null || !_corriendo) return;

    final milisegundos = fin.difference(_ahora()).inMilliseconds;
    final restantes = milisegundos <= 0 ? 0 : (milisegundos / 1000).ceil();
    if (restantes <= 0) {
      unawaited(_completar(fin));
    } else if (restantes != _segundosRestantes) {
      _segundosRestantes = restantes;
      notifyListeners();
    }
  }

  int _restantesHasta(DateTime fin) {
    final milisegundos = fin.difference(_ahora()).inMilliseconds;
    return milisegundos <= 0 ? 0 : (milisegundos / 1000).ceil();
  }

  void _arrancarTemporizador() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(
      const Duration(seconds: 1),
      (_) => actualizarTiempo(),
    );
  }

  /// Termina el bloque que acabó en [fin]: registra la sesión (si era de
  /// enfoque), pasa al siguiente modo detenido y borra el estado guardado.
  ///
  /// Marca el bloque como detenido antes de cualquier espera, así un segundo
  /// aviso de vencimiento (tick tardío, volver a la app) no lo repite.
  Future<void> _completar(DateTime fin) async {
    _temporizador?.cancel();
    _temporizador = null;
    final eraEnfoque = _modo == ModoPomodoro.enfoque;
    final duracion = _segundosTotales;
    _corriendo = false;
    _fin = null;

    if (eraEnfoque) {
      _ciclos++;
      _modo = _ciclos % 4 == 0
          ? ModoPomodoro.descansoLargo
          : ModoPomodoro.descansoCorto;
    } else {
      _modo = ModoPomodoro.enfoque;
    }
    _segundosTotales = _modo.segundos(demo: _modoDemo);
    _segundosRestantes = _segundosTotales;
    notifyListeners();

    if (eraEnfoque) {
      await _registrarSesion(
        materiaId: _materiaId,
        inicio: fin.subtract(Duration(seconds: duracion)),
        duracionSegundos: duracion,
      );
    }
    await _borrarEstado();
  }

  Future<void> _programarAviso() async {
    final fin = _fin;
    if (fin == null) return;
    final String titulo;
    final String cuerpo;
    if (_modo == ModoPomodoro.enfoque) {
      titulo = '¡Bloque de enfoque terminado!';
      final enMateria = _materiaNombre != null ? ' en $_materiaNombre' : '';
      cuerpo = 'Buen trabajo$enMateria. Toma un descanso.';
    } else {
      titulo = 'Descanso terminado';
      cuerpo = 'A concentrarse de nuevo.';
    }
    await _notificador.programar(fin: fin, titulo: titulo, cuerpo: cuerpo);
  }

  Future<void> _guardarEstado() async {
    try {
      await _repositorio.guardarPomodoroEnCurso(
        EstadoPomodoro(
          modo: _modo,
          corriendo: _corriendo,
          fin: _fin,
          segundosRestantes: _segundosRestantes,
          segundosTotales: _segundosTotales,
          ciclos: _ciclos,
          materiaId: _materiaId,
          materiaNombre: _materiaNombre,
        ),
      );
    } catch (_) {}
  }

  Future<void> _borrarEstado() async {
    try {
      await _repositorio.borrarPomodoroEnCurso();
    } catch (_) {}
  }
}
