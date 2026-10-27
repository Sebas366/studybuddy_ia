import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy_ia/providers/estadisticas_provider.dart';
import 'package:studybuddy_ia/screens/main_shell.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  testWidgets(
    'Borrar una materia borra sus sesiones e intentos y el provider se recalcula',
    (WidgetTester tester) async {
      final repositorio = RepositorioMemoria();
      final id = await sembrarMateria(repositorio, 'Redes');
      await repositorio.registrarSesionEnfoque(
        materiaId: id,
        inicio: DateTime(2026, 10, 27, 9),
        duracionSegundos: 1500,
      );
      await repositorio.registrarIntentoQuiz(
        materiaId: id,
        aciertos: 4,
        total: 5,
      );
      await abrirApp(tester, repositorio);

      final estadisticas = Provider.of<EstadisticasProvider>(
        tester.element(find.byType(MainShell)),
        listen: false,
      );
      expect(estadisticas.sesiones, hasLength(1));
      expect(estadisticas.intentos, hasLength(1));

      await tester.longPress(find.text('Redes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-borrar-materia')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(await repositorio.obtenerSesionesEnfoque(), isEmpty);
      expect(await repositorio.obtenerIntentosQuiz(), isEmpty);
      expect(estadisticas.sesiones, isEmpty);
      expect(estadisticas.intentos, isEmpty);
    },
  );
}
