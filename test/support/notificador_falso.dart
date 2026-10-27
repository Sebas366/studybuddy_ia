import 'dart:async';

import 'package:studybuddy_ia/services/notificador_pomodoro.dart';

/// Notificador de pruebas: no muestra nada, solo registra lo que se le pide.
class NotificadorFalso implements NotificadorPomodoro {
  /// Cuántas veces se pidieron los permisos.
  int permisosPedidos = 0;

  /// Avisos programados, en orden.
  final List<({DateTime fin, String titulo, String cuerpo})> programadas = [];

  /// Cuántas veces se canceló el aviso.
  int cancelaciones = 0;

  /// Si no es nulo, `pedirPermisos` espera a que se complete (simula el diálogo abierto).
  Completer<void>? permisoPendiente;

  @override
  Future<void> pedirPermisos() async {
    permisosPedidos++;
    await permisoPendiente?.future;
  }

  @override
  Future<void> programar({
    required DateTime fin,
    required String titulo,
    required String cuerpo,
  }) async {
    programadas.add((fin: fin, titulo: titulo, cuerpo: cuerpo));
  }

  @override
  Future<void> cancelar() async {
    cancelaciones++;
  }
}
