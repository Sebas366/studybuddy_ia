import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/main.dart';
import 'package:studybuddy_ia/theme/app_theme.dart';

void main() {
  /// Configura el tamaño del viewport para simular un smartphone moderno (1080x2400).
  void configurarPantalla(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Carga inicial y renderizado de MainShell en StudyBuddy IA',
      (WidgetTester tester) async {
    configurarPantalla(tester);

    await tester.pumpWidget(const StudyBuddyApp());
    await tester.pumpAndSettle();

    // Verificación de saludo personalizado y barra de navegación
    expect(find.text('¡Hola, Edwin! 👋'), findsOneWidget);
    expect(find.text('¿Qué vamos a repasar hoy?'), findsOneWidget);
    expect(find.text('¡Racha de 7 días activa! 🔥'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    // Verificación de materias de prueba visibles
    expect(find.text('Arquitectura de Computadores'), findsOneWidget);
    expect(find.text('Bootcamp IA y Datos'), findsOneWidget);
    expect(find.text('Desarrollo Móvil'), findsOneWidget);
  });

  testWidgets('Navegación entre pestañas del NavigationBar',
      (WidgetTester tester) async {
    configurarPantalla(tester);

    await tester.pumpWidget(const StudyBuddyApp());
    await tester.pumpAndSettle();

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

  testWidgets('Filtrado en vivo en la barra de búsqueda',
      (WidgetTester tester) async {
    configurarPantalla(tester);

    await tester.pumpWidget(const StudyBuddyApp());
    await tester.pumpAndSettle();

    final campoBusqueda = find.byType(TextField);
    expect(campoBusqueda, findsOneWidget);

    // Escribimos "MIPS"
    await tester.enterText(campoBusqueda, 'MIPS');
    await tester.pumpAndSettle();

    expect(find.text('Arquitectura de Computadores'), findsOneWidget);
    expect(find.text('Bootcamp IA y Datos'), findsNothing);
    expect(find.text('Desarrollo Móvil'), findsNothing);

    // Limpiamos el texto
    await tester.enterText(campoBusqueda, '');
    await tester.pumpAndSettle();

    expect(find.text('Arquitectura de Computadores'), findsOneWidget);
    expect(find.text('Bootcamp IA y Datos'), findsOneWidget);
    expect(find.text('Desarrollo Móvil'), findsOneWidget);
  });

  testWidgets('Navegación a Detalle de Materia y herramientas 2x2',
      (WidgetTester tester) async {
    configurarPantalla(tester);

    await tester.pumpWidget(const StudyBuddyApp());
    await tester.pumpAndSettle();

    // Tocamos en la primera materia
    await tester.tap(find.text('Arquitectura de Computadores'));
    await tester.pumpAndSettle();

    // Verificamos elementos de la pantalla de detalle
    expect(find.text('Herramientas de Estudio'), findsOneWidget);
    expect(find.text('Resumir'), findsOneWidget);
    expect(find.text('Quiz IA'), findsOneWidget);
    expect(find.text('Tutor IA'), findsOneWidget);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('Escanear'), findsOneWidget);

    // Probamos el SnackBar del botón Escanear
    await tester.tap(find.text('Escanear'));
    await tester.pump();
    expect(find.text('Función de escaneo de apuntes con IA próximamente...'),
        findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Flujo de Pomodoro funcional', (WidgetTester tester) async {
    configurarPantalla(tester);

    await tester.pumpWidget(const StudyBuddyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arquitectura de Computadores'));
    await tester.pumpAndSettle();

    // Abrir Pomodoro
    await tester.tap(find.text('Pomodoro'));
    await tester.pumpAndSettle();

    // Verificar tiempo inicial de 25:00 en modo Enfoque
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Enfoque'), findsOneWidget);
    expect(find.text('Descanso Corto'), findsOneWidget);
    expect(find.text('Descanso Largo'), findsOneWidget);

    // Cambiar a Descanso Corto (05:00)
    await tester.tap(find.text('Descanso Corto'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);

    // Volver a la pantalla anterior
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('Alternancia de Modo Oscuro desde Perfil',
      (WidgetTester tester) async {
    configurarPantalla(tester);

    await tester.pumpWidget(const StudyBuddyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    final switchModoOscuro = find.widgetWithText(SwitchListTile, 'Modo Oscuro');
    expect(switchModoOscuro, findsOneWidget);

    // Alternar interruptor
    await tester.tap(switchModoOscuro);
    await tester.pumpAndSettle();

    expect(modoTemaGlobal.value, isNotNull);
  });
}
