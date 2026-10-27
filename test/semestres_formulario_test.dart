import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/utils/semestres.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const campoSemestre = Key('campo-semestre');
  const campoNombre = Key('campo-nombre');
  const botonGuardar = Key('guardar-materia');

  /// Texto actual del campo de semestre del formulario abierto.
  String semestreEscrito(WidgetTester tester) =>
      tester.widget<TextFormField>(find.byKey(campoSemestre)).controller!.text;

  testWidgets('Abre con el semestre actual del calendario si no hay materias', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, RepositorioMemoria());

    await tester.tap(find.byKey(const Key('crear-primera-materia')));
    await tester.pumpAndSettle();

    expect(semestreEscrito(tester), semestreActual(DateTime.now()));
  });

  testWidgets('Al editar abre con el semestre de la materia', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes', semestre: '2025-1');
    await abrirApp(tester, repositorio);

    await tester.longPress(find.text('Redes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcion-editar-materia')));
    await tester.pumpAndSettle();

    expect(semestreEscrito(tester), '2025-1');
  });

  testWidgets('Tocar una sugerencia rellena el campo de semestre', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes', semestre: '2025-1');
    await abrirApp(tester, repositorio);

    await tester.tap(find.text('Nueva materia'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sugerencia-semestre-2025-1')), findsOneWidget);
    expect(
      find.byKey(Key('sugerencia-semestre-${semestreActual(DateTime.now())}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('sugerencia-semestre-2025-1')));
    await tester.pumpAndSettle();

    expect(semestreEscrito(tester), '2025-1');
  });

  testWidgets('Un semestre vacío no se guarda y se explica', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await abrirApp(tester, repositorio);

    await tester.tap(find.byKey(const Key('crear-primera-materia')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoNombre), 'Redes');
    await tester.enterText(find.byKey(campoSemestre), '   ');
    await tester.tap(find.byKey(botonGuardar));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el semestre.'), findsOneWidget);
    expect(await repositorio.obtenerMaterias(), isEmpty);
  });

  testWidgets('Un semestre de más de 20 caracteres no se guarda', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await abrirApp(tester, repositorio);

    await tester.tap(find.byKey(const Key('crear-primera-materia')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoNombre), 'Redes');
    await tester.enterText(find.byKey(campoSemestre), 'X' * 21);
    await tester.tap(find.byKey(botonGuardar));
    await tester.pumpAndSettle();

    expect(
      find.text('El semestre no puede pasar de 20 caracteres.'),
      findsOneWidget,
    );
    expect(await repositorio.obtenerMaterias(), isEmpty);
  });

  testWidgets('Guardar crea la materia con el semestre escrito', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await abrirApp(tester, repositorio);

    await tester.tap(find.byKey(const Key('crear-primera-materia')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoNombre), 'Redes');
    await tester.enterText(find.byKey(campoSemestre), '2025-1');
    await tester.tap(find.byKey(botonGuardar));
    await tester.pumpAndSettle();

    expect((await repositorio.obtenerMaterias()).single.semestre, '2025-1');
  });

  testWidgets('Editar cambia el semestre de la materia', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes', semestre: '2025-1');
    await abrirApp(tester, repositorio);

    await tester.longPress(find.text('Redes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcion-editar-materia')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoSemestre), '2026-1');
    await tester.tap(find.byKey(botonGuardar));
    await tester.pumpAndSettle();

    expect((await repositorio.obtenerMaterias()).single.semestre, '2026-1');
  });
}
