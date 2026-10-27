import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/main.dart';

import 'repositorio_memoria.dart';

/// Monta [StudyBuddyApp] con el [repositorio] dado, simulando un smartphone.
///
/// Configura el viewport (800x1400, ratio 1.0) y espera a que termine la carga inicial.
Future<void> abrirApp(WidgetTester tester, RepositorioMemoria repositorio) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(StudyBuddyApp(repositorio: repositorio));
  await tester.pumpAndSettle();
}

/// Crea una materia real de prueba directamente en el [repositorio].
Future<String> sembrarMateria(
  RepositorioMemoria repositorio,
  String nombre, {
  int colorIndice = 0,
  String iconoClave = 'libro',
}) async {
  final materia = await repositorio.crearMateria(
    nombre: nombre,
    descripcion: '',
    colorIndice: colorIndice,
    iconoClave: iconoClave,
  );
  return materia.id;
}
