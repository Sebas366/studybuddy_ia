import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/models/intento_quiz.dart';
import 'package:studybuddy_ia/models/sesion_enfoque.dart';
import 'package:studybuddy_ia/utils/calculos_estadisticas.dart';

void main() {
  // Miércoles 28 de octubre de 2026.
  final hoy = DateTime(2026, 10, 28, 12);

  SesionEnfoque sesion(DateTime inicio, int segundos, [String? materiaId]) {
    return SesionEnfoque(
      id: 'ses_${inicio.microsecondsSinceEpoch}_$segundos',
      materiaId: materiaId,
      inicio: inicio,
      duracionSegundos: segundos,
    );
  }

  IntentoQuiz intento(
    int aciertos,
    int total,
    DateTime fecha, [
    String materiaId = 'mat_a',
  ]) {
    return IntentoQuiz(
      id: 'qz_${fecha.microsecondsSinceEpoch}_$aciertos',
      materiaId: materiaId,
      aciertos: aciertos,
      total: total,
      fecha: fecha,
    );
  }

  group('calcularRacha', () {
    test('sin sesiones es 0', () {
      expect(calcularRacha([], hoy), 0);
    });

    test('una sesión hoy es 1', () {
      expect(calcularRacha([sesion(DateTime(2026, 10, 28, 9), 1500)], hoy), 1);
    });

    test('hoy y ayer es 2', () {
      final sesiones = [
        sesion(DateTime(2026, 10, 28, 9), 1500),
        sesion(DateTime(2026, 10, 27, 20), 1500),
      ];
      expect(calcularRacha(sesiones, hoy), 2);
    });

    test('solo ayer mantiene viva la racha en 1', () {
      expect(calcularRacha([sesion(DateTime(2026, 10, 27, 20), 1500)], hoy), 1);
    });

    test('solo anteayer ya la rompió: 0', () {
      expect(calcularRacha([sesion(DateTime(2026, 10, 26, 20), 1500)], hoy), 0);
    });

    test('hoy, ayer y anteayer es 3', () {
      final sesiones = [
        sesion(DateTime(2026, 10, 28, 9), 1500),
        sesion(DateTime(2026, 10, 27, 9), 1500),
        sesion(DateTime(2026, 10, 26, 9), 1500),
      ];
      expect(calcularRacha(sesiones, hoy), 3);
    });

    test('dos sesiones el mismo día cuentan un solo día', () {
      final sesiones = [
        sesion(DateTime(2026, 10, 28, 9), 1500),
        sesion(DateTime(2026, 10, 28, 15), 1500),
      ];
      expect(calcularRacha(sesiones, hoy), 1);
    });

    test(
      'un bloque que cruza la medianoche cuenta para el día en que terminó',
      () {
        final sesiones = [
          sesion(DateTime(2026, 10, 27, 12), 1500),
          // Empieza el 27 a las 23:50 y termina el 28 a las 00:15.
          sesion(DateTime(2026, 10, 27, 23, 50), 1500),
        ];
        expect(calcularRacha(sesiones, hoy), 2);
      },
    );

    test('un día sin estudiar rompe la racha', () {
      final sesiones = [
        sesion(DateTime(2026, 10, 28, 9), 1500),
        sesion(DateTime(2026, 10, 26, 9), 1500),
      ];
      expect(calcularRacha(sesiones, hoy), 1);
    });
  });

  group('horasPorDiaDeLaSemana', () {
    test('reparte las horas en lunes a domingo de la semana actual', () {
      final sesiones = [
        sesion(DateTime(2026, 10, 26, 10), 3600),
        sesion(DateTime(2026, 10, 28, 10), 5400),
      ];
      expect(horasPorDiaDeLaSemana(sesiones, hoy), [1.0, 0, 1.5, 0, 0, 0, 0]);
    });

    test('un bloque que cruza la medianoche suma al día en que terminó', () {
      final sesiones = [sesion(DateTime(2026, 10, 27, 23, 50), 1500)];
      final horas = horasPorDiaDeLaSemana(sesiones, hoy);
      expect(horas[1], 0); // martes: empezó, pero no terminó ese día
      expect(horas[2], 1500 / 3600); // miércoles: terminó
    });

    test('ignora las sesiones de la semana anterior', () {
      final sesiones = [sesion(DateTime(2026, 10, 25, 22), 3600)];
      expect(horasPorDiaDeLaSemana(sesiones, hoy), [0, 0, 0, 0, 0, 0, 0]);
    });

    test('un domingo todavía incluye el lunes de esa misma semana', () {
      final domingo = DateTime(2026, 11, 1, 12);
      final sesiones = [sesion(DateTime(2026, 10, 26, 10), 3600)];
      expect(horasPorDiaDeLaSemana(sesiones, domingo)[0], 1.0);
    });
  });

  group('indicePicoSemanal', () {
    test('es null si no hay horas', () {
      expect(indicePicoSemanal([0, 0, 0, 0, 0, 0, 0]), isNull);
    });

    test('devuelve el día con más horas', () {
      expect(indicePicoSemanal([1, 0, 1.5, 0, 0, 0, 0]), 2);
    });

    test('en un empate gana el primero', () {
      expect(indicePicoSemanal([2, 0, 2, 0, 0, 0, 0]), 0);
    });
  });

  test('nombresDiasCortos va de lunes a domingo', () {
    expect(nombresDiasCortos, [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ]);
  });

  group('segundosTotales', () {
    final sesiones = [
      sesion(DateTime(2026, 10, 28, 9), 1500, 'mat_a'),
      sesion(DateTime(2026, 10, 27, 9), 1500, 'mat_b'),
      sesion(DateTime(2026, 10, 26, 9), 600),
    ];

    test('suma todas las sesiones', () {
      expect(segundosTotales(sesiones), 3600);
    });

    test('filtra por materia', () {
      expect(segundosTotales(sesiones, materiaId: 'mat_a'), 1500);
    });
  });

  group('formatearDuracion', () {
    test('formatea minutos y horas', () {
      expect(formatearDuracion(0), '0 min');
      expect(formatearDuracion(15), '15 s');
      expect(formatearDuracion(59), '59 s');
      expect(formatearDuracion(60), '1 min');
      expect(formatearDuracion(2700), '45 min');
      expect(formatearDuracion(3600), '1 h');
      expect(formatearDuracion(9000), '2 h 30 min');
    });
  });

  group('formatearHoras', () {
    test('quita el decimal cuando es entero', () {
      expect(formatearHoras(0), '0');
      expect(formatearHoras(2), '2');
      expect(formatearHoras(2.5), '2.5');
      expect(formatearHoras(1.26), '1.3');
    });
  });

  group('mejorIntento', () {
    test('elige el de mayor proporción de aciertos', () {
      final intentos = [
        intento(3, 5, DateTime(2026, 10, 1)),
        intento(5, 5, DateTime(2026, 10, 2)),
        intento(4, 5, DateTime(2026, 10, 3)),
      ];
      expect(mejorIntento(intentos, 'mat_a')!.aciertos, 5);
    });

    test('en un empate gana el más reciente', () {
      final viejo = intento(4, 5, DateTime(2026, 10, 1));
      final nuevo = intento(4, 5, DateTime(2026, 10, 9));
      expect(mejorIntento([viejo, nuevo], 'mat_a')!.fecha, nuevo.fecha);
    });

    test('no mezcla materias y devuelve null si no hay intentos', () {
      final intentos = [intento(5, 5, DateTime(2026, 10, 1), 'mat_b')];
      expect(mejorIntento(intentos, 'mat_a'), isNull);
    });
  });
}
