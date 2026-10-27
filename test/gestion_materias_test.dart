import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const opcionEditar = Key('opcion-editar-materia');
  const opcionBorrar = Key('opcion-borrar-materia');
  const campoNombre = Key('campo-nombre');
  final botonConfirmarBorrado = find.widgetWithText(TextButton, 'Borrar');
  final botonCancelar = find.widgetWithText(TextButton, 'Cancelar');

  Future<void> mantenerPulsada(WidgetTester tester, String nombre) async {
    await tester.longPress(find.text(nombre));
    await tester.pumpAndSettle();
  }

  testWidgets('Mantener pulsada una tarjeta ofrece editar y borrar',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await abrirApp(tester, repositorio);

    await mantenerPulsada(tester, 'Redes');

    expect(find.byKey(opcionEditar), findsOneWidget);
    expect(find.byKey(opcionBorrar), findsOneWidget);
  });

  testWidgets('Editar cambia el nombre y se refleja en Inicio',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await abrirApp(tester, repositorio);

    await mantenerPulsada(tester, 'Redes');
    await tester.tap(find.byKey(opcionEditar));
    await tester.pumpAndSettle();

    // El formulario abre con el nombre actual precargado.
    expect(find.text('Editar materia'), findsOneWidget);
    final campo = tester.widget<TextFormField>(find.byKey(campoNombre));
    expect(campo.controller!.text, 'Redes');

    await tester.enterText(find.byKey(campoNombre), 'Redes de Computadores');
    await tester.tap(find.byKey(const Key('guardar-materia')));
    await tester.pumpAndSettle();

    expect(find.text('Redes de Computadores'), findsOneWidget);
    expect(find.text('Redes'), findsNothing);
    expect((await repositorio.obtenerMaterias()).single.nombre,
        'Redes de Computadores');
  });

  testWidgets('Cancelar el borrado conserva la materia',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await abrirApp(tester, repositorio);

    await mantenerPulsada(tester, 'Redes');
    await tester.tap(find.byKey(opcionBorrar));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(botonCancelar);
    await tester.pumpAndSettle();

    expect(find.text('Redes'), findsOneWidget);
    expect(await repositorio.obtenerMaterias(), hasLength(1));
  });

  testWidgets('Confirmar el borrado elimina la materia y sus apuntes',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    final id = await sembrarMateria(repositorio, 'Redes');
    await repositorio.crearApunte(
        materiaId: id, titulo: 'DHCP', contenido: 'DORA');
    await repositorio.crearApunte(
        materiaId: id, titulo: 'DNS', contenido: 'BIND9');
    await abrirApp(tester, repositorio);

    await mantenerPulsada(tester, 'Redes');
    await tester.tap(find.byKey(opcionBorrar));
    await tester.pumpAndSettle();

    final dialogo = find.byType(AlertDialog);
    expect(
        find.descendant(of: dialogo, matching: find.textContaining('"Redes"')),
        findsOneWidget);
    expect(
        find.descendant(
            of: dialogo, matching: find.textContaining('y sus 2 apuntes')),
        findsOneWidget);

    await tester.tap(botonConfirmarBorrado);
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes materias'), findsOneWidget);
    expect(await repositorio.obtenerMaterias(), isEmpty);
  });

  testWidgets('El aviso de borrado usa el singular con un solo apunte',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    final id = await sembrarMateria(repositorio, 'Redes');
    await repositorio.crearApunte(
        materiaId: id, titulo: 'DHCP', contenido: 'DORA');
    await abrirApp(tester, repositorio);

    await mantenerPulsada(tester, 'Redes');
    await tester.tap(find.byKey(opcionBorrar));
    await tester.pumpAndSettle();

    expect(
        find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('y su 1 apunte')),
        findsOneWidget);
  });
}
