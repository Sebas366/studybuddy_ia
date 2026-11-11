import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/services/almacen_clave.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';

import 'providers/ia_y_ajustes_provider_test.dart' show RecordatorioFalso;
import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';
import 'support/servicio_ia_falso.dart';

void main() {
  late RepositorioMemoria repositorio;

  setUp(() => repositorio = RepositorioMemoria());

  Future<void> abrirPerfil(
    WidgetTester tester, {
    ServicioIaFalso? ia,
    AlmacenClave? almacenClave,
    RecordatorioFalso? recordatorio,
  }) async {
    await abrirApp(
      tester,
      repositorio,
      ia: ia,
      almacenClave: almacenClave,
      recordatorio: recordatorio,
    );
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
  }

  group('Datos del usuario', () {
    testWidgets('Editar el perfil cambia el nombre en Perfil y en Inicio', (
      tester,
    ) async {
      await abrirPerfil(tester);
      expect(find.text('Estudiante'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editar-perfil')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-nombre-perfil')),
        'Edwin',
      );
      await tester.enterText(
        find.byKey(const Key('campo-carrera-perfil')),
        'Ingeniería de Sistemas',
      );
      await tester.tap(find.byKey(const Key('guardar-perfil')));
      await tester.pumpAndSettle();

      expect(find.text('Edwin'), findsOneWidget);
      expect(find.text('Ingeniería de Sistemas'), findsOneWidget);

      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      expect(find.text('¡Hola, Edwin! 👋'), findsOneWidget);
    });

    testWidgets('El nombre sigue ahí al reabrir la app', (tester) async {
      await abrirPerfil(tester);
      await tester.tap(find.byKey(const Key('editar-perfil')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-nombre-perfil')),
        'Edwin',
      );
      await tester.tap(find.byKey(const Key('guardar-perfil')));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await abrirApp(tester, repositorio);

      expect(find.text('¡Hola, Edwin! 👋'), findsOneWidget);
    });

    testWidgets('Cancelar la edición no cambia nada', (tester) async {
      await abrirPerfil(tester);

      await tester.tap(find.byKey(const Key('editar-perfil')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-nombre-perfil')),
        'Otro',
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Estudiante'), findsOneWidget);
      expect(find.text('Otro'), findsNothing);
    });
  });

  testWidgets('El modo oscuro queda guardado al reabrir la app', (tester) async {
    await abrirPerfil(tester);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Modo Oscuro'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await abrirApp(tester, repositorio);

    final contexto = tester.element(find.text('StudyBuddy IA'));
    expect(Theme.of(contexto).brightness, Brightness.dark);
  });

  group('Recordatorio de estudio', () {
    testWidgets('Encenderlo lo programa a las 6:00 PM y apagarlo lo cancela', (
      tester,
    ) async {
      final recordatorio = RecordatorioFalso();
      await abrirPerfil(tester, recordatorio: recordatorio);
      expect(
        find.text('Aviso diario a las 6:00 PM para mantener la racha'),
        findsOneWidget,
      );

      final interruptor = find.byKey(const Key('recordatorio-estudio'));
      await tester.ensureVisible(interruptor);
      await tester.tap(interruptor);
      await tester.pumpAndSettle();

      expect(recordatorio.programados.single, (hora: 18, minuto: 0));
      expect(await repositorio.obtenerAjuste('recordatorio_activo'), '1');

      await tester.tap(interruptor);
      await tester.pumpAndSettle();

      expect(recordatorio.cancelaciones, 1);
      expect(await repositorio.obtenerAjuste('recordatorio_activo'), '0');
    });
  });

  group('Inteligencia artificial', () {
    testWidgets('Sin clave aparece sin conectar y solo ofrece conectarla', (
      tester,
    ) async {
      await abrirPerfil(tester);

      expect(find.text('Sin conectar'), findsOneWidget);
      expect(find.text('Conectar la IA'), findsOneWidget);
      expect(find.byKey(const Key('probar-ia')), findsNothing);
      expect(find.byKey(const Key('quitar-clave-ia')), findsNothing);
    });

    testWidgets('Guardar la clave la deja conectada y sin mostrarla completa', (
      tester,
    ) async {
      final almacen = AlmacenClaveMemoria();
      await abrirPerfil(tester, almacenClave: almacen);

      final boton = find.byKey(const Key('conectar-ia'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-clave-ia')),
        'sk-ant-api03-clave-secreta-9876',
      );
      await tester.tap(find.byKey(const Key('guardar-clave-ia')));
      await tester.pumpAndSettle();

      // Al pegar una clave de Claude, el selector cambia solo a Claude.
      expect(find.text('Conectada · Claude · sk-ant-…9876'), findsOneWidget);
      expect(find.textContaining('clave-secreta'), findsNothing);
      expect(find.text('Cambiar clave'), findsOneWidget);
      expect(await almacen.leer(), 'claude|sk-ant-api03-clave-secreta-9876');
    });

    testWidgets('Por defecto propone Gemini, que es gratis, y la guarda así', (
      tester,
    ) async {
      final almacen = AlmacenClaveMemoria();
      await abrirPerfil(tester, almacenClave: almacen);
      final boton = find.byKey(const Key('conectar-ia'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.textContaining('aistudio.google.com'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('campo-clave-ia')),
        'AIzaSyClaveDeGemini4321',
      );
      await tester.tap(find.byKey(const Key('guardar-clave-ia')));
      await tester.pumpAndSettle();

      expect(find.text('Conectada · Gemini · AIzaSyC…4321'), findsOneWidget);
      expect(await almacen.leer(), 'gemini|AIzaSyClaveDeGemini4321');
    });

    testWidgets('Se puede elegir Claude a mano en el selector', (tester) async {
      final almacen = AlmacenClaveMemoria();
      await abrirPerfil(tester, almacenClave: almacen);
      final boton = find.byKey(const Key('conectar-ia'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('proveedor-claude')));
      await tester.pumpAndSettle();
      expect(find.textContaining('platform.claude.com'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('campo-clave-ia')),
        'clave-sin-forma-conocida-0000',
      );
      await tester.tap(find.byKey(const Key('guardar-clave-ia')));
      await tester.pumpAndSettle();

      expect(await almacen.leer(), 'claude|clave-sin-forma-conocida-0000');
    });

    testWidgets('Una clave vacía muestra el error y no se guarda', (
      tester,
    ) async {
      await abrirPerfil(tester);
      final boton = find.byKey(const Key('conectar-ia'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guardar-clave-ia')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu clave de la API.'), findsOneWidget);
      expect(find.text('Conectar la IA'), findsWidgets);
    });

    testWidgets('"Probar conexión" avisa si la clave funciona', (tester) async {
      final ia = ServicioIaFalso();
      await abrirPerfil(tester, ia: ia);

      final boton = find.byKey(const Key('probar-ia'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(ia.llamadas, ['probar']);
      expect(find.text('Conexión correcta: la IA está lista.'), findsOneWidget);
    });

    testWidgets('"Probar conexión" muestra el motivo si la clave no sirve', (
      tester,
    ) async {
      final ia = ServicioIaFalso()
        ..error = const ErrorIa(
          TipoErrorIa.claveInvalida,
          'La clave de la API no es válida.',
        );
      await abrirPerfil(tester, ia: ia);

      final boton = find.byKey(const Key('probar-ia'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('La clave de la API no es válida.'), findsOneWidget);
    });

    testWidgets('Quitar la clave deja la IA sin conectar', (tester) async {
      final almacen = AlmacenClaveMemoria('claude|sk-ant-api03-clave-vieja-1234');
      await abrirPerfil(tester, ia: ServicioIaFalso(), almacenClave: almacen);
      expect(find.textContaining('Conectada'), findsOneWidget);

      final boton = find.byKey(const Key('quitar-clave-ia'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('Sin conectar'), findsOneWidget);
      expect(await almacen.leer(), isNull);
    });
  });
}
