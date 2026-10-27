import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/models/estado_pomodoro.dart';
import 'package:studybuddy_ia/models/modo_pomodoro.dart';

void main() {
  group('ModoPomodoro', () {
    test('en modo normal dura 25, 5 y 15 minutos', () {
      expect(ModoPomodoro.enfoque.segundos(demo: false), 1500);
      expect(ModoPomodoro.descansoCorto.segundos(demo: false), 300);
      expect(ModoPomodoro.descansoLargo.segundos(demo: false), 900);
    });

    test('en modo demostración dura 15, 5 y 10 segundos', () {
      expect(ModoPomodoro.enfoque.segundos(demo: true), 15);
      expect(ModoPomodoro.descansoCorto.segundos(demo: true), 5);
      expect(ModoPomodoro.descansoLargo.segundos(demo: true), 10);
    });

    test('tiene etiquetas e iconos', () {
      expect(ModoPomodoro.enfoque.etiqueta, 'Enfoque');
      expect(ModoPomodoro.descansoCorto.etiqueta, 'Descanso Corto');
      expect(ModoPomodoro.descansoLargo.etiqueta, 'Descanso Largo');
      expect(ModoPomodoro.enfoque.icono, Icons.center_focus_strong_rounded);
      expect(ModoPomodoro.descansoCorto.icono, Icons.coffee_rounded);
      expect(ModoPomodoro.descansoLargo.icono, Icons.weekend_rounded);
    });
  });

  test('EstadoPomodoro guarda sus campos', () {
    final fin = DateTime(2026, 10, 28, 9, 30);
    final estado = EstadoPomodoro(
      modo: ModoPomodoro.enfoque,
      corriendo: true,
      fin: fin,
      segundosRestantes: 10,
      segundosTotales: 15,
      ciclos: 2,
      materiaId: 'mat_1',
      materiaNombre: 'Redes',
    );

    expect(estado.modo, ModoPomodoro.enfoque);
    expect(estado.corriendo, isTrue);
    expect(estado.fin, fin);
    expect(estado.segundosRestantes, 10);
    expect(estado.segundosTotales, 15);
    expect(estado.ciclos, 2);
    expect(estado.materiaId, 'mat_1');
    expect(estado.materiaNombre, 'Redes');
  });
}
