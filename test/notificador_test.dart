import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/services/notificador_pomodoro.dart';

import 'support/notificador_falso.dart';

void main() {
  test('NotificadorNulo completa todas las operaciones sin lanzar', () async {
    const notificador = NotificadorNulo();

    await notificador.pedirPermisos();
    await notificador.programar(
      fin: DateTime(2026, 10, 28, 9),
      titulo: 'Título',
      cuerpo: 'Cuerpo',
    );
    await notificador.cancelar();
  });

  test('NotificadorFalso registra lo que se le pide', () async {
    final notificador = NotificadorFalso();
    final fin = DateTime(2026, 10, 28, 9, 30);

    await notificador.pedirPermisos();
    await notificador.programar(fin: fin, titulo: 'T', cuerpo: 'C');
    await notificador.cancelar();

    expect(notificador.permisosPedidos, 1);
    expect(notificador.programadas.single.fin, fin);
    expect(notificador.programadas.single.titulo, 'T');
    expect(notificador.cancelaciones, 1);
  });
}
