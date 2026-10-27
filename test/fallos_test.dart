import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/screens/error_base_datos_screen.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  testWidgets('Inicio muestra el error y permite reintentar la carga',
      (WidgetTester tester) async {
    final repositorio = RepositorioInestable()..fallarLectura = true;
    await sembrarMateria(repositorio, 'Redes');
    await abrirApp(tester, repositorio);

    expect(find.text('No se pudieron cargar tus materias.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('reintentar-carga')), findsOneWidget);

    repositorio.fallarLectura = false;
    await tester.tap(find.byKey(const Key('reintentar-carga')));
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar tus materias.'), findsNothing);
    expect(find.text('Redes'), findsOneWidget);
  });

  testWidgets('La pantalla de error de la base de datos ofrece reintentar',
      (WidgetTester tester) async {
    var reintentos = 0;
    await tester.pumpWidget(
      ErrorBaseDatosApp(onReintentar: () => reintentos++),
    );

    expect(find.text('No se pudo abrir tu base de datos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reintentar-base-datos')));
    await tester.pump();

    expect(reintentos, 1);
  });
}
