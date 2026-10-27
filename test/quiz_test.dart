import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy_ia/data/datos_demo.dart';
import 'package:studybuddy_ia/providers/estadisticas_provider.dart';
import 'package:studybuddy_ia/screens/quiz_screen.dart';

import 'support/repositorio_memoria.dart';

void main() {
  final materia = DatosDemo.materias.first;

  late RepositorioMemoria repositorio;

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    repositorio = RepositorioMemoria();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EstadisticasProvider(repositorio)..cargar(),
        child: MaterialApp(home: QuizScreen(materia: materia)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Responde una pregunta (bien o mal) y comprueba; no avanza a la siguiente.
  Future<void> responder(
    WidgetTester tester,
    int indice, {
    required bool acertar,
  }) async {
    final pregunta = materia.preguntas[indice];
    final correcta = pregunta.indiceRespuestaCorrecta;
    final elegida = acertar
        ? correcta
        : (correcta + 1) % pregunta.opciones.length;

    await tester.tap(find.text(pregunta.opciones[elegida]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprobar respuesta'));
    await tester.pumpAndSettle();
  }

  testWidgets('Al terminar el quiz se guarda un intento con aciertos y total', (
    WidgetTester tester,
  ) async {
    await montar(tester);
    final total = materia.preguntas.length;
    expect(total, 5);

    for (var i = 0; i < total; i++) {
      await responder(tester, i, acertar: i < 3);
      await tester.tap(
        find.text(i < total - 1 ? 'Siguiente pregunta' : 'Ver resultados'),
      );
      await tester.pumpAndSettle();
    }

    final intentos = await repositorio.obtenerIntentosQuiz();
    expect(intentos, hasLength(1));
    expect(intentos.single.aciertos, 3);
    expect(intentos.single.total, 5);
    expect(intentos.single.materiaId, materia.id);
  });

  testWidgets('No se guarda nada si el quiz se abandona antes de terminar', (
    WidgetTester tester,
  ) async {
    await montar(tester);

    await responder(tester, 0, acertar: true);
    await tester.tap(find.text('Siguiente pregunta'));
    await tester.pumpAndSettle();

    expect(await repositorio.obtenerIntentosQuiz(), isEmpty);
  });

  testWidgets('Un doble toque en "Ver resultados" guarda un solo intento', (
    WidgetTester tester,
  ) async {
    await montar(tester);
    final total = materia.preguntas.length;

    for (var i = 0; i < total; i++) {
      await responder(tester, i, acertar: true);
      if (i < total - 1) {
        await tester.tap(find.text('Siguiente pregunta'));
        await tester.pumpAndSettle();
      }
    }
    // Dos toques dentro del mismo cuadro: se invoca dos veces el manejador del botón.
    final boton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Ver resultados'),
    );
    boton.onPressed!();
    boton.onPressed!();
    await tester.pumpAndSettle();

    expect(await repositorio.obtenerIntentosQuiz(), hasLength(1));
  });
}
