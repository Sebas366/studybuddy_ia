import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy_ia/data/datos_demo.dart';
import 'package:studybuddy_ia/providers/materias_provider.dart';
import 'package:studybuddy_ia/screens/detalle_materia_screen.dart';
import 'package:studybuddy_ia/utils/formato_fecha.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const botonNuevoApunte = Key('nuevo-apunte');
  const campoTitulo = Key('campo-titulo-apunte');
  const campoTexto = Key('campo-texto-apunte');
  const botonGuardarApunte = Key('guardar-apunte');
  const textoVacio = 'Aún no tienes apuntes. Toca "+ Nuevo" para crear el primero.';

  /// Abre la app con una materia real llamada 'Redes' y entra a su detalle.
  Future<void> entrarAlDetalle(
      WidgetTester tester, RepositorioMemoria repositorio) async {
    await abrirApp(tester, repositorio);
    await tester.tap(find.text('Redes'));
    await tester.pumpAndSettle();
  }

  Future<void> escribirYGuardarApunte(
      WidgetTester tester, String titulo, String texto) async {
    await tester.tap(find.byKey(botonNuevoApunte));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoTitulo), titulo);
    await tester.enterText(find.byKey(campoTexto), texto);
    await tester.tap(find.byKey(botonGuardarApunte));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Una materia nueva muestra el mensaje de apuntes vacíos y no muestra progreso',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await entrarAlDetalle(tester, repositorio);

    expect(find.text(textoVacio), findsOneWidget);
    expect(find.textContaining('dominado'), findsNothing);
  });

  testWidgets('Crear un apunte lo agrega a la lista con la fecha de hoy',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await entrarAlDetalle(tester, repositorio);

    await escribirYGuardarApunte(
        tester, 'DHCP y proceso DORA', 'Discover, Offer, Request, Ack');

    expect(find.text('DHCP y proceso DORA'), findsOneWidget);
    expect(find.text(formatearFecha(DateTime.now())), findsOneWidget);
    expect(find.text('1 apunte'), findsOneWidget);
    expect(find.text(textoVacio), findsNothing);
  });

  testWidgets('No guarda apuntes sin título o sin texto',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await entrarAlDetalle(tester, repositorio);

    await tester.tap(find.byKey(botonNuevoApunte));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(botonGuardarApunte));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el título del apunte.'), findsOneWidget);
    expect(find.text('Escribe el texto del apunte.'), findsOneWidget);
    expect((await repositorio.obtenerMaterias()).single.apuntes, isEmpty);
  });

  testWidgets('Doble toque en Guardar crea un solo apunte',
      (WidgetTester tester) async {
    final repositorio = RepositorioLento();
    repositorio.compuertaMaterias.complete();
    await sembrarMateria(repositorio, 'Redes');
    await entrarAlDetalle(tester, repositorio);

    await tester.tap(find.byKey(botonNuevoApunte));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoTitulo), 'DHCP');
    await tester.enterText(find.byKey(campoTexto), 'DORA');
    await tester.tap(find.byKey(botonGuardarApunte));
    await tester.pump();
    await tester.tap(find.byKey(botonGuardarApunte));
    await tester.pump();

    repositorio.compuertaApuntes.complete();
    await tester.pumpAndSettle();

    expect((await repositorio.obtenerMaterias()).single.apuntes, hasLength(1));
  });

  testWidgets('Editar un apunte cambia su título', (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    final id = await sembrarMateria(repositorio, 'Redes');
    await repositorio.crearApunte(
        materiaId: id, titulo: 'DHCP', contenido: 'DORA');
    await entrarAlDetalle(tester, repositorio);

    await tester.longPress(find.text('DHCP'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcion-editar-apunte')));
    await tester.pumpAndSettle();

    // El formulario abre con los datos actuales.
    final campo = tester.widget<TextFormField>(find.byKey(campoTitulo));
    expect(campo.controller!.text, 'DHCP');

    await tester.enterText(find.byKey(campoTitulo), 'DHCP avanzado');
    await tester.tap(find.byKey(botonGuardarApunte));
    await tester.pumpAndSettle();

    expect(find.text('DHCP avanzado'), findsOneWidget);
    expect((await repositorio.obtenerMaterias()).single.apuntes.single.titulo,
        'DHCP avanzado');
  });

  testWidgets('Borrar un apunte pide confirmación y lo elimina',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    final id = await sembrarMateria(repositorio, 'Redes');
    await repositorio.crearApunte(
        materiaId: id, titulo: 'DHCP', contenido: 'DORA');
    await entrarAlDetalle(tester, repositorio);

    await tester.longPress(find.text('DHCP'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcion-borrar-apunte')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('DHCP'), findsNothing);
    expect(find.text(textoVacio), findsOneWidget);
    expect((await repositorio.obtenerMaterias()).single.apuntes, isEmpty);
  });

  testWidgets('Borrar la materia desde su detalle vuelve a Inicio',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await entrarAlDetalle(tester, repositorio);

    await tester.tap(find.byKey(const Key('menu-materia')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-borrar-materia')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes materias'), findsOneWidget);
    expect(find.text(textoVacio), findsNothing);
    expect(tester.takeException(), isNull);
    expect(await repositorio.obtenerMaterias(), isEmpty);
  });

  testWidgets('Editar la materia desde su detalle actualiza la cabecera',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await entrarAlDetalle(tester, repositorio);

    await tester.tap(find.byKey(const Key('menu-materia')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-editar-materia')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo-nombre')), 'Redes II');
    await tester.tap(find.byKey(const Key('guardar-materia')));
    await tester.pumpAndSettle();

    expect(find.text('Redes II'), findsOneWidget);
  });

  testWidgets('Una materia de demostración no muestra menú ni "+ Nuevo"',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MateriasProvider(RepositorioMemoria())..cargar(),
        child: MaterialApp(
          home: DetalleMateriaScreen(materia: DatosDemo.materias.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('menu-materia')), findsNothing);
    expect(find.byKey(botonNuevoApunte), findsNothing);
    expect(find.textContaining('dominado'), findsOneWidget);
  });
}
