import 'package:flutter/material.dart';

import '../data/materias_repository.dart';
import '../services/notificador_pomodoro.dart';

/// Preferencias del usuario: su perfil, el tema de la app y el recordatorio diario.
///
/// Todo se guarda en la tabla de ajustes para que siga igual al reabrir la app.
/// Ninguna operación lanza: si guardar falla, el cambio vale hasta cerrar la app.
class AjustesProvider extends ChangeNotifier {
  AjustesProvider({
    required this._repositorio,
    this._recordatorio = const RecordatorioNulo(),
  });

  final MateriasRepository _repositorio;
  final NotificadorRecordatorio _recordatorio;

  static const String _claveNombre = 'perfil_nombre';
  static const String _claveCarrera = 'perfil_carrera';
  static const String _claveTema = 'tema';
  static const String _claveRecordatorio = 'recordatorio_activo';
  static const String _claveHoraRecordatorio = 'recordatorio_hora';

  /// Nombre que se usa mientras el usuario no escriba el suyo.
  static const String nombrePorDefecto = 'Estudiante';

  /// Longitud máxima del nombre y de la carrera.
  static const int maxTextoPerfil = 40;

  String _nombre = nombrePorDefecto;
  String _carrera = '';
  ThemeMode _modoTema = ThemeMode.system;
  bool _recordatorioActivo = false;
  TimeOfDay _horaRecordatorio = const TimeOfDay(hour: 18, minute: 0);

  /// Nombre con el que la app saluda al usuario.
  String get nombre => _nombre;

  /// Carrera o descripción corta del usuario; vacía si no la escribió.
  String get carrera => _carrera;

  /// Tema elegido: claro, oscuro o el del sistema.
  ThemeMode get modoTema => _modoTema;

  /// `true` si el recordatorio diario de estudio está encendido.
  bool get recordatorioActivo => _recordatorioActivo;

  /// Hora a la que suena el recordatorio diario.
  TimeOfDay get horaRecordatorio => _horaRecordatorio;

  /// Lee los ajustes guardados y notifica a los oyentes.
  Future<void> cargar() async {
    try {
      final nombre = await _repositorio.obtenerAjuste(_claveNombre);
      final carrera = await _repositorio.obtenerAjuste(_claveCarrera);
      final tema = await _repositorio.obtenerAjuste(_claveTema);
      final activo = await _repositorio.obtenerAjuste(_claveRecordatorio);
      final hora = await _repositorio.obtenerAjuste(_claveHoraRecordatorio);

      if (nombre != null && nombre.isNotEmpty) _nombre = nombre;
      if (carrera != null) _carrera = carrera;
      _modoTema = switch (tema) {
        'claro' => ThemeMode.light,
        'oscuro' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _recordatorioActivo = activo == '1';
      _horaRecordatorio = _horaDesdeTexto(hora) ?? _horaRecordatorio;
    } catch (_) {
      // Sin ajustes guardados se usan los valores por defecto.
    }
    notifyListeners();
  }

  /// Cambia el nombre y la carrera del perfil.
  ///
  /// Un nombre vacío vuelve al nombre por defecto.
  Future<void> cambiarPerfil({
    required String nombre,
    required String carrera,
  }) async {
    final nombreLimpio = _recortar(nombre);
    _nombre = nombreLimpio.isEmpty ? nombrePorDefecto : nombreLimpio;
    _carrera = _recortar(carrera);
    notifyListeners();
    await _guardar(_claveNombre, nombreLimpio);
    await _guardar(_claveCarrera, _carrera);
  }

  /// Cambia el tema de la app.
  Future<void> cambiarTema(ThemeMode modo) async {
    if (modo == _modoTema) return;
    _modoTema = modo;
    notifyListeners();
    await _guardar(_claveTema, switch (modo) {
      ThemeMode.light => 'claro',
      ThemeMode.dark => 'oscuro',
      ThemeMode.system => 'sistema',
    });
  }

  /// Enciende o apaga el recordatorio diario y, si se indica, cambia su hora.
  Future<void> cambiarRecordatorio({
    required bool activo,
    TimeOfDay? hora,
  }) async {
    _recordatorioActivo = activo;
    if (hora != null) _horaRecordatorio = hora;
    notifyListeners();

    if (activo) {
      await _recordatorio.pedirPermisos();
      await _recordatorio.programarDiario(
        hora: _horaRecordatorio.hour,
        minuto: _horaRecordatorio.minute,
        titulo: 'Hora de estudiar 📚',
        cuerpo: 'Un bloque de enfoque hoy mantiene tu racha.',
      );
    } else {
      await _recordatorio.cancelarDiario();
    }
    await _guardar(_claveRecordatorio, activo ? '1' : '0');
    await _guardar(
      _claveHoraRecordatorio,
      '${_horaRecordatorio.hour}:${_horaRecordatorio.minute}',
    );
  }

  String _recortar(String texto) {
    final limpio = texto.trim();
    return limpio.length > maxTextoPerfil
        ? limpio.substring(0, maxTextoPerfil)
        : limpio;
  }

  Future<void> _guardar(String clave, String valor) async {
    try {
      await _repositorio.guardarAjuste(clave, valor);
    } catch (_) {
      // El cambio ya se aplicó en pantalla; solo no quedó guardado.
    }
  }

  TimeOfDay? _horaDesdeTexto(String? texto) {
    final partes = texto?.split(':');
    if (partes == null || partes.length != 2) return null;
    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null) return null;
    if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59) return null;
    return TimeOfDay(hour: hora, minute: minuto);
  }
}
