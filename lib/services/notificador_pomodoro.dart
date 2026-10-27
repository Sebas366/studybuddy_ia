/// Avisa al usuario cuando termina un bloque de Pomodoro, aunque la app esté cerrada.
///
/// Es una interfaz para poder cambiar la implementación real (alarma del
/// sistema) por una falsa en las pruebas.
abstract class NotificadorPomodoro {
  /// Pide el permiso de notificaciones (Android 13 o superior). Nunca lanza.
  Future<void> pedirPermisos();

  /// Programa un aviso para la hora [fin], reemplazando el anterior si lo había.
  Future<void> programar({
    required DateTime fin,
    required String titulo,
    required String cuerpo,
  });

  /// Quita el aviso programado y el que ya se esté mostrando (detiene la vibración).
  Future<void> cancelar();
}

/// Notificador que no hace nada; se usa si no se pudo iniciar el real.
class NotificadorNulo implements NotificadorPomodoro {
  const NotificadorNulo();

  @override
  Future<void> pedirPermisos() async {}

  @override
  Future<void> programar({
    required DateTime fin,
    required String titulo,
    required String cuerpo,
  }) async {}

  @override
  Future<void> cancelar() async {}
}
