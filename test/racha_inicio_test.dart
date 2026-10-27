import 'package:flutter_test/flutter_test.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  /// Registra una sesión de enfoque hace [dias] días (0 = hoy).
  Future<void> sesionHaceDias(RepositorioMemoria repositorio, int dias) {
    return repositorio.registrarSesionEnfoque(
      inicio: DateTime.now().subtract(Duration(days: dias)),
      duracionSegundos: 1500,
    );
  }

  testWidgets('Sin sesiones no se muestra la tarjeta de racha', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, RepositorioMemoria());

    expect(find.textContaining('¡Racha de'), findsNothing);
  });

  testWidgets('Con una sesión hoy muestra la racha de 1 día en singular', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await sesionHaceDias(repositorio, 0);
    await abrirApp(tester, repositorio);

    expect(find.text('¡Racha de 1 día activa! 🔥'), findsOneWidget);
  });

  testWidgets('Con sesiones hoy y ayer muestra la racha de 2 días', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes');
    await sesionHaceDias(repositorio, 0);
    await sesionHaceDias(repositorio, 1);
    await abrirApp(tester, repositorio);

    expect(find.text('¡Racha de 2 días activa! 🔥'), findsOneWidget);
    // Convive con la lista de materias.
    expect(find.text('Redes'), findsOneWidget);
  });

  testWidgets('Una sesión de hace 3 días no cuenta como racha', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioMemoria();
    await sesionHaceDias(repositorio, 3);
    await abrirApp(tester, repositorio);

    expect(find.textContaining('¡Racha de'), findsNothing);
  });
}
