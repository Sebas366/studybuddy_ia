import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/models/evaluacion.dart';
import 'package:studybuddy_ia/models/sesion_estudio.dart';
import 'package:studybuddy_ia/utils/plan.dart';

void main() {
  final hoy = DateTime(2026, 11, 10, 15, 30);

  Evaluacion evaluacion(String titulo, DateTime fecha) =>
      Evaluacion(id: titulo, materiaId: 'm', titulo: titulo, fecha: fecha);

  SesionEstudio sesion(String tema, DateTime inicio) => SesionEstudio(
    id: tema,
    materiaId: null,
    tema: tema,
    inicio: inicio,
    duracionMinutos: 30,
  );

  group('diasRestantes', () {
    test('cuenta días de calendario, sin importar la hora', () {
      expect(diasRestantes(DateTime(2026, 11, 10), hoy), 0);
      expect(diasRestantes(DateTime(2026, 11, 11), hoy), 1);
      expect(diasRestantes(DateTime(2026, 11, 13), hoy), 3);
      expect(diasRestantes(DateTime(2026, 11, 9, 23, 59), hoy), -1);
    });

    test('cruza el cambio de mes y de año', () {
      expect(diasRestantes(DateTime(2026, 12, 1), hoy), 21);
      expect(diasRestantes(DateTime(2027, 1, 1), DateTime(2026, 12, 31)), 1);
    });
  });

  test('textoDiasRestantes distingue hoy, mañana y varios días', () {
    expect(textoDiasRestantes(0), 'Hoy');
    expect(textoDiasRestantes(1), 'Mañana');
    expect(textoDiasRestantes(5), 'En 5 días');
  });

  test('formatearFechaLarga escribe el día de la semana y el mes', () {
    expect(formatearFechaLarga(DateTime(2026, 11, 10)), 'Martes, 10 de noviembre');
    expect(formatearFechaLarga(DateTime(2026, 9, 24)), 'Jueves, 24 de septiembre');
  });

  test('formatearHora usa formato de 12 horas', () {
    expect(formatearHora(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(formatearHora(DateTime(2026, 1, 1, 9, 0)), '9:00 AM');
    expect(formatearHora(DateTime(2026, 1, 1, 12, 30)), '12:30 PM');
    expect(formatearHora(DateTime(2026, 1, 1, 18, 45)), '6:45 PM');
  });

  test('evaluacionesPendientes deja las de hoy en adelante, la más cercana primero', () {
    final pendientes = evaluacionesPendientes([
      evaluacion('Final', DateTime(2026, 12, 10)),
      evaluacion('Pasada', DateTime(2026, 11, 9)),
      evaluacion('Hoy', DateTime(2026, 11, 10)),
      evaluacion('Parcial', DateTime(2026, 11, 20)),
    ], hoy);

    expect(pendientes.map((e) => e.titulo), ['Hoy', 'Parcial', 'Final']);
  });

  test('sesionesDelDia y sesionesProximas separan hoy de los días siguientes', () {
    final sesiones = [
      sesion('Mañana', DateTime(2026, 11, 11, 8)),
      sesion('Hoy tarde', DateTime(2026, 11, 10, 18)),
      sesion('Ayer', DateTime(2026, 11, 9, 8)),
      sesion('Hoy temprano', DateTime(2026, 11, 10, 7)),
      sesion('Semana que viene', DateTime(2026, 11, 17, 8)),
    ];

    expect(
      sesionesDelDia(sesiones, hoy).map((s) => s.tema),
      ['Hoy temprano', 'Hoy tarde'],
    );
    expect(
      sesionesProximas(sesiones, hoy).map((s) => s.tema),
      ['Mañana', 'Semana que viene'],
    );
  });
}
