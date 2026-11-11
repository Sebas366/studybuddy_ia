import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/models/resultados_ia.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';

import 'support/abrir_app.dart';
import 'support/reloj_falso.dart';
import 'support/repositorio_memoria.dart';
import 'support/servicio_ia_falso.dart';

void main() {
  late RepositorioMemoria repositorio;
  late ServicioIaFalso ia;
  late RelojFalso reloj;
  late String materiaId;

  setUp(() async {
    repositorio = RepositorioMemoria();
    ia = ServicioIaFalso();
    // Martes 10 de noviembre de 2026, 3:00 PM.
    reloj = RelojFalso(DateTime(2026, 11, 10, 15));
    materiaId = await sembrarMateria(repositorio, 'Redes');
  });

  Future<void> abrirPlan(WidgetTester tester, {bool conClave = true}) async {
    await abrirApp(
      tester,
      repositorio,
      ahora: reloj.call,
      ia: conClave ? ia : null,
    );
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
  }

  Future<void> sembrarEvaluacion(
    String titulo,
    DateTime fecha, {
    String temas = '',
  }) {
    return repositorio.crearEvaluacion(
      materiaId: materiaId,
      titulo: titulo,
      fecha: fecha,
      temas: temas,
    );
  }

  group('Evaluaciones', () {
    testWidgets('Sin evaluaciones invita a agregar la primera', (tester) async {
      await abrirPlan(tester);

      expect(find.text('Sin evaluaciones a la vista'), findsOneWidget);
      expect(find.text('Próxima evaluación'), findsNothing);
    });

    testWidgets('Crear una evaluación la muestra con su cuenta regresiva', (
      tester,
    ) async {
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('agregar-primera-evaluacion')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-titulo-evaluacion')),
        'Primer parcial',
      );
      await tester.enterText(
        find.byKey(const Key('campo-temas-evaluacion')),
        'DHCP y DNS',
      );
      await tester.tap(find.byKey(const Key('guardar-evaluacion')));
      await tester.pumpAndSettle();

      // El formulario propone la fecha para dentro de una semana.
      expect(find.text('Próxima evaluación'), findsOneWidget);
      expect(find.text('Primer parcial'), findsOneWidget);
      expect(find.text('En 7 días'), findsOneWidget);
      expect(find.text('Redes · Martes, 17 de noviembre'), findsOneWidget);
      expect(find.text('Temas: DHCP y DNS'), findsOneWidget);

      final guardada = (await repositorio.obtenerEvaluaciones()).single;
      expect(guardada.fecha, DateTime(2026, 11, 17));
      expect(guardada.materiaId, materiaId);
    });

    testWidgets('Una evaluación sin nombre no se guarda', (tester) async {
      await abrirPlan(tester);
      await tester.tap(find.byKey(const Key('agregar-primera-evaluacion')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guardar-evaluacion')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe el nombre de la evaluación.'), findsOneWidget);
      expect(await repositorio.obtenerEvaluaciones(), isEmpty);
    });

    testWidgets('La más cercana va en la tarjeta y las demás en la lista', (
      tester,
    ) async {
      await sembrarEvaluacion('Final', DateTime(2026, 12, 1));
      await sembrarEvaluacion('Parcial', DateTime(2026, 11, 11));
      await sembrarEvaluacion('Ya pasó', DateTime(2026, 11, 9));
      await abrirPlan(tester);

      expect(find.text('Mañana'), findsOneWidget);
      expect(find.text('Otras evaluaciones'), findsOneWidget);
      expect(find.text('Final'), findsOneWidget);
      expect(find.text('En 21 días'), findsOneWidget);
      // Las evaluaciones que ya pasaron no se muestran.
      expect(find.text('Ya pasó'), findsNothing);

      // La tarjeta destacada es la del parcial, no la del final.
      final tarjeta = find.byKey(const Key('tarjeta-proxima-evaluacion'));
      expect(
        find.descendant(of: tarjeta, matching: find.text('Parcial')),
        findsOneWidget,
      );
    });

    testWidgets('Una evaluación de hoy dice "Hoy"', (tester) async {
      await sembrarEvaluacion('Quiz', DateTime(2026, 11, 10));
      await abrirPlan(tester);

      expect(find.text('Hoy'), findsOneWidget);
    });

    testWidgets('Se puede editar y borrar desde sus opciones', (tester) async {
      await sembrarEvaluacion('Parcial', DateTime(2026, 11, 20));
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('opciones-proxima-evaluacion')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-editar-plan')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-titulo-evaluacion')),
        'Parcial corregido',
      );
      await tester.tap(find.byKey(const Key('guardar-evaluacion')));
      await tester.pumpAndSettle();
      expect(find.text('Parcial corregido'), findsOneWidget);
      // Editar conserva la fecha que ya tenía.
      expect(
        (await repositorio.obtenerEvaluaciones()).single.fecha,
        DateTime(2026, 11, 20),
      );

      await tester.tap(find.byKey(const Key('opciones-proxima-evaluacion')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-borrar-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('Sin evaluaciones a la vista'), findsOneWidget);
      expect(await repositorio.obtenerEvaluaciones(), isEmpty);
    });

    testWidgets('"Estudiar ahora" abre la materia de la evaluación', (
      tester,
    ) async {
      await sembrarEvaluacion('Parcial', DateTime(2026, 11, 20));
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('estudiar-evaluacion')));
      await tester.pumpAndSettle();

      expect(find.text('Herramientas de Estudio'), findsOneWidget);
    });

    testWidgets('Sin materias no deja crear una evaluación', (tester) async {
      await repositorio.borrarMateria(materiaId);
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('agregar-primera-evaluacion')));
      await tester.pump();

      expect(
        find.text('Crea una materia en Inicio para agregarle una evaluación.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('guardar-evaluacion')), findsNothing);
    });

    testWidgets('Al borrar la materia desaparece su evaluación', (tester) async {
      await sembrarEvaluacion('Parcial', DateTime(2026, 11, 20));
      await abrirPlan(tester);
      expect(find.text('Parcial'), findsOneWidget);

      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Redes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-borrar-materia')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Parcial'), findsNothing);
      expect(find.text('Sin evaluaciones a la vista'), findsOneWidget);
    });
  });

  group('Sesiones', () {
    testWidgets('Sin sesiones para hoy lo dice y ofrece agregar una', (
      tester,
    ) async {
      await abrirPlan(tester);

      expect(find.text('Sesiones de Hoy'), findsOneWidget);
      expect(find.text('Martes, 10 de noviembre'), findsOneWidget);
      expect(
        find.text('No tienes sesiones planeadas para hoy.'),
        findsOneWidget,
      );
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('Crear una sesión la deja en las de hoy, a la próxima hora', (
      tester,
    ) async {
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('agregar-sesion-hoy')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-tema-sesion')),
        'Repaso de DHCP',
      );
      await tester.tap(find.byKey(const Key('guardar-sesion')));
      await tester.pumpAndSettle();

      expect(find.text('Repaso de DHCP'), findsOneWidget);
      expect(find.text('Estudio libre'), findsOneWidget);
      expect(find.text('4:00 PM - 5:00 PM'), findsOneWidget);
      expect(find.text('0 de 1 completadas'), findsOneWidget);

      final guardada = (await repositorio.obtenerSesionesPlan()).single;
      expect(guardada.inicio, DateTime(2026, 11, 10, 16));
      expect(guardada.duracionMinutos, 60);
    });

    testWidgets('Una sesión sin tema no se guarda', (tester) async {
      await abrirPlan(tester);
      await tester.tap(find.byKey(const Key('agregar-sesion-hoy')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guardar-sesion')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe qué vas a estudiar.'), findsOneWidget);
      expect(await repositorio.obtenerSesionesPlan(), isEmpty);
    });

    testWidgets('Marcar una sesión actualiza el avance y queda guardado', (
      tester,
    ) async {
      await repositorio.crearSesionPlan(
        materiaId: materiaId,
        tema: 'Primera',
        inicio: DateTime(2026, 11, 10, 8),
        duracionMinutos: 30,
      );
      await repositorio.crearSesionPlan(
        tema: 'Segunda',
        inicio: DateTime(2026, 11, 10, 18),
        duracionMinutos: 30,
      );
      await abrirPlan(tester);
      expect(find.text('0 de 2 completadas'), findsOneWidget);

      await tester.tap(find.text('Primera'));
      await tester.pumpAndSettle();

      expect(find.text('1 de 2 completadas'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      final sesiones = await repositorio.obtenerSesionesPlan();
      expect(sesiones.first.completada, isTrue);
      expect(sesiones.last.completada, isFalse);
    });

    testWidgets('Separa las sesiones de hoy, las atrasadas y las próximas', (
      tester,
    ) async {
      await repositorio.crearSesionPlan(
        tema: 'De ayer sin hacer',
        inicio: DateTime(2026, 11, 9, 8),
        duracionMinutos: 30,
      );
      final hecha = await repositorio.crearSesionPlan(
        tema: 'De ayer ya hecha',
        inicio: DateTime(2026, 11, 9, 10),
        duracionMinutos: 30,
      );
      await repositorio.marcarSesionPlan(hecha.id, completada: true);
      await repositorio.crearSesionPlan(
        tema: 'De hoy',
        inicio: DateTime(2026, 11, 10, 18),
        duracionMinutos: 30,
      );
      await repositorio.crearSesionPlan(
        tema: 'De mañana',
        inicio: DateTime(2026, 11, 11, 9),
        duracionMinutos: 45,
      );
      await abrirPlan(tester);

      expect(find.text('0 de 1 completadas'), findsOneWidget);
      expect(find.text('Atrasadas'), findsOneWidget);
      expect(find.text('De ayer sin hacer'), findsOneWidget);
      expect(find.text('De ayer ya hecha'), findsNothing);
      expect(find.text('Próximas sesiones'), findsOneWidget);
      expect(
        find.text('Miércoles, 11 de noviembre · 9:00 AM - 9:45 AM'),
        findsOneWidget,
      );
    });

    testWidgets('Se puede editar y borrar manteniéndola pulsada', (tester) async {
      await repositorio.crearSesionPlan(
        tema: 'Repaso',
        inicio: DateTime(2026, 11, 10, 18),
        duracionMinutos: 30,
      );
      await abrirPlan(tester);

      await tester.longPress(find.text('Repaso'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-editar-plan')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-tema-sesion')),
        'Repaso general',
      );
      await tester.tap(find.byKey(const Key('guardar-sesion')));
      await tester.pumpAndSettle();
      expect(find.text('Repaso general'), findsOneWidget);
      // Editar conserva la hora y la duración que ya tenía.
      final editada = (await repositorio.obtenerSesionesPlan()).single;
      expect(editada.inicio, DateTime(2026, 11, 10, 18));
      expect(editada.duracionMinutos, 30);

      await tester.longPress(find.text('Repaso general'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-borrar-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      expect(await repositorio.obtenerSesionesPlan(), isEmpty);
    });

    testWidgets('Las sesiones siguen ahí al reabrir la app', (tester) async {
      await abrirPlan(tester);
      await tester.tap(find.byKey(const Key('agregar-sesion-hoy')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo-tema-sesion')),
        'Repaso de DHCP',
      );
      await tester.tap(find.byKey(const Key('guardar-sesion')));
      await tester.pumpAndSettle();

      // Se desmonta la app y se abre otra vez sobre el mismo repositorio.
      await tester.pumpWidget(const SizedBox());
      await abrirPlan(tester);

      expect(find.text('Repaso de DHCP'), findsOneWidget);
    });
  });

  group('Plan con IA', () {
    setUp(() async {
      await sembrarEvaluacion(
        'Parcial',
        DateTime(2026, 11, 13),
        temas: 'DHCP',
      );
    });

    testWidgets('Muestra las sesiones sugeridas y las agrega al aceptar', (
      tester,
    ) async {
      ia.plan = [
        SesionSugerida(
          inicio: DateTime(2026, 11, 10, 18),
          duracionMinutos: 45,
          tema: 'Repasar DORA',
        ),
        SesionSugerida(
          inicio: DateTime(2026, 11, 12, 17),
          duracionMinutos: 60,
          tema: 'Repaso general',
        ),
      ];
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('plan-con-ia')));
      await tester.pumpAndSettle();

      expect(find.text('Plan sugerido por la IA'), findsOneWidget);
      expect(find.text('Repasar DORA'), findsOneWidget);
      expect(
        find.text('Jueves, 12 de noviembre · 5:00 PM · 60 min'),
        findsOneWidget,
      );
      expect(await repositorio.obtenerSesionesPlan(), isEmpty);

      await tester.tap(find.byKey(const Key('aceptar-plan-ia')));
      await tester.pumpAndSettle();

      final sesiones = await repositorio.obtenerSesionesPlan();
      expect(sesiones.map((s) => s.tema), ['Repasar DORA', 'Repaso general']);
      expect(sesiones.every((s) => s.materiaId == materiaId), isTrue);
      expect(find.text('0 de 1 completadas'), findsOneWidget);
      expect(find.text('Próximas sesiones'), findsOneWidget);
    });

    testWidgets('Descartar el plan no agrega nada', (tester) async {
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('plan-con-ia')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(await repositorio.obtenerSesionesPlan(), isEmpty);
    });

    testWidgets('Si la IA falla avisa y no agrega nada', (tester) async {
      ia.error = const ErrorIa(TipoErrorIa.sinConexion, 'No hay conexión.');
      await abrirPlan(tester);

      await tester.tap(find.byKey(const Key('plan-con-ia')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No hay conexión.'), findsOneWidget);
      expect(find.text('Armando tu plan con IA...'), findsNothing);
      expect(await repositorio.obtenerSesionesPlan(), isEmpty);
    });

    testWidgets('Sin clave pide conectarla antes de pedir el plan', (
      tester,
    ) async {
      await abrirPlan(tester, conClave: false);

      await tester.tap(find.byKey(const Key('plan-con-ia')));
      await tester.pumpAndSettle();

      expect(find.text('Conectar la IA'), findsOneWidget);
      expect(ia.llamadas, isEmpty);
    });
  });
}
