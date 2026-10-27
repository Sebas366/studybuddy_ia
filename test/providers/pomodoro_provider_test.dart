import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/models/modo_pomodoro.dart';
import 'package:studybuddy_ia/providers/pomodoro_provider.dart';

import '../support/notificador_falso.dart';
import '../support/reloj_falso.dart';
import '../support/repositorio_memoria.dart';

void main() {
  final inicio = DateTime(2026, 10, 28, 9);

  late RepositorioMemoria repositorio;
  late RelojFalso reloj;
  late NotificadorFalso notificador;
  late List<({String? materiaId, DateTime inicio, int duracion})> sesiones;
  late List<PomodoroProvider> creados;

  /// Crea un provider nuevo sobre el mismo repositorio, reloj y notificador.
  PomodoroProvider nuevo() {
    final provider = PomodoroProvider(
      repositorio: repositorio,
      notificador: notificador,
      registrarSesion:
          ({
            String? materiaId,
            required DateTime inicio,
            required int duracionSegundos,
          }) async {
            sesiones.add((
              materiaId: materiaId,
              inicio: inicio,
              duracion: duracionSegundos,
            ));
            return true;
          },
      ahora: reloj.call,
    );
    creados.add(provider);
    return provider;
  }

  setUp(() {
    repositorio = RepositorioMemoria();
    reloj = RelojFalso(inicio);
    notificador = NotificadorFalso();
    sesiones = [];
    creados = [];
  });

  /// Deja pasar [duracion] en el reloj y dispara un tick del temporizador.
  Future<void> pasar(WidgetTester tester, Duration duracion) async {
    reloj.avanzar(duracion);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  /// Simula que la app se cierra: libera el provider y lo saca de la lista a limpiar.
  void cerrar(PomodoroProvider provider) {
    provider.dispose();
    creados.remove(provider);
  }

  /// Libera los temporizadores de los providers creados (los de las pruebas ya terminadas).
  void liberar() {
    for (final provider in creados) {
      provider.dispose();
    }
    creados.clear();
  }

  testWidgets('arranca en enfoque, detenido, con 15 s en modo demostración', (
    tester,
  ) async {
    final provider = nuevo();

    expect(provider.modo, ModoPomodoro.enfoque);
    expect(provider.modoDemo, isTrue);
    expect(provider.segundosRestantes, 15);
    expect(provider.corriendo, isFalse);
    expect(provider.hayBloqueActivo, isFalse);
    liberar();
  });

  testWidgets('sin modo demostración el enfoque dura 25 minutos', (
    tester,
  ) async {
    final provider = nuevo();

    await provider.alternarModoDemo(false);

    expect(provider.segundosRestantes, 1500);
    expect(provider.segundosTotales, 1500);
    liberar();
  });

  testWidgets('iniciar programa un aviso a la hora de fin y pide permisos', (
    tester,
  ) async {
    final provider = nuevo();
    provider.seleccionarMateria('m1', 'Redes');

    await provider.alternar();

    expect(provider.corriendo, isTrue);
    expect(notificador.permisosPedidos, 1);
    final aviso = notificador.programadas.single;
    expect(aviso.fin, inicio.add(const Duration(seconds: 15)));
    expect(aviso.titulo, '¡Bloque de enfoque terminado!');
    expect(aviso.cuerpo, 'Buen trabajo en Redes. Toma un descanso.');
    liberar();
  });

  testWidgets('el tiempo restante sigue la hora real, no los ticks', (
    tester,
  ) async {
    final provider = nuevo();
    await provider.alternar();

    await pasar(tester, const Duration(seconds: 10));

    expect(provider.segundosRestantes, 5);
    liberar();
  });

  testWidgets(
    'un tick tardío completa el bloque una sola vez y registra la sesión',
    (tester) async {
      final provider = nuevo();
      provider.seleccionarMateria('m1', 'Redes');
      await provider.alternar();

      await pasar(tester, const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(sesiones, hasLength(1));
      expect(sesiones.single.materiaId, 'm1');
      expect(sesiones.single.duracion, 15);
      // Se ubica justo antes de su hora de fin (aunque el tick llegara tarde).
      expect(sesiones.single.inicio, inicio);
      expect(provider.modo, ModoPomodoro.descansoCorto);
      expect(provider.segundosRestantes, 5);
      expect(provider.corriendo, isFalse);
      liberar();
    },
  );

  testWidgets('el cuarto enfoque lleva al descanso largo', (tester) async {
    final provider = nuevo();

    for (var i = 0; i < 4; i++) {
      await provider.cambiarModo(ModoPomodoro.enfoque);
      await provider.alternar();
      await pasar(tester, const Duration(seconds: 15));
    }

    expect(sesiones, hasLength(4));
    expect(provider.ciclosCompletados, 4);
    expect(provider.modo, ModoPomodoro.descansoLargo);
    expect(provider.segundosRestantes, 10);
    liberar();
  });

  testWidgets('terminar un descanso no registra sesión y vuelve al enfoque', (
    tester,
  ) async {
    final provider = nuevo();
    await provider.cambiarModo(ModoPomodoro.descansoCorto);
    await provider.alternar();

    await pasar(tester, const Duration(seconds: 5));

    expect(sesiones, isEmpty);
    expect(provider.modo, ModoPomodoro.enfoque);
    expect(provider.segundosRestantes, 15);
    expect(notificador.programadas.single.titulo, 'Descanso terminado');
    liberar();
  });

  testWidgets(
    'pausar cancela el aviso y conserva el tiempo; reanudar reprograma',
    (tester) async {
      final provider = nuevo();
      await provider.alternar();
      await pasar(tester, const Duration(seconds: 5));
      final cancelacionesAntes = notificador.cancelaciones;

      await provider.alternar(); // pausa

      expect(provider.corriendo, isFalse);
      expect(provider.segundosRestantes, 10);
      expect(notificador.cancelaciones, cancelacionesAntes + 1);

      await pasar(tester, const Duration(seconds: 20)); // en pausa no avanza
      expect(provider.segundosRestantes, 10);

      await provider.alternar(); // reanuda
      expect(notificador.programadas, hasLength(2));
      expect(
        notificador.programadas.last.fin,
        reloj.actual.add(const Duration(seconds: 10)),
      );
      liberar();
    },
  );

  testWidgets(
    'reiniciar, saltar y cambiar de modo cancelan el aviso y no registran sesión',
    (tester) async {
      final provider = nuevo();

      await provider.alternar();
      var cancelaciones = notificador.cancelaciones;
      await provider.reiniciar();
      expect(notificador.cancelaciones, cancelaciones + 1);
      expect(provider.segundosRestantes, 15);
      expect(provider.corriendo, isFalse);

      await provider.alternar();
      cancelaciones = notificador.cancelaciones;
      await provider.saltar();
      expect(notificador.cancelaciones, cancelaciones + 1);
      expect(provider.modo, ModoPomodoro.descansoCorto);

      await provider.alternar();
      cancelaciones = notificador.cancelaciones;
      await provider.cambiarModo(ModoPomodoro.descansoLargo);
      expect(notificador.cancelaciones, cancelaciones + 1);
      expect(provider.modo, ModoPomodoro.descansoLargo);

      expect(sesiones, isEmpty);
      liberar();
    },
  );

  testWidgets(
    'guarda el estado en curso al iniciar, pausar y lo borra al reiniciar',
    (tester) async {
      final provider = nuevo();
      provider.seleccionarMateria('m1', 'Redes');

      await provider.alternar();
      var estado = (await repositorio.obtenerPomodoroEnCurso())!;
      expect(estado.corriendo, isTrue);
      expect(estado.fin, inicio.add(const Duration(seconds: 15)));
      expect(estado.segundosTotales, 15);
      expect(estado.materiaId, 'm1');
      expect(estado.materiaNombre, 'Redes');

      await pasar(tester, const Duration(seconds: 5));
      await provider.alternar(); // pausa
      estado = (await repositorio.obtenerPomodoroEnCurso())!;
      expect(estado.corriendo, isFalse);
      expect(estado.fin, isNull);
      expect(estado.segundosRestantes, 10);

      await provider.reiniciar();
      expect(await repositorio.obtenerPomodoroEnCurso(), isNull);
      liberar();
    },
  );

  testWidgets(
    'restaurar un bloque corriendo con fin futuro lo reanuda y reprograma el aviso',
    (tester) async {
      final primero = nuevo();
      primero.seleccionarMateria('m1', 'Redes');
      await primero.alternar();
      await pasar(tester, const Duration(seconds: 5));
      cerrar(primero); // la app se cierra

      final segundo = nuevo();
      await segundo.restaurar();

      expect(segundo.corriendo, isTrue);
      expect(segundo.segundosRestantes, 10);
      expect(segundo.materiaNombre, 'Redes');
      expect(
        notificador.programadas.last.fin,
        inicio.add(const Duration(seconds: 15)),
      );

      await pasar(tester, const Duration(seconds: 10));
      expect(sesiones, hasLength(1));
      liberar();
    },
  );

  testWidgets('restaurar un bloque ya vencido lo completa una sola vez', (
    tester,
  ) async {
    final primero = nuevo();
    primero.seleccionarMateria('m1', 'Redes');
    await primero.alternar();
    cerrar(primero); // la app se cierra y pasa más tiempo que el bloque

    reloj.avanzar(const Duration(seconds: 60));
    final segundo = nuevo();
    await segundo.restaurar();
    await segundo.restaurar();

    expect(sesiones, hasLength(1));
    expect(sesiones.single.inicio, inicio);
    expect(segundo.modo, ModoPomodoro.descansoCorto);
    expect(segundo.corriendo, isFalse);
    expect(await repositorio.obtenerPomodoroEnCurso(), isNull);
    liberar();
  });

  testWidgets('restaurar un bloque en pausa lo deja detenido con su tiempo', (
    tester,
  ) async {
    final primero = nuevo();
    await primero.alternar();
    await pasar(tester, const Duration(seconds: 5));
    await primero.alternar(); // pausa
    cerrar(primero);

    final segundo = nuevo();
    await segundo.restaurar();

    expect(segundo.corriendo, isFalse);
    expect(segundo.segundosRestantes, 10);
    expect(segundo.hayBloqueActivo, isTrue);
    liberar();
  });

  testWidgets(
    'al volver a la app se descarta el aviso y se reprograma si corre',
    (tester) async {
      final provider = nuevo();

      await provider.alReanudarApp(); // sin bloque: solo descarta
      expect(notificador.cancelaciones, 1);
      expect(notificador.programadas, isEmpty);

      await provider.alternar();
      final fin = notificador.programadas.single.fin;
      await provider.alReanudarApp();

      expect(notificador.cancelaciones, 2);
      expect(notificador.programadas, hasLength(2));
      expect(notificador.programadas.last.fin, fin);
      liberar();
    },
  );

  testWidgets(
    'al volver a la app completa un bloque que venció en segundo plano',
    (tester) async {
      final provider = nuevo();
      await provider.alternar();

      reloj.avanzar(const Duration(seconds: 30));
      await provider.alReanudarApp();

      expect(sesiones, hasLength(1));
      expect(provider.modo, ModoPomodoro.descansoCorto);
      liberar();
    },
  );

  testWidgets(
    'la materia solo se puede cambiar cuando no hay un bloque activo',
    (tester) async {
      final provider = nuevo();
      provider.seleccionarMateria('m1', 'Redes');
      await provider.alternar();

      provider.seleccionarMateria('m2', 'Cálculo');
      expect(provider.materiaId, 'm1');

      await provider.reiniciar();
      provider.seleccionarMateria('m2', 'Cálculo');
      expect(provider.materiaId, 'm2');
      expect(provider.materiaNombre, 'Cálculo');
      liberar();
    },
  );

  testWidgets(
    'el modo demostración no altera un bloque iniciado y se conserva',
    (tester) async {
      final provider = nuevo();
      await provider.alternar();

      await provider.alternarModoDemo(false);

      expect(provider.modoDemo, isFalse);
      expect(provider.segundosRestantes, 15); // el bloque iniciado no cambia
      expect(provider.segundosTotales, 15);

      // Al terminar, el siguiente bloque ya usa la duración normal.
      await pasar(tester, const Duration(seconds: 15));
      expect(provider.modo, ModoPomodoro.descansoCorto);
      expect(provider.segundosRestantes, 300);

      // El ajuste sobrevive a una app nueva.
      final otro = nuevo();
      await otro.restaurar();
      expect(otro.modoDemo, isFalse);
      liberar();
    },
  );

  testWidgets(
    'el aviso se programa sin esperar la respuesta del permiso de notificaciones',
    (tester) async {
      final permiso = Completer<void>();
      notificador.permisoPendiente = permiso; // el diálogo sigue abierto
      final provider = nuevo();

      unawaited(provider.alternar());
      await tester.pump();

      expect(notificador.programadas, hasLength(1));
      expect(
        notificador.programadas.single.fin,
        inicio.add(const Duration(seconds: 15)),
      );
      permiso.complete();
      await tester.pump();
      liberar();
    },
  );

  testWidgets('prepararAvisos pide los permisos una sola vez', (tester) async {
    final provider = nuevo();

    await provider.prepararAvisos();
    await provider.prepararAvisos();
    await provider.alternar();

    expect(notificador.permisosPedidos, 1);
    liberar();
  });
}
