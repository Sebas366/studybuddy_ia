import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  /// Abre la app y entra a la pestaña Stats.
  Future<void> abrirStats(
    WidgetTester tester,
    RepositorioMemoria repositorio,
  ) async {
    await abrirApp(tester, repositorio);
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
  }

  /// Lunes de la semana actual a las 10:00 más [dias] días.
  DateTime diaDeEstaSemana(int dias) {
    final ahora = DateTime.now();
    final lunes = DateTime(
      ahora.year,
      ahora.month,
      ahora.day - (ahora.weekday - 1),
    );
    return DateTime(lunes.year, lunes.month, lunes.day + dias, 10);
  }

  testWidgets('Sin datos: tarjetas en cero y aviso para empezar', (
    WidgetTester tester,
  ) async {
    await abrirStats(tester, RepositorioMemoria());

    expect(find.text('Estadísticas y Rendimiento'), findsOneWidget);
    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('0 días'), findsOneWidget);
    expect(find.text('Total de 0 horas esta semana'), findsOneWidget);
    expect(find.textContaining('Pico:'), findsNothing);
    expect(
      find.text(
        'Completa un bloque de enfoque del Pomodoro para ver tus estadísticas.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Crea una materia para ver tu estudio por materia.'),
      findsOneWidget,
    );
  });

  testWidgets('Con sesiones de lunes y miércoles muestra total, pico y tiempo', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await repositorio.registrarSesionEnfoque(
      inicio: diaDeEstaSemana(0),
      duracionSegundos: 3600,
    );
    await repositorio.registrarSesionEnfoque(
      inicio: diaDeEstaSemana(2),
      duracionSegundos: 5400,
    );
    await abrirStats(tester, repositorio);

    expect(find.text('2 h 30 min'), findsOneWidget);
    expect(find.text('Total de 2.5 horas esta semana'), findsOneWidget);
    expect(find.text('Pico: Mié (1.5 h)'), findsOneWidget);
    expect(
      find.text(
        'Completa un bloque de enfoque del Pomodoro para ver tus estadísticas.',
      ),
      findsNothing,
    );
  });

  testWidgets(
    'Estudio por materia muestra tiempo y mejor quiz solo de materias reales',
    (WidgetTester tester) async {
      final repositorio = RepositorioMemoria();
      final id = await sembrarMateria(repositorio, 'Redes');
      await repositorio.registrarSesionEnfoque(
        materiaId: id,
        inicio: DateTime.now(),
        duracionSegundos: 5400,
      );
      // Una sesión de una materia de demostración cuenta en el total, sin tarjeta propia.
      await repositorio.registrarSesionEnfoque(
        materiaId: 'mat_1',
        inicio: DateTime.now(),
        duracionSegundos: 1500,
      );
      await repositorio.registrarIntentoQuiz(
        materiaId: id,
        aciertos: 3,
        total: 5,
      );
      await repositorio.registrarIntentoQuiz(
        materiaId: id,
        aciertos: 4,
        total: 5,
      );
      await abrirStats(tester, repositorio);

      await tester.scrollUntilVisible(find.text('Redes'), 200);
      expect(find.text('Redes'), findsOneWidget);
      expect(find.text('1 h 30 min'), findsOneWidget);
      expect(find.text('Mejor quiz: 4/5'), findsOneWidget);
      expect(find.text('1 h 55 min'), findsOneWidget); // total general
      expect(
        find.text('Crea una materia para ver tu estudio por materia.'),
        findsNothing,
      );
      expect(find.text('Arquitectura de Computadores'), findsNothing);
    },
  );

  testWidgets('Racha y quizzes se calculan con los datos guardados', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    final ahora = DateTime.now();
    await repositorio.registrarSesionEnfoque(
      inicio: ahora,
      duracionSegundos: 1500,
    );
    await repositorio.registrarSesionEnfoque(
      inicio: ahora.subtract(const Duration(days: 1)),
      duracionSegundos: 1500,
    );
    for (final aciertos in [1, 2, 3]) {
      await repositorio.registrarIntentoQuiz(
        materiaId: 'mat_1',
        aciertos: aciertos,
        total: 5,
      );
    }
    await abrirStats(tester, repositorio);

    expect(find.text('2 días'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Si falla la carga muestra el error y permite reintentar', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioInestable();
    await repositorio.registrarSesionEnfoque(
      inicio: DateTime.now(),
      duracionSegundos: 3600,
    );
    repositorio.fallarLectura = true;
    await abrirStats(tester, repositorio);

    expect(
      find.text('No se pudieron cargar tus estadísticas.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reintentar-estadisticas')), findsOneWidget);

    repositorio.fallarLectura = false;
    await tester.tap(find.byKey(const Key('reintentar-estadisticas')));
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar tus estadísticas.'), findsNothing);
    expect(find.text('1 h'), findsOneWidget);
  });
}
