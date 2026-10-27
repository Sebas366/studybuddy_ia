import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy_ia/data/datos_demo.dart';
import 'package:studybuddy_ia/models/materia.dart';
import 'package:studybuddy_ia/providers/estadisticas_provider.dart';
import 'package:studybuddy_ia/screens/pomodoro_screen.dart';

import 'support/reloj_falso.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const botonIniciar = Key('pomodoro-iniciar-pausar');
  const botonReiniciar = Key('pomodoro-reiniciar');
  const botonSaltar = Key('pomodoro-saltar');
  final inicio = DateTime(2026, 10, 27, 9);

  late RepositorioMemoria repositorio;
  late RelojFalso reloj;

  /// Monta el Pomodoro con un reloj controlado y un repositorio en memoria.
  Future<void> montar(WidgetTester tester, {Materia? materia}) async {
    repositorio = RepositorioMemoria();
    reloj = RelojFalso(inicio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EstadisticasProvider(repositorio)..cargar(),
        child: MaterialApp(
          home: PomodoroScreen(materia: materia, ahora: reloj.call),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Deja pasar [duracion] en el reloj y dispara un tick del temporizador.
  Future<void> pasarTiempo(WidgetTester tester, Duration duracion) async {
    reloj.avanzar(duracion);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets(
    'Al terminar un bloque de enfoque se guarda una sesión de 1500 s con su materia y hora de inicio',
    (WidgetTester tester) async {
      final materia = DatosDemo.materias.first;
      await montar(tester, materia: materia);

      await tester.tap(find.byKey(botonIniciar));
      await tester.pump();
      await pasarTiempo(tester, const Duration(minutes: 25));

      final sesiones = await repositorio.obtenerSesionesEnfoque();
      expect(sesiones, hasLength(1));
      expect(sesiones.single.duracionSegundos, 1500);
      expect(sesiones.single.materiaId, materia.id);
      expect(sesiones.single.inicio, inicio);
      // Pasa solo al descanso corto.
      expect(find.text('05:00'), findsOneWidget);
    },
  );

  testWidgets(
    'Un tick tardío tras bloquear la pantalla completa el bloque y lo guarda una sola vez',
    (WidgetTester tester) async {
      await montar(tester);

      await tester.tap(find.byKey(botonIniciar));
      await tester.pump();
      // El celular estuvo bloqueado 26 minutos y llega un único tick.
      await pasarTiempo(tester, const Duration(minutes: 26));
      // Otros ticks posteriores no deben duplicar la sesión.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(await repositorio.obtenerSesionesEnfoque(), hasLength(1));
    },
  );

  testWidgets('El tiempo restante sigue la hora real y no los ticks', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(botonIniciar));
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 10));

    expect(find.text('15:00'), findsOneWidget);
  });

  testWidgets('Al volver a la app se recalcula el tiempo restante', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(botonIniciar));
    await tester.pump();
    // Pasa tiempo "con la app dormida": sin ticks del temporizador.
    reloj.avanzar(const Duration(minutes: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('15:00'), findsOneWidget);
  });

  testWidgets('Pausar conserva el tiempo y reanudar continúa desde ahí', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(botonIniciar));
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 5));
    expect(find.text('20:00'), findsOneWidget);

    await tester.tap(find.byKey(botonIniciar)); // pausa
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 3));
    expect(find.text('20:00'), findsOneWidget);

    await tester.tap(find.byKey(botonIniciar)); // reanuda
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 1));
    expect(find.text('19:00'), findsOneWidget);
  });

  testWidgets('Saltar y reiniciar un bloque no guardan sesiones', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(botonIniciar));
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 10));
    await tester.tap(find.byKey(botonReiniciar));
    await tester.pump();
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.byKey(botonIniciar));
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 20));
    await tester.tap(find.byKey(botonSaltar));
    await tester.pump();

    expect(await repositorio.obtenerSesionesEnfoque(), isEmpty);
  });

  testWidgets('Terminar un descanso no guarda una sesión', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    await tester.tap(find.text('Descanso Corto'));
    await tester.pump();
    await tester.tap(find.byKey(botonIniciar));
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 5));

    expect(await repositorio.obtenerSesionesEnfoque(), isEmpty);
    // Vuelve al enfoque.
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('Una sesión sin materia se guarda con materiaId nulo', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byKey(botonIniciar));
    await tester.pump();
    await pasarTiempo(tester, const Duration(minutes: 25));

    final sesiones = await repositorio.obtenerSesionesEnfoque();
    expect(sesiones.single.materiaId, isNull);
  });
}
