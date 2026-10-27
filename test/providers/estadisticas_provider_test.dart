import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/providers/estadisticas_provider.dart';

import '../support/repositorio_memoria.dart';

void main() {
  final inicio = DateTime(2026, 10, 27, 9);

  test('cargar con la base vacía termina de cargar sin datos', () async {
    final proveedor = EstadisticasProvider(RepositorioMemoria());
    expect(proveedor.cargando, isTrue);

    await proveedor.cargar();

    expect(proveedor.cargando, isFalse);
    expect(proveedor.sesiones, isEmpty);
    expect(proveedor.intentos, isEmpty);
    expect(proveedor.error, isNull);
  });

  test(
    'registrarSesionEnfoque guarda, devuelve true y se ve en sesiones',
    () async {
      final proveedor = EstadisticasProvider(RepositorioMemoria());
      await proveedor.cargar();

      final guardada = await proveedor.registrarSesionEnfoque(
        materiaId: 'mat_a',
        inicio: inicio,
        duracionSegundos: 1500,
      );

      expect(guardada, isTrue);
      expect(proveedor.sesiones.single.materiaId, 'mat_a');
      expect(proveedor.sesiones.single.duracionSegundos, 1500);
    },
  );

  test('registrarIntentoQuiz guarda y se ve en intentos', () async {
    final proveedor = EstadisticasProvider(RepositorioMemoria());
    await proveedor.cargar();

    final guardado = await proveedor.registrarIntentoQuiz(
      materiaId: 'mat_a',
      aciertos: 4,
      total: 5,
    );

    expect(guardado, isTrue);
    expect(proveedor.intentos.single.aciertos, 4);
  });

  test('si la lectura falla, cargar no lanza y expone el error', () async {
    final repositorio = RepositorioInestable()..fallarLectura = true;
    final proveedor = EstadisticasProvider(repositorio);

    await proveedor.cargar();

    expect(proveedor.cargando, isFalse);
    expect(proveedor.error, 'No se pudieron cargar tus estadísticas.');

    repositorio.fallarLectura = false;
    await proveedor.cargar();
    expect(proveedor.error, isNull);
  });

  test('si la escritura falla, registrar devuelve false y no lanza', () async {
    final repositorio = RepositorioInestable();
    final proveedor = EstadisticasProvider(repositorio);
    await proveedor.cargar();
    repositorio.fallarEscritura = true;

    final sesion = await proveedor.registrarSesionEnfoque(
      materiaId: null,
      inicio: inicio,
      duracionSegundos: 1500,
    );
    final intento = await proveedor.registrarIntentoQuiz(
      materiaId: 'mat_a',
      aciertos: 1,
      total: 5,
    );

    expect(sesion, isFalse);
    expect(intento, isFalse);
    expect(proveedor.sesiones, isEmpty);
    expect(proveedor.intentos, isEmpty);
  });

  test(
    'sincronizarConMaterias recarga solo cuando cambia el conjunto de materias',
    () async {
      final repositorio = RepositorioMemoria();
      final proveedor = EstadisticasProvider(repositorio);
      await proveedor.cargar();
      final materia = await repositorio.crearMateria(
        nombre: 'Redes',
        descripcion: '',
        colorIndice: 0,
        iconoClave: 'libro',
      );
      // Se agrega un dato directamente en el repositorio, sin pasar por el provider.
      await repositorio.registrarSesionEnfoque(
        materiaId: materia.id,
        inicio: inicio,
        duracionSegundos: 1500,
      );

      // La primera llamada solo fija la referencia: no recarga.
      proveedor.sincronizarConMaterias([]);
      await pumpEventQueue();
      expect(proveedor.sesiones, isEmpty);

      // Mismo conjunto: no recarga.
      proveedor.sincronizarConMaterias([]);
      await pumpEventQueue();
      expect(proveedor.sesiones, isEmpty);

      // Cambia el conjunto de materias: recarga.
      proveedor.sincronizarConMaterias([materia]);
      await pumpEventQueue();
      expect(proveedor.sesiones, hasLength(1));
    },
  );
}
