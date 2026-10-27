import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notificador_pomodoro.dart';

/// Implementación real: una notificación programada con una alarma del sistema.
///
/// El aviso suena con el sonido de alarma y **repite la vibración** hasta que se
/// abre la app, se descarta o pasan 60 segundos (bandera `FLAG_INSISTENT`).
class NotificadorLocal implements NotificadorPomodoro {
  NotificadorLocal._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Identificador fijo: solo hay un aviso de Pomodoro a la vez.
  static const int _idNotificacion = 1;

  /// Identificador y nombre del canal de notificaciones de Android.
  static const String _idCanal = 'pomodoro_fin';
  static const String _nombreCanal = 'Fin de bloque Pomodoro';

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
    try {
      await _programarCon(
        AndroidScheduleMode.exactAllowWhileIdle,
        fin,
        titulo,
        cuerpo,
      );
    } catch (_) {
      // Si el sistema rechaza la alarma exacta, se usa una aproximada.
      try {
        await _programarCon(
          AndroidScheduleMode.inexactAllowWhileIdle,
          fin,
          titulo,
          cuerpo,
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> cancelar() async {
    try {
      await _plugin.cancel(id: _idNotificacion);
    } catch (_) {}
  }
}
