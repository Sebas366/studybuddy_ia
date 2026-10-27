import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/data/datos_demo.dart';
import 'package:studybuddy_ia/screens/detalle_materia_screen.dart';
import 'package:studybuddy_ia/utils/formato_fecha.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const avisoDisponible = 'Disponible en la Fase 3.';

  /// Abre la app con la materia real 'Redes' (y un apunte si se indica) y entra a su detalle.
  Future<void> entrarAlDetalle(
    WidgetTester tester, {
    String? tituloApunte,
    String contenidoApunte = 'texto',
  }) async {
    final repositorio = RepositorioMemoria();
    final id = await sembrarMateria(repositorio, 'Redes');
    if (tituloApunte != null) {
      await repositorio.crearApunte(
          materiaId: id, titulo: tituloApunte, contenido: contenidoApunte);
    }
    await abrirApp(tester, repositorio);
    await tester.tap(find.text('Redes'));
    await tester.pumpAndSettle();
  }

  testWidgets('Resumir, Quiz IA y Tutor IA muestran el aviso en una materia real',
      (WidgetTester tester) async {
    await entrarAlDetalle(tester);
    expect(find.text('Próximamente'), findsOneWidget);

    for (final herramienta in ['Resumir', 'Quiz IA', 'Tutor IA']) {
      await tester.tap(find.text(herramienta));
      await tester.pumpAndSettle();

      expect(find.text('Resumen, ideas clave y quiz con IA'), findsOneWidget,
          reason: herramienta);
      expect(find.text(avisoDisponible), findsOneWidget, reason: herramienta);
      // No se navegó a las pantallas simuladas.
      expect(find.text('Resumen Inteligente'), findsNothing);
      expect(find.textContaining('Quiz:'), findsNothing);
      expect(find.textContaining('Tutor IA:'), findsNothing);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text(avisoDisponible), findsNothing, reason: herramienta);
    }
  });

  testWidgets('Tocar un apunte real muestra su texto y el aviso',
      (WidgetTester tester) async {
    await entrarAlDetalle(tester,
        tituloApunte: 'DHCP', contenidoApunte: 'Discover, Offer, Request, Ack');

    await tester.tap(find.text('DHCP'));
    await tester.pumpAndSettle();

    expect(find.text('Apunte'), findsOneWidget);
    expect(find.text('DHCP'), findsOneWidget);
    expect(find.text(formatearFecha(DateTime.now())), findsOneWidget);
    expect(find.text('Discover, Offer, Request, Ack'), findsOneWidget);
    expect(find.text(avisoDisponible), findsOneWidget);
    expect(find.textContaining('Ideas Clave'), findsNothing);
    expect(find.text('Crear quiz'), findsNothing);
  });

  testWidgets('Un apunte con texto muy largo no desborda',
      (WidgetTester tester) async {
    await entrarAlDetalle(tester,
        tituloApunte: 'Apunte largo',
        contenidoApunte: 'línea de prueba ' * 320);

    await tester.tap(find.text('Apunte largo'));
    await tester.pumpAndSettle();

    expect(find.text('Apunte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El contenido del apunte no queda bajo la barra de navegación',
      (WidgetTester tester) async {
    await entrarAlDetalle(tester,
        tituloApunte: 'Apunte largo', contenidoApunte: 'línea de prueba ' * 320);
    await tester.tap(find.text('Apunte largo'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(400, 600);
    simularBarraDeNavegacion(tester, alto: 120);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();

    final inferior = tester.getBottomLeft(find.text('Copiar')).dy;
    expect(inferior, lessThanOrEqualTo(600 - 120));
  });

  testWidgets('Copiar pone título, materia y texto en el portapapeles',
      (WidgetTester tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
      if (llamada.method == 'Clipboard.setData') {
        copiado = (llamada.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await entrarAlDetalle(tester,
        tituloApunte: 'DHCP', contenidoApunte: 'Discover, Offer, Request, Ack');
    await tester.tap(find.text('DHCP'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();

    expect(copiado, contains('DHCP'));
    expect(copiado, contains('Redes'));
    expect(copiado, contains('Discover, Offer, Request, Ack'));
  });

  testWidgets(
      'En una materia de demostración Resumir sigue abriendo el resumen simulado',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      conProveedoresDePrueba(
        DetalleMateriaScreen(materia: DatosDemo.materias.first),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resumir'));
    await tester.pumpAndSettle();

    expect(find.text('Resumen Inteligente'), findsOneWidget);
    expect(find.text(avisoDisponible), findsNothing);
  });
}
