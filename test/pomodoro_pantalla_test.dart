import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/abrir_app.dart';
import 'support/notificador_falso.dart';
import 'support/reloj_falso.dart';
import 'support/repositorio_memoria.dart';

void main() {
  const iniciar = Key('pomodoro-iniciar-pausar');
  const reiniciar = Key('pomodoro-reiniciar');
  const pastilla = Key('pastilla-pomodoro');

  late RepositorioMemoria repositorio;
  late RelojFalso reloj;
  late NotificadorFalso notificador;

  /// Abre la app con la materia 'Redes' (y 'Cálculo' si se pide) y un reloj simulado.
  Future<void> abrir(WidgetTester tester, {bool dosMaterias = false}) async {
    repositorio = RepositorioMemoria();
    reloj = RelojFalso(DateTime.now());
    notificador = NotificadorFalso();
    await sembrarMateria(repositorio, 'Redes');
    if (dosMaterias) await sembrarMateria(repositorio, 'Cálculo');
    await abrirApp(
      tester,
      repositorio,
      notificador: notificador,
      ahora: reloj.call,
    );
  }

  /// Desde Inicio entra a la materia y abre su Pomodoro.
  Future<void> abrirPomodoroDe(WidgetTester tester, String materia) async {
    await tester.tap(find.text(materia));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pomodoro'));
    await tester.pumpAndSettle();
  }

  /// Sale del Pomodoro y del detalle de la materia hasta llegar a Inicio.
  Future<void> salirHastaInicio(WidgetTester tester) async {
    await tester.pageBack(); // del Pomodoro al detalle
    await tester.pumpAndSettle();
    // El detalle tiene su propio botón de regreso (no el estándar).
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
  }

  /// Deja pasar tiempo en el reloj y dispara un tick del temporizador global.
  Future<void> pasar(WidgetTester tester, Duration duracion) async {
    reloj.avanzar(duracion);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets(
    'Muestra 00:15 en modo demostración y 25:00 al apagarlo en Perfil',
    (tester) async {
      await abrir(tester);
      await abrirPomodoroDe(tester, 'Redes');
      expect(find.text('00:15'), findsOneWidget);
      expect(find.text('Pomodoro: Redes'), findsOneWidget);

      await salirHastaInicio(tester);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byKey(const Key('modo-demo'))).value,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('modo-demo')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byKey(const Key('modo-demo'))).value,
        isFalse,
      );

      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      await abrirPomodoroDe(tester, 'Redes');
      expect(find.text('25:00'), findsOneWidget);
    },
  );

  testWidgets(
    'Salir de la pantalla y volver no reinicia el tiempo: sigue corriendo',
    (tester) async {
      await abrir(tester);
      await abrirPomodoroDe(tester, 'Redes');
      await tester.tap(find.byKey(iniciar));
      await tester.pump();
      await pasar(tester, const Duration(seconds: 5));
      expect(find.text('00:10'), findsOneWidget);

      await tester.pageBack(); // sale de la pantalla del Pomodoro
      await tester.pumpAndSettle();
      await pasar(
        tester,
        const Duration(seconds: 3),
      ); // el tiempo sigue corriendo afuera

      await tester.tap(find.text('Pomodoro'));
      await tester.pumpAndSettle();
      expect(find.text('00:07'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'Si el bloque termina estando en Inicio, se registra la sesión y Stats la refleja',
    (tester) async {
      await abrir(tester);
      await abrirPomodoroDe(tester, 'Redes');
      await tester.tap(find.byKey(iniciar));
      await tester.pump();
      await salirHastaInicio(tester);

      await pasar(tester, const Duration(seconds: 20));
      await tester.pumpAndSettle();

      final sesiones = await repositorio.obtenerSesionesEnfoque();
      expect(sesiones, hasLength(1));
      expect(sesiones.single.duracionSegundos, 15);
      expect(notificador.programadas, hasLength(1));
      expect(find.text('¡Racha de 1 día activa! 🔥'), findsOneWidget);

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('15 s'), findsWidgets);
    },
  );

  testWidgets(
    'La pastilla aparece mientras hay un bloque, muestra el tiempo y abre la pantalla',
    (tester) async {
      await abrir(tester);
      expect(find.byKey(pastilla), findsNothing);

      await abrirPomodoroDe(tester, 'Redes');
      await tester.tap(find.byKey(iniciar));
      await tester.pump();
      await pasar(tester, const Duration(seconds: 5));
      await salirHastaInicio(tester);

      expect(find.byKey(pastilla), findsOneWidget);
      expect(find.text('🍅 Pomodoro en curso · 00:10'), findsOneWidget);

      await tester.tap(find.byKey(pastilla));
      await tester.pumpAndSettle();
      expect(find.text('00:10'), findsOneWidget);

      await tester.tap(find.byKey(iniciar)); // pausa
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('🍅 Pomodoro en pausa · 00:10'), findsOneWidget);

      await tester.tap(find.byKey(pastilla));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(reiniciar));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(pastilla), findsNothing);
    },
  );

  testWidgets(
    'Abrir el Pomodoro de otra materia con un bloque activo no lo reemplaza',
    (tester) async {
      await abrir(tester, dosMaterias: true);
      await abrirPomodoroDe(tester, 'Redes');
      await tester.tap(find.byKey(iniciar));
      await tester.pump();
      await pasar(tester, const Duration(seconds: 5));
      await salirHastaInicio(tester);

      await abrirPomodoroDe(tester, 'Cálculo');

      expect(find.text('Pomodoro: Redes'), findsOneWidget);
      expect(find.text('00:10'), findsOneWidget);
      expect(
        find.text(
          'Ya hay un Pomodoro en curso de "Redes". Termínalo o reinícialo para cambiar de materia.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Sin bloque activo, abrir el Pomodoro de otra materia cambia la materia',
    (tester) async {
      await abrir(tester, dosMaterias: true);
      await abrirPomodoroDe(tester, 'Redes');
      expect(find.text('Pomodoro: Redes'), findsOneWidget);
      await salirHastaInicio(tester);

      await abrirPomodoroDe(tester, 'Cálculo');

      expect(find.text('Pomodoro: Cálculo'), findsOneWidget);
      expect(find.textContaining('Ya hay un Pomodoro en curso'), findsNothing);
    },
  );

  testWidgets('Al abrir la pantalla se piden los permisos una sola vez, no al iniciar',
      (tester) async {
    await abrir(tester);
    expect(notificador.permisosPedidos, 0);

    await abrirPomodoroDe(tester, 'Redes');
    expect(notificador.permisosPedidos, 1);

    await tester.tap(find.byKey(iniciar));
    await tester.pump();
    expect(notificador.permisosPedidos, 1);
  });

  testWidgets('La tarjeta del Pomodoro muestra la duración real del bloque',
      (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Redes'));
    await tester.pumpAndSettle();
    expect(find.text('Sesión de 15 s'), findsOneWidget);
    expect(find.text('Sesión de 25 min'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('modo-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redes'));
    await tester.pumpAndSettle();

    expect(find.text('Sesión de 25 min'), findsOneWidget);
  });
}
