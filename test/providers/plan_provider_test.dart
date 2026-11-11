import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/models/resultados_ia.dart';
import 'package:studybuddy_ia/providers/plan_provider.dart';

import '../support/abrir_app.dart';
import '../support/repositorio_memoria.dart';

void main() {
  late RepositorioMemoria repositorio;
  late PlanProvider provider;
  late String materiaId;

  setUp(() async {
    repositorio = RepositorioMemoria();
    materiaId = await sembrarMateria(repositorio, 'Redes');
    provider = PlanProvider(repositorio);
    await provider.cargar();
  });

  test('cargando es true hasta terminar la primera carga', () async {
    final nuevo = PlanProvider(repositorio);
    expect(nuevo.cargando, isTrue);

    await nuevo.cargar();

    expect(nuevo.cargando, isFalse);
    expect(nuevo.evaluaciones, isEmpty);
    expect(nuevo.sesiones, isEmpty);
  });

  test('crearEvaluacion recorta los textos y guarda la fecha sin hora', () async {
    await provider.crearEvaluacion(
      materiaId: materiaId,
      titulo: '  Parcial 1  ',
      fecha: DateTime(2026, 11, 20, 14, 30),
      temas: '  DHCP y DNS ',
    );

    final evaluacion = provider.evaluaciones.single;
    expect(evaluacion.titulo, 'Parcial 1');
    expect(evaluacion.temas, 'DHCP y DNS');
    expect(evaluacion.fecha, DateTime(2026, 11, 20));
  });

  test('una evaluación sin título lanza ArgumentError y no guarda nada', () async {
    expect(
      () => provider.crearEvaluacion(
        materiaId: materiaId,
        titulo: '   ',
        fecha: DateTime(2026, 11, 20),
      ),
      throwsArgumentError,
    );
    expect(await repositorio.obtenerEvaluaciones(), isEmpty);
  });

  test('crearSesion valida el tema y la duración', () async {
    final inicio = DateTime(2026, 11, 10, 18);
    expect(
      () => provider.crearSesion(tema: '', inicio: inicio, duracionMinutos: 30),
      throwsArgumentError,
    );
    expect(
      () => provider.crearSesion(tema: 'x', inicio: inicio, duracionMinutos: 0),
      throwsArgumentError,
    );
    expect(await repositorio.obtenerSesionesPlan(), isEmpty);

    await provider.crearSesion(
      materiaId: materiaId,
      tema: ' Repaso ',
      inicio: inicio,
      duracionMinutos: 45,
    );
    expect(provider.sesiones.single.tema, 'Repaso');
  });

  test('marcarSesion cambia el estado y notifica', () async {
    await provider.crearSesion(
      tema: 'Repaso',
      inicio: DateTime(2026, 11, 10, 18),
      duracionMinutos: 45,
    );
    var notificaciones = 0;
    provider.addListener(() => notificaciones++);

    await provider.marcarSesion(provider.sesiones.single.id, completada: true);

    expect(provider.sesiones.single.completada, isTrue);
    expect(notificaciones, greaterThan(0));
  });

  test('agregarSesionesSugeridas guarda las sesiones de la IA en la materia', () async {
    await provider.agregarSesionesSugeridas(materiaId, [
      SesionSugerida(
        inicio: DateTime(2026, 11, 11, 18),
        duracionMinutos: 60,
        tema: 'Segunda',
      ),
      SesionSugerida(
        inicio: DateTime(2026, 11, 10, 18),
        duracionMinutos: 45,
        tema: 'Primera ${'x' * 200}',
      ),
    ]);

    expect(provider.sesiones, hasLength(2));
    expect(provider.sesiones.first.tema, startsWith('Primera'));
    // Un tema demasiado largo se recorta al máximo permitido.
    expect(provider.sesiones.first.tema.length, 120);
    expect(provider.sesiones.every((s) => s.materiaId == materiaId), isTrue);
  });

  test('al borrar una materia, sincronizar recarga y quita lo suyo', () async {
    await provider.crearEvaluacion(
      materiaId: materiaId,
      titulo: 'Parcial',
      fecha: DateTime(2026, 11, 20),
    );
    provider.sincronizarConMaterias(await repositorio.obtenerMaterias());

    await repositorio.borrarMateria(materiaId);
    provider.sincronizarConMaterias(await repositorio.obtenerMaterias());
    await Future<void>.delayed(Duration.zero);

    expect(provider.evaluaciones, isEmpty);
  });

  test('si la lectura falla queda un mensaje de error', () async {
    final inestable = RepositorioInestable()..fallarLectura = true;
    final conFallo = PlanProvider(_PlanInestable(inestable));

    await conFallo.cargar();

    expect(conFallo.error, isNotNull);
    expect(conFallo.cargando, isFalse);
  });
}

/// Repositorio cuyo plan no se puede leer mientras `fallarLectura` esté activo.
class _PlanInestable extends RepositorioMemoria {
  _PlanInestable(this._control);

  final RepositorioInestable _control;

  @override
  Future<List<Never>> obtenerEvaluaciones() async {
    if (_control.fallarLectura) throw StateError('Fallo simulado de lectura');
    return const [];
  }
}
