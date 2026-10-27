import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/theme/app_theme.dart';

import 'support/abrir_app.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const botonCrearPrimera = Key('crear-primera-materia');
  const campoNombre = Key('campo-nombre');
  const botonGuardarMateria = Key('guardar-materia');

  testWidgets('Inicio arranca vacío con botón para crear la primera materia',
      (WidgetTester tester) async {
    await abrirApp(tester, RepositorioMemoria());

    expect(find.text('¡Hola, Edwin! 👋'), findsOneWidget);
    expect(find.text('¿Qué vamos a repasar hoy?'), findsOneWidget);
    expect(find.text('Aún no tienes materias'), findsOneWidget);
    expect(find.byKey(botonCrearPrimera), findsOneWidget);

    // Sin datos de demostración mezclados como si fueran reales.
    expect(find.text('¡Racha de 7 días activa! 🔥'), findsNothing);
    expect(find.text('Arquitectura de Computadores'), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('Crear la primera materia desde el estado vacío',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await abrirApp(tester, repositorio);

    await tester.tap(find.byKey(botonCrearPrimera));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoNombre), 'Servicios Telemáticos');
    await tester.tap(find.byKey(const Key('color-1')));
    await tester.tap(find.byKey(const Key('icono-red')));
    await tester.tap(find.byKey(botonGuardarMateria));
    await tester.pumpAndSettle();

    expect(find.text('Servicios Telemáticos'), findsOneWidget);
    expect(find.text('Sin apuntes'), findsOneWidget);
    expect(find.text('Aún no tienes materias'), findsNothing);

    final guardadas = await repositorio.obtenerMaterias();
    expect(guardadas, hasLength(1));
    expect(guardadas.single.colorIndice, 1);
    expect(guardadas.single.iconoClave, 'red');
  });

  testWidgets('No guarda un nombre vacío o de solo espacios',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await abrirApp(tester, repositorio);

    await tester.tap(find.byKey(botonCrearPrimera));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoNombre), '   ');
    await tester.tap(find.byKey(botonGuardarMateria));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el nombre de la materia.'), findsOneWidget);
    expect(await repositorio.obtenerMaterias(), isEmpty);
  });

  testWidgets('Rechaza un nombre de 61 caracteres y acepta uno de 60',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await abrirApp(tester, repositorio);

    await tester.tap(find.byKey(botonCrearPrimera));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoNombre), 'A' * 61);
    await tester.tap(find.byKey(botonGuardarMateria));
    await tester.pumpAndSettle();
    expect(find.text('El nombre no puede pasar de 60 caracteres.'),
        findsOneWidget);
    expect(await repositorio.obtenerMaterias(), isEmpty);

    await tester.enterText(find.byKey(campoNombre), 'A' * 60);
    await tester.tap(find.byKey(botonGuardarMateria));
    await tester.pumpAndSettle();

    expect((await repositorio.obtenerMaterias()).single.nombre, 'A' * 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Doble toque en Guardar crea una sola materia',
      (WidgetTester tester) async {
    // El guardado queda en curso mientras se toca el botón por segunda vez.
    final repositorio = RepositorioLento();
    await abrirApp(tester, repositorio);

    await tester.tap(find.byKey(botonCrearPrimera));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(campoNombre), 'Redes');
    await tester.tap(find.byKey(botonGuardarMateria));
    await tester.pump();
    await tester.tap(find.byKey(botonGuardarMateria));
    await tester.pump();

    repositorio.compuerta.complete();
    await tester.pumpAndSettle();

    expect(await repositorio.obtenerMaterias(), hasLength(1));
  });

  testWidgets('Navegación entre pestañas del NavigationBar',
      (WidgetTester tester) async {
    await abrirApp(tester, RepositorioMemoria());

    // Pestaña Plan de Estudio
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Plan de Estudio'), findsOneWidget);
    expect(find.text('Próximo Parcial'), findsOneWidget);
    expect(find.text('Sesiones de Hoy'), findsOneWidget);

    // Pestaña Stats
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Estadísticas y Rendimiento'), findsOneWidget);
    expect(find.text('Horas de Estudio Semanal'), findsOneWidget);
    expect(find.text('Progreso por Materia'), findsOneWidget);

    // Pestaña Perfil
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi Perfil'), findsOneWidget);
    expect(find.text('Edwin'), findsOneWidget);
    expect(find.text('Modo Oscuro'), findsOneWidget);
    expect(find.text('Acerca de StudyBuddy IA'), findsOneWidget);

    // Volver a Inicio
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('¡Hola, Edwin! 👋'), findsOneWidget);
  });

  testWidgets('Buscador filtra materias reales', (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes de Computadores');
    await sembrarMateria(repositorio, 'Cálculo');
    await abrirApp(tester, repositorio);

    final campoBusqueda = find.byType(TextField);
    expect(campoBusqueda, findsOneWidget);

    await tester.enterText(campoBusqueda, 'redes');
    await tester.pumpAndSettle();
    expect(find.text('Redes de Computadores'), findsOneWidget);
    expect(find.text('Cálculo'), findsNothing);

    await tester.enterText(campoBusqueda, '');
    await tester.pumpAndSettle();
    expect(find.text('Redes de Computadores'), findsOneWidget);
    expect(find.text('Cálculo'), findsOneWidget);
  });

  testWidgets('Pomodoro se abre desde una materia real',
      (WidgetTester tester) async {
    final repositorio = RepositorioMemoria();
    await sembrarMateria(repositorio, 'Redes de Computadores');
    await abrirApp(tester, repositorio);

    await tester.tap(find.text('Redes de Computadores'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pomodoro'));
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Enfoque'), findsOneWidget);
    expect(find.text('Descanso Corto'), findsOneWidget);
    expect(find.text('Descanso Largo'), findsOneWidget);

    await tester.tap(find.text('Descanso Corto'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('Alternancia de Modo Oscuro desde Perfil',
      (WidgetTester tester) async {
    await abrirApp(tester, RepositorioMemoria());

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    final switchModoOscuro = find.widgetWithText(SwitchListTile, 'Modo Oscuro');
    expect(switchModoOscuro, findsOneWidget);

    await tester.tap(switchModoOscuro);
    await tester.pumpAndSettle();

    expect(modoTemaGlobal.value, isNotNull);
  });
}
