import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notificador_pomodoro.dart';

/// Implementación real: una notificación programada con una alarma del sistema.
///
/// El aviso del Pomodoro suena con el sonido de alarma y **repite la vibración**
/// hasta que se abre la app, se descarta o pasan 60 segundos (bandera
/// `FLAG_INSISTENT`). El recordatorio diario es una notificación normal.
class NotificadorLocal implements NotificadorPomodoro, NotificadorRecordatorio {
  NotificadorLocal._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Identificador fijo: solo hay un aviso de Pomodoro a la vez.
  static const int _idNotificacion = 1;

  /// Identificador y nombre del canal de notificaciones de Android.
  static const String _idCanal = 'pomodoro_fin';
  static const String _nombreCanal = 'Fin de bloque Pomodoro';

  /// Identificador y canal del recordatorio diario de estudio.
  static const int _idRecordatorio = 2;
  static const String _idCanalRecordatorio = 'recordatorio_estudio';
  static const String _nombreCanalRecordatorio = 'Recordatorio de estudio';

  /// Inicializa el plugin. Lanza si el sistema no lo permite.
  static Future<NotificadorLocal> crear() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    return NotificadorLocal._(plugin);
  }

  /// Detalles del aviso: máxima prioridad, alarma, sonido y vibración repetida.
  NotificationDetails _detalles() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _idCanal,
        _nombreCanal,
        channelDescription:
            'Avisa cuando termina un bloque de enfoque o de descanso',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400]),
        // 4 = FLAG_INSISTENT: repite el sonido y la vibración hasta que se atienda.
        additionalFlags: Int32List.fromList([4]),
        timeoutAfter: 60000,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  @override
  Future<void> pedirPermisos() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Sin permiso el Pomodoro sigue funcionando, solo que sin aviso.
    }
  }

  Future<void> _programarCon(
    AndroidScheduleMode modo,
    DateTime fin,
    String titulo,
    String cuerpo,
  ) {
    return _plugin.zonedSchedule(
      id: _idNotificacion,
      scheduledDate: tz.TZDateTime.from(fin, tz.UTC),
      notificationDetails: _detalles(),
      androidScheduleMode: modo,
      title: titulo,
      body: cuerpo,
    );
  }

  @override
  Future<void> programar({
    required DateTime fin,
    required String titulo,
    required String cuerpo,
  }) async {
    // Se prueba del modo más fiable al menos: la alarma de reloj no la congelan
    // ni la retrasan los ahorros de batería (algunos celulares congelan las apps
    // en segundo plano y no entregan las alarmas comunes).
    const modos = [
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];
    for (final modo in modos) {
      try {
        await _programarCon(modo, fin, titulo, cuerpo);
        return;
      } catch (_) {
        // Si el sistema rechaza este tipo de alarma, se intenta con el siguiente.
      }
    }
  }

  @override
  Future<void> cancelar() async {
    try {
      await _plugin.cancel(id: _idNotificacion);
    } catch (_) {}
  }

  @override
  Future<void> programarDiario({
    required int hora,
    required int minuto,
    required String titulo,
    required String cuerpo,
  }) async {
    // Próxima vez que el reloj local marque esa hora: hoy, o mañana si ya pasó.
    final ahora = DateTime.now();
    var proxima = DateTime(ahora.year, ahora.month, ahora.day, hora, minuto);
    if (!proxima.isAfter(ahora)) {
      proxima = DateTime(ahora.year, ahora.month, ahora.day + 1, hora, minuto);
    }
    try {
      // Se repite a la misma hora UTC cada día, que equivale a la misma hora
      // local mientras la zona no cambie de horario (Colombia no lo hace).
      await _plugin.zonedSchedule(
        id: _idRecordatorio,
        scheduledDate: tz.TZDateTime.from(proxima, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _idCanalRecordatorio,
            _nombreCanalRecordatorio,
            channelDescription: 'Aviso diario para mantener la racha de estudio',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        title: titulo,
        body: cuerpo,
      );
    } catch (_) {
      // Sin recordatorio la app sigue funcionando.
    }
  }

  @override
  Future<void> cancelarDiario() async {
    try {
      await _plugin.cancel(id: _idRecordatorio);
    } catch (_) {}
  }
}
