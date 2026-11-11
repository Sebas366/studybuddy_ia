import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/services/selector_imagen.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';
import 'support/servicio_ia_falso.dart';

void main() {
  late RepositorioMemoria repositorio;
  late ServicioIaFalso ia;
  late String materiaId;

  setUp(() {
    repositorio = RepositorioMemoria();
    ia = ServicioIaFalso();
  });

  /// Abre la app con la materia 'Redes' (con los apuntes indicados) y entra a su detalle.
  ///
  /// Con [conClave] en `false` la app arranca con la IA sin conectar.
  Future<void> entrarAlDetalle(
    WidgetTester tester, {
    List<String> apuntes = const ['DHCP'],
    bool conClave = true,
    SelectorImagen? selectorImagen,
  }) async {
    materiaId = await sembrarMateria(repositorio, 'Redes');
    // Se siembran al revés para que el primero de la lista quede arriba.
    for (final titulo in apuntes.reversed) {
      await repositorio.crearApunte(
        materiaId: materiaId,
        titulo: titulo,
        contenido: 'Texto de $titulo',
      );
    }
    await abrirApp(
      tester,
      repositorio,
      ia: conClave ? ia : null,
      selectorImagen: selectorImagen,
    );
    await tester.tap(find.text('Redes'));
    await tester.pumpAndSettle();
  }

  group('Resumen con IA', () {
    testWidgets('Resumir genera el resumen, lo muestra y lo guarda', (
      tester,
    ) async {
      await entrarAlDetalle(tester);

      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();

      expect(find.text('Resumen Inteligente'), findsOneWidget);
      expect(find.text('Resumen medio de prueba.'), findsOneWidget);
      expect(find.text('Ideas Clave (2)'), findsOneWidget);
      expect(find.text('Primera idea clave.'), findsOneWidget);

      await tester.tap(find.text('Corto'));
      await tester.pumpAndSettle();
      expect(find.text('Resumen corto de prueba.'), findsOneWidget);

      final apunte = (await repositorio.obtenerMaterias()).single.apuntes.single;
      expect(apunte.resumenDetallado, 'Resumen detallado de prueba.');
    });

    testWidgets('Un resumen ya guardado se abre sin volver a llamar a la IA', (
      tester,
    ) async {
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.textContaining('Resumen listo'), findsOneWidget);

      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();

      expect(find.text('Resumen medio de prueba.'), findsOneWidget);
      expect(ia.llamadas.where((l) => l == 'resumir'), hasLength(1));
    });

    testWidgets('Mientras la IA trabaja se ve el indicador de espera', (
      tester,
    ) async {
      ia.compuerta = Completer<void>();
      await entrarAlDetalle(tester);

      await tester.tap(find.text('Resumir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Resumiendo tu apunte...'), findsOneWidget);
      expect(find.text('Resumen medio de prueba.'), findsNothing);

      ia.compuerta!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Resumen medio de prueba.'), findsOneWidget);
    });

    testWidgets('Si la IA falla se ve el motivo y se puede reintentar', (
      tester,
    ) async {
      ia.error = const ErrorIa(TipoErrorIa.sinConexion, 'No hay conexión.');
      await entrarAlDetalle(tester);

      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();

      expect(find.text('No hay conexión.'), findsOneWidget);
      expect(find.text('Resumen medio de prueba.'), findsNothing);

      ia.error = null;
      await tester.tap(find.byKey(const Key('reintentar-ia')));
      await tester.pumpAndSettle();

      expect(find.text('Resumen medio de prueba.'), findsOneWidget);
    });

    testWidgets('Sin clave pide conectarla y luego genera el resumen', (
      tester,
    ) async {
      await entrarAlDetalle(tester, conClave: false);

      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();
      expect(find.text('Conectar la IA'), findsOneWidget);
      expect(ia.llamadas, isEmpty);

      await tester.enterText(
        find.byKey(const Key('campo-clave-ia')),
        'sk-ant-clave-de-prueba',
      );
      await tester.tap(find.byKey(const Key('guardar-clave-ia')));
      await tester.pumpAndSettle();

      expect(find.text('Resumen medio de prueba.'), findsOneWidget);
    });

    testWidgets('Si se cancela la clave, explica qué falta', (tester) async {
      await entrarAlDetalle(tester, conClave: false);

      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Conecta la IA con tu clave para usar esta función.'),
        findsOneWidget,
      );
      expect(ia.llamadas, isEmpty);
    });

    testWidgets('Con varios apuntes deja elegir cuál resumir', (tester) async {
      await entrarAlDetalle(tester, apuntes: ['DHCP', 'DNS']);

      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();
      expect(find.text('¿Qué apunte quieres resumir?'), findsOneWidget);

      await tester.tap(find.text('DNS').last);
      await tester.pumpAndSettle();

      expect(find.text('Resumen Inteligente'), findsOneWidget);
      expect(find.text('DNS'), findsOneWidget);
    });

    testWidgets('Sin apuntes avisa que hace falta uno', (tester) async {
      await entrarAlDetalle(tester, apuntes: []);

      await tester.tap(find.text('Resumir'));
      await tester.pump();

      expect(find.text('Agrega un apunte para poder resumirlo.'), findsOneWidget);
      expect(find.text('Resumen Inteligente'), findsNothing);
    });

    testWidgets('Desde el apunte se llega al resumen', (tester) async {
      await entrarAlDetalle(tester);

      await tester.tap(find.text('DHCP'));
      await tester.pumpAndSettle();
      expect(find.text('Texto de DHCP'), findsOneWidget);
      expect(find.text('Resumir con IA'), findsOneWidget);

      await tester.tap(find.byKey(const Key('resumir-apunte')));
      await tester.pumpAndSettle();
      expect(find.text('Resumen medio de prueba.'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Ver resumen con IA'), findsOneWidget);
    });

    testWidgets('Editar el texto del apunte descarta el resumen', (tester) async {
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Resumir'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.longPress(find.text('DHCP'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-editar-apunte')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-texto-apunte')),
        'Texto corregido',
      );
      await tester.tap(find.byKey(const Key('guardar-apunte')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Resumen listo'), findsNothing);
    });
  });

  group('Quiz con IA', () {
    testWidgets('Genera el quiz, se responde y guarda el intento', (
      tester,
    ) async {
      await entrarAlDetalle(tester);
      expect(find.text('Generar con IA'), findsOneWidget);

      await tester.tap(find.text('Quiz IA'));
      await tester.pumpAndSettle();
      expect(find.text('Tu quiz está listo'), findsOneWidget);
      expect(ia.ultimosApuntes.single.titulo, 'DHCP');

      await tester.tap(find.byKey(const Key('empezar-quiz')));
      await tester.pumpAndSettle();

      // Primera pregunta bien, segunda mal.
      expect(find.text('Pregunta uno'), findsOneWidget);
      await tester.tap(find.text('Correcta 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comprobar respuesta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Explicación uno.'), findsOneWidget);
      await tester.tap(find.text('Siguiente pregunta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mala 2a'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comprobar respuesta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver resultados'));
      await tester.pumpAndSettle();

      final intento = (await repositorio.obtenerIntentosQuiz()).single;
      expect(intento.aciertos, 1);
      expect(intento.total, 2);
      expect(intento.materiaId, materiaId);

      await tester.tap(find.text('Volver a la materia'));
      await tester.pumpAndSettle();
      expect(find.text('2 preguntas'), findsOneWidget);
      expect(find.text('50% dominado'), findsOneWidget);
    });

    testWidgets('Un quiz guardado se puede empezar sin llamar a la IA', (
      tester,
    ) async {
      materiaId = await sembrarMateria(repositorio, 'Redes');
      await repositorio.reemplazarPreguntas(materiaId, ServicioIaFalso.quiz);
      await abrirApp(tester, repositorio, ia: ia);
      await tester.tap(find.text('Redes'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quiz IA'));
      await tester.pumpAndSettle();

      expect(find.text('Tu quiz está listo'), findsOneWidget);
      expect(ia.llamadas, isEmpty);
    });

    testWidgets('"Generar preguntas nuevas" vuelve a pedir el quiz', (
      tester,
    ) async {
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Quiz IA'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('generar-quiz-nuevo')));
      await tester.pumpAndSettle();

      expect(ia.llamadas.where((l) => l == 'quiz'), hasLength(2));
      expect(find.text('Tu quiz está listo'), findsOneWidget);
    });

    testWidgets('Sin apuntes avisa que hace falta uno', (tester) async {
      await entrarAlDetalle(tester, apuntes: []);

      await tester.tap(find.text('Quiz IA'));
      await tester.pump();

      expect(
        find.text('Agrega un apunte para que la IA pueda crear el quiz.'),
        findsOneWidget,
      );
      expect(ia.llamadas, isEmpty);
    });

    testWidgets('Si la IA falla se ve el motivo y se puede reintentar', (
      tester,
    ) async {
      ia.error = const ErrorIa(TipoErrorIa.limite, 'Espera un momento.');
      await entrarAlDetalle(tester);

      await tester.tap(find.text('Quiz IA'));
      await tester.pumpAndSettle();
      expect(find.text('Espera un momento.'), findsOneWidget);

      ia.error = null;
      await tester.tap(find.byKey(const Key('reintentar-ia')));
      await tester.pumpAndSettle();
      expect(find.text('Tu quiz está listo'), findsOneWidget);
    });
  });

  group('Tutor IA', () {
    Future<void> preguntar(WidgetTester tester, String texto) async {
      await tester.enterText(find.byType(TextField), texto);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    testWidgets('Responde con la IA y guarda la conversación', (tester) async {
      await entrarAlDetalle(tester);

      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Soy tu Tutor IA para Redes'), findsOneWidget);
      expect(find.textContaining('Ya leí tus apuntes'), findsOneWidget);

      await preguntar(tester, '¿Qué es el pipeline?');

      expect(find.text('¿Qué es el pipeline?'), findsOneWidget);
      // Las partes del streaming se juntan en una sola burbuja.
      expect(find.text('El pipeline tiene cinco etapas.'), findsOneWidget);
      expect(ia.ultimosApuntes.single.titulo, 'DHCP');
      expect(ia.ultimoHistorial.single.texto, '¿Qué es el pipeline?');

      final guardados = await repositorio.obtenerMensajesChat(materiaId);
      expect(guardados.map((m) => m.esUsuario), [true, false]);
      expect(guardados.last.texto, 'El pipeline tiene cinco etapas.');
    });

    testWidgets('La segunda pregunta lleva el historial completo', (
      tester,
    ) async {
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();

      await preguntar(tester, 'Primera');
      await preguntar(tester, 'Segunda');

      expect(ia.ultimoHistorial.map((m) => m.texto), [
        'Primera',
        'El pipeline tiene cinco etapas.',
        'Segunda',
      ]);
    });

    testWidgets('La conversación sigue ahí al volver a entrar', (tester) async {
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();
      await preguntar(tester, '¿Qué es el pipeline?');
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué es el pipeline?'), findsOneWidget);
      expect(find.text('El pipeline tiene cinco etapas.'), findsOneWidget);
    });

    testWidgets('Una sugerencia se envía como pregunta', (tester) async {
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('¿Me explicas el concepto principal?'));
      await tester.pumpAndSettle();

      expect(ia.ultimoHistorial.single.texto, '¿Me explicas el concepto principal?');
      expect(find.text('El pipeline tiene cinco etapas.'), findsOneWidget);
    });

    testWidgets('"Nueva conversación" borra los mensajes', (tester) async {
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();
      await preguntar(tester, '¿Qué es el pipeline?');

      await tester.tap(find.byKey(const Key('nueva-conversacion')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué es el pipeline?'), findsNothing);
      expect(await repositorio.obtenerMensajesChat(materiaId), isEmpty);
    });

    testWidgets('Si el tutor falla se puede reintentar sin repetir la pregunta', (
      tester,
    ) async {
      ia.error = const ErrorIa(TipoErrorIa.servicio, 'Servicio saturado.');
      await entrarAlDetalle(tester);
      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();

      await preguntar(tester, '¿Qué es el pipeline?');
      expect(find.text('Servicio saturado.'), findsOneWidget);
      expect(find.text('El pipeline tiene cinco etapas.'), findsNothing);

      ia.error = null;
      await tester.tap(find.byKey(const Key('reintentar-tutor')));
      await tester.pumpAndSettle();

      expect(find.text('Servicio saturado.'), findsNothing);
      expect(find.text('El pipeline tiene cinco etapas.'), findsOneWidget);
      final guardados = await repositorio.obtenerMensajesChat(materiaId);
      expect(guardados.where((m) => m.esUsuario), hasLength(1));
    });

    testWidgets('Sin clave pide conectarla antes de abrir el chat', (
      tester,
    ) async {
      await entrarAlDetalle(tester, conClave: false);

      await tester.tap(find.text('Tutor IA'));
      await tester.pumpAndSettle();
      expect(find.text('Conectar la IA'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tutor IA:'), findsNothing);
    });
  });

  group('Escanear un apunte', () {
    testWidgets('La foto se transcribe y queda como apunte tras revisarla', (
      tester,
    ) async {
      final selector = SelectorImagenFalso();
      await entrarAlDetalle(tester, apuntes: [], selectorImagen: selector);

      await tester.tap(find.byKey(const Key('escanear-apunte')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escanear-camara')));
      await tester.pumpAndSettle();

      expect(selector.pedidos, [OrigenImagen.camara]);
      expect(find.text('Revisar apunte escaneado'), findsOneWidget);
      expect(find.text('Título escaneado'), findsOneWidget);
      expect(find.text('Texto leído de la foto.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('guardar-apunte')));
      await tester.pumpAndSettle();

      final apunte = (await repositorio.obtenerMaterias()).single.apuntes.single;
      expect(apunte.titulo, 'Título escaneado');
      expect(apunte.contenido, 'Texto leído de la foto.');
      expect(find.text('Título escaneado'), findsOneWidget);
    });

    testWidgets('Se puede elegir la foto de la galería', (tester) async {
      final selector = SelectorImagenFalso();
      await entrarAlDetalle(tester, selectorImagen: selector);

      await tester.tap(find.byKey(const Key('escanear-apunte')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escanear-galeria')));
      await tester.pumpAndSettle();

      expect(selector.pedidos, [OrigenImagen.galeria]);
      expect(find.text('Revisar apunte escaneado'), findsOneWidget);
    });

    testWidgets('Si se cancela la foto no pasa nada', (tester) async {
      final selector = SelectorImagenFalso()..cancelar = true;
      await entrarAlDetalle(tester, selectorImagen: selector);

      await tester.tap(find.byKey(const Key('escanear-apunte')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escanear-camara')));
      await tester.pumpAndSettle();

      expect(ia.llamadas, isEmpty);
      expect(find.text('Revisar apunte escaneado'), findsNothing);
      expect(find.text('Herramientas de Estudio'), findsOneWidget);
    });

    testWidgets('Si la IA no puede leer la foto, avisa y vuelve a la materia', (
      tester,
    ) async {
      ia.error = const ErrorIa(
        TipoErrorIa.respuestaInvalida,
        'No se encontró texto legible en la imagen.',
      );
      await entrarAlDetalle(tester);

      await tester.tap(find.byKey(const Key('escanear-apunte')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escanear-camara')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('No se encontró texto legible en la imagen.'),
        findsOneWidget,
      );
      expect(find.text('Leyendo tu apunte con IA...'), findsNothing);
      expect(find.text('Revisar apunte escaneado'), findsNothing);
    });
  });

  testWidgets('La materia de ejemplo se carga desde Inicio con sus apuntes', (
    tester,
  ) async {
    await abrirApp(tester, repositorio, ia: ia);

    await tester.tap(find.byKey(const Key('cargar-materia-ejemplo')));
    await tester.pumpAndSettle();

    expect(find.text('Arquitectura de Computadores'), findsOneWidget);
    final materia = (await repositorio.obtenerMaterias()).single;
    expect(materia.apuntes, hasLength(2));
    expect(
      materia.apuntes.first.titulo,
      'Segmentación de instrucciones (pipeline MIPS)',
    );
  });
}
