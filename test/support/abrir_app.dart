import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy_ia/data/materias_repository.dart';
import 'package:studybuddy_ia/main.dart';
import 'package:studybuddy_ia/providers/ajustes_provider.dart';
import 'package:studybuddy_ia/providers/estadisticas_provider.dart';
import 'package:studybuddy_ia/providers/ia_provider.dart';
import 'package:studybuddy_ia/providers/materias_provider.dart';
import 'package:studybuddy_ia/providers/plan_provider.dart';
import 'package:studybuddy_ia/providers/pomodoro_provider.dart';
import 'package:studybuddy_ia/services/almacen_clave.dart';
import 'package:studybuddy_ia/services/notificador_pomodoro.dart';
import 'package:studybuddy_ia/services/selector_imagen.dart';
import 'package:studybuddy_ia/services/servicio_ia.dart';
import 'package:studybuddy_ia/utils/reloj.dart';

import 'repositorio_memoria.dart';
import 'servicio_ia_falso.dart';

/// Monta [StudyBuddyApp] con el [repositorio] dado, simulando un smartphone.
///
/// Configura el viewport (800x1400, ratio 1.0) y espera a que termine la carga inicial.
/// Con [notificador] y [ahora] se pueden observar los avisos del Pomodoro y simular el reloj.
/// Con [ia] la app arranca con la clave de IA ya guardada y usa ese servicio falso;
/// sin él arranca con la IA sin conectar.
Future<void> abrirApp(
  WidgetTester tester,
  RepositorioMemoria repositorio, {
  NotificadorPomodoro? notificador,
  NotificadorRecordatorio? recordatorio,
  DateTime Function()? ahora,
  ServicioIa? ia,
  AlmacenClave? almacenClave,
  SelectorImagen? selectorImagen,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final servicio = ia ?? ServicioIaFalso();
  await tester.pumpWidget(
    StudyBuddyApp(
      repositorio: repositorio,
      notificador: notificador ?? const NotificadorNulo(),
      recordatorio: recordatorio ?? const RecordatorioNulo(),
      ahora: ahora ?? DateTime.now,
      almacenClave:
          almacenClave ?? AlmacenClaveMemoria(ia == null ? null : 'sk-prueba'),
      fabricaIa: (_, _) => servicio,
      selectorImagen: selectorImagen ?? SelectorImagenFalso(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Crea una materia real de prueba directamente en el [repositorio].
Future<String> sembrarMateria(
  RepositorioMemoria repositorio,
  String nombre, {
  int colorIndice = 0,
  String iconoClave = 'libro',
  String semestre = '2026-2',
}) async {
  final materia = await repositorio.crearMateria(
    nombre: nombre,
    descripcion: '',
    colorIndice: colorIndice,
    iconoClave: iconoClave,
    semestre: semestre,
  );
  return materia.id;
}

/// Simula la barra de navegación del sistema (Android) con [alto] píxeles abajo.
///
/// Restablece los valores originales al terminar la prueba.
void simularBarraDeNavegacion(WidgetTester tester, {double alto = 120}) {
  tester.view.padding = FakeViewPadding(bottom: alto);
  tester.view.viewPadding = FakeViewPadding(bottom: alto);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

/// Monta una pantalla suelta dentro de un `MaterialApp` con los mismos providers
/// que la app, sobre el [repositorio] dado, sin pasar por la navegación principal.
Widget conProveedoresDePrueba(
  Widget pantalla, {
  RepositorioMemoria? repositorio,
  ServicioIa? ia,
}) {
  final repo = repositorio ?? RepositorioMemoria();
  final servicio = ia ?? ServicioIaFalso();
  return MultiProvider(
    providers: [
      Provider<MateriasRepository>.value(value: repo),
      Provider<SelectorImagen>.value(value: SelectorImagenFalso()),
      Provider<Reloj>.value(value: DateTime.now),
      ChangeNotifierProvider(
        create: (_) => AjustesProvider(repositorio: repo)..cargar(),
      ),
      ChangeNotifierProvider(
        create: (_) => IaProvider(
          almacen: AlmacenClaveMemoria(ia == null ? null : 'sk-prueba'),
          fabrica: (_, _) => servicio,
        )..cargar(),
      ),
      ChangeNotifierProvider(create: (_) => MateriasProvider(repo)..cargar()),
      ChangeNotifierProvider(
        create: (_) => EstadisticasProvider(repo)..cargar(),
      ),
      ChangeNotifierProvider(create: (_) => PlanProvider(repo)..cargar()),
      ChangeNotifierProvider(
        create: (_) => PomodoroProvider(
          repositorio: repo,
          notificador: const NotificadorNulo(),
          registrarSesion:
              ({
                String? materiaId,
                required DateTime inicio,
                required int duracionSegundos,
              }) async => true,
        ),
      ),
    ],
    child: MaterialApp(home: pantalla),
  );
}
