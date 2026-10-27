import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy_ia/providers/materias_provider.dart';

import '../support/repositorio_memoria.dart';

void main() {
  late RepositorioMemoria repositorio;
  late MateriasProvider provider;

  setUp(() {
    repositorio = RepositorioMemoria();
    provider = MateriasProvider(repositorio);
  });

  test('cargando es true hasta terminar la primera carga', () async {
    expect(provider.cargando, isTrue);

    await provider.cargar();

    expect(provider.cargando, isFalse);
    expect(provider.materias, isEmpty);
  });

  test('crearMateria recorta el nombre y notifica a los oyentes', () async {
    await provider.cargar();
    var notificaciones = 0;
    provider.addListener(() => notificaciones++);

    await provider.crearMateria(nombre: '  Redes  ');

    expect(provider.materias.single.nombre, 'Redes');
    expect(notificaciones, greaterThan(0));
  });

  test(
    'crearMateria con nombre vacío lanza ArgumentError y no guarda nada',
    () async {
      await provider.cargar();

      await expectLater(
        provider.crearMateria(nombre: '   '),
        throwsA(isA<ArgumentError>()),
      );

      expect(provider.materias, isEmpty);
      expect(await repositorio.obtenerMaterias(), isEmpty);
    },
  );

  test('crearApunte actualiza el subtítulo de la materia', () async {
    await provider.cargar();
    await provider.crearMateria(nombre: 'Redes');
    final id = provider.materias.single.id;

    await provider.crearApunte(
      materiaId: id,
      titulo: 'DHCP',
      contenido: 'Proceso DORA',
    );

    expect(provider.materias.single.subtitulo, '1 apunte');
    expect(provider.materias.single.apuntes.single.titulo, 'DHCP');
  });

  test('crearApunte con título vacío lanza ArgumentError', () async {
    await provider.cargar();
    await provider.crearMateria(nombre: 'Redes');
    final id = provider.materias.single.id;

    await expectLater(
      provider.crearApunte(materiaId: id, titulo: '', contenido: 'texto'),
      throwsA(isA<ArgumentError>()),
    );

    expect(provider.materias.single.apuntes, isEmpty);
  });

  test('borrarMateria la quita de la lista', () async {
    await provider.cargar();
    await provider.crearMateria(nombre: 'Redes');
    final id = provider.materias.single.id;

    await provider.borrarMateria(id);

    expect(provider.materias, isEmpty);
    expect(provider.porId(id), isNull);
  });

  test('porId devuelve null si la materia no existe', () async {
    await provider.cargar();

    expect(provider.porId('no-existe'), isNull);
  });

  group('cuando la base de datos falla', () {
    test('cargar no lanza: termina de cargar y expone un error', () async {
      final inestable = RepositorioInestable()..fallarLectura = true;
      final proveedor = MateriasProvider(inestable);

      await proveedor.cargar();

      expect(proveedor.cargando, isFalse);
      expect(proveedor.error, 'No se pudieron cargar tus materias.');
      expect(proveedor.materias, isEmpty);
    });

    test(
      'reintentar cargar limpia el error cuando la lectura vuelve',
      () async {
        final inestable = RepositorioInestable()..fallarLectura = true;
        final proveedor = MateriasProvider(inestable);
        await proveedor.cargar();

        inestable.fallarLectura = false;
        await proveedor.cargar();

        expect(proveedor.error, isNull);
      },
    );

    test('si la recarga falla después de guardar, crearMateria no lanza y no se duplica', () async {
      final inestable = RepositorioInestable();
      final proveedor = MateriasProvider(inestable);
      await proveedor.cargar();

      inestable.fallarLectura = true;
      await proveedor.crearMateria(nombre: 'Redes');

      expect(proveedor.error, isNotNull);
      inestable.fallarLectura = false;
      expect(await inestable.obtenerMaterias(), hasLength(1));
    });

    test(
      'si la recarga falla después de guardar, crearApunte no lanza',
      () async {
        final inestable = RepositorioInestable();
        final proveedor = MateriasProvider(inestable);
        await proveedor.cargar();
        await proveedor.crearMateria(nombre: 'Redes');
        final id = proveedor.materias.single.id;

        inestable.fallarLectura = true;
        await proveedor.crearApunte(
          materiaId: id,
          titulo: 'DHCP',
          contenido: 'DORA',
        );

        inestable.fallarLectura = false;
        expect(
          (await inestable.obtenerMaterias()).single.apuntes,
          hasLength(1),
        );
      },
    );
  });

  test(
    'una recarga lenta no pisa los datos de una recarga más nueva',
    () async {
      final lento = RepositorioLecturaLenta();
      final proveedor = MateriasProvider(lento);
      await proveedor.cargar();

      final compuerta = lento.retenerProximaLectura();
      final recargaVieja = proveedor
          .cargar(); // toma la foto vacía y se queda esperando
      await pumpEventQueue();
      await lento.crearMateria(
        nombre: 'Redes',
        descripcion: '',
        colorIndice: 0,
        iconoClave: 'libro',
      );
      await proveedor.cargar(); // recarga más nueva: ve la materia

      compuerta.complete();
      await recargaVieja;

      expect(proveedor.materias, hasLength(1));
    },
  );
}
