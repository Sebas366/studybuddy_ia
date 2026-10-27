import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const selector = Key('selector-semestre');

  /// Texto del semestre que muestra el selector en este momento.
  Finder textoEnSelector(String texto) =>
      find.descendant(of: find.byKey(selector), matching: find.text(texto));

  /// Abre el menú del selector y elige una opción (`semestre-2026-1`, `semestre-todos`, ...).
  Future<void> elegir(WidgetTester tester, String clave) async {
    await tester.tap(find.byKey(selector));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(clave)));
    await tester.pumpAndSettle();
  }

  /// Siembra 'Vieja' (2026-1) y después 'Nueva' (2026-2): la más reciente es 'Nueva'.
  Future<RepositorioMemoria> dosSemestres() async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Vieja', semestre: '2026-1');
    await sembrarMateria(repositorio, 'Nueva', semestre: '2026-2');
    return repositorio;
  }

  testWidgets(
    'Arranca en el semestre de la materia más reciente y oculta el resto',
    (WidgetTester tester) async {
      await abrirApp(tester, await dosSemestres());

      expect(find.text('Nueva'), findsOneWidget);
      expect(find.text('Vieja'), findsNothing);
      expect(textoEnSelector('2026-2'), findsOneWidget);
      expect(find.text('Mis Materias (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'Elegir otro semestre cambia la lista y Todos las muestra todas con su semestre',
    (WidgetTester tester) async {
      await abrirApp(tester, await dosSemestres());

      await elegir(tester, 'semestre-2026-1');
      expect(find.text('Vieja'), findsOneWidget);
      expect(find.text('Nueva'), findsNothing);
      expect(textoEnSelector('2026-1'), findsOneWidget);

      await elegir(tester, 'semestre-todos');
      expect(find.text('Vieja'), findsOneWidget);
      expect(find.text('Nueva'), findsOneWidget);
      expect(textoEnSelector('Todos'), findsOneWidget);
      expect(find.text('Mis Materias (2)'), findsOneWidget);
      expect(find.text('2026-1 · Sin apuntes'), findsOneWidget);
      expect(find.text('2026-2 · Sin apuntes'), findsOneWidget);
    },
  );

  testWidgets('El buscador encuentra materias de otros semestres', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, await dosSemestres());
    expect(find.text('Vieja'), findsNothing);

    await tester.enterText(find.byType(TextField), 'vieja');
    await tester.pumpAndSettle();
    expect(find.text('Vieja'), findsOneWidget);
    expect(find.text('2026-1 · Sin apuntes'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Vieja'), findsNothing);
    expect(find.text('Nueva'), findsOneWidget);
  });

  testWidgets(
    'Crear una materia en otro semestre cambia la vista a ese semestre',
    (WidgetTester tester) async {
      await abrirApp(tester, await dosSemestres());

      await tester.tap(find.text('Nueva materia'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campo-nombre')), 'Cálculo');
      await tester.enterText(find.byKey(const Key('campo-semestre')), '2025-2');
      await tester.tap(find.byKey(const Key('guardar-materia')));
      await tester.pumpAndSettle();

      expect(find.text('Cálculo'), findsOneWidget);
      expect(textoEnSelector('2025-2'), findsOneWidget);
      expect(find.text('Nueva'), findsNothing);
    },
  );

  testWidgets(
    'El formulario de materia nueva abre con el semestre que se está viendo',
    (WidgetTester tester) async {
      await abrirApp(tester, await dosSemestres());
      await elegir(tester, 'semestre-2026-1');

      await tester.tap(find.text('Nueva materia'));
      await tester.pumpAndSettle();

      final campo = tester.widget<TextFormField>(
        find.byKey(const Key('campo-semestre')),
      );
      expect(campo.controller!.text, '2026-1');
    },
  );

  testWidgets(
    'Borrar la última materia del semestre vuelve al más reciente que queda',
    (WidgetTester tester) async {
      await abrirApp(tester, await dosSemestres());

      await tester.longPress(find.text('Nueva'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-borrar-materia')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('Vieja'), findsOneWidget);
      expect(textoEnSelector('2026-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Mover una materia a otro semestre hace que la vista la siga', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, await dosSemestres());

    await tester.longPress(find.text('Nueva'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcion-editar-materia')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-semestre')), '2026-1');
    await tester.tap(find.byKey(const Key('guardar-materia')));
    await tester.pumpAndSettle();

    expect(find.text('Nueva'), findsOneWidget);
    expect(find.text('Vieja'), findsOneWidget);
    expect(textoEnSelector('2026-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Con una sola materia el selector muestra su semestre', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes', semestre: '2025-2');
    await abrirApp(tester, repositorio);

    expect(find.text('Redes'), findsOneWidget);
    expect(textoEnSelector('2025-2'), findsOneWidget);
  });

  testWidgets(
    'Si se borra la última materia del semestre elegido, la vista vuelve a otro con materias',
    (WidgetTester tester) async {
      await abrirApp(tester, await dosSemestres());
      await elegir(tester, 'semestre-2026-1'); // elección explícita
      expect(find.text('Vieja'), findsOneWidget);

      await tester.longPress(find.text('Vieja'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-borrar-materia')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva'), findsOneWidget);
      expect(textoEnSelector('2026-2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
