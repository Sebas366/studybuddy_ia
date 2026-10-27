import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studybuddy_ia/data/materias_repository_sqflite.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late MateriasRepositorySqflite repositorio;

  setUp(() async {
    repositorio = await MateriasRepositorySqflite.abrir(
      ruta: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await repositorio.cerrar();
  });

  Future<String> crearMateriaBasica(String nombre) async {
    final materia = await repositorio.crearMateria(
      nombre: nombre,
      descripcion: '',
      colorIndice: 0,
      iconoClave: 'libro',
    );
    return materia.id;
  }

  test('crea una materia y la devuelve con 0 apuntes', () async {
    final materia = await repositorio.crearMateria(
      nombre: 'Redes',
      descripcion: 'Protocolos',
      colorIndice: 2,
      iconoClave: 'red',
    );

    expect(materia.nombre, 'Redes');
    expect(materia.descripcion, 'Protocolos');
    expect(materia.colorIndice, 2);
    expect(materia.iconoClave, 'red');
    expect(materia.apuntes, isEmpty);
    expect(materia.subtitulo, 'Sin apuntes');
    expect(materia.esDemo, isFalse);
    expect(materia.progreso, 0);

    final guardadas = await repositorio.obtenerMaterias();
    expect(guardadas, hasLength(1));
    expect(guardadas.single.id, materia.id);
  });

  test('devuelve materias y apuntes del más nuevo al más viejo', () async {
    final idA = await crearMateriaBasica('A');
    await crearMateriaBasica('B');
    await repositorio.crearApunte(
      materiaId: idA,
      titulo: 'x',
      contenido: 'primero',
    );
    await repositorio.crearApunte(
      materiaId: idA,
      titulo: 'y',
      contenido: 'segundo',
    );

    final materias = await repositorio.obtenerMaterias();

    expect(materias.map((m) => m.nombre), ['B', 'A']);
    final materiaA = materias.last;
    expect(materiaA.apuntes.map((a) => a.titulo), ['y', 'x']);
    expect(materiaA.subtitulo, '2 apuntes');
  });

  test('actualiza nombre, descripción, color e icono de una materia', () async {
    final id = await crearMateriaBasica('Viejo');

    await repositorio.actualizarMateria(
      id: id,
      nombre: 'Nuevo',
      descripcion: 'Descripción nueva',
      colorIndice: 4,
      iconoClave: 'codigo',
    );

    final materia = (await repositorio.obtenerMaterias()).single;
    expect(materia.nombre, 'Nuevo');
    expect(materia.descripcion, 'Descripción nueva');
    expect(materia.colorIndice, 4);
    expect(materia.iconoClave, 'codigo');
  });

  test(
    'actualiza título y contenido de un apunte sin cambiar su fecha',
    () async {
      final id = await crearMateriaBasica('A');
      final apunte = await repositorio.crearApunte(
        materiaId: id,
        titulo: 'Viejo',
        contenido: 'texto viejo',
      );

      await repositorio.actualizarApunte(
        id: apunte.id,
        titulo: 'Nuevo',
        contenido: 'texto nuevo',
      );

      final guardado =
          (await repositorio.obtenerMaterias()).single.apuntes.single;
      expect(guardado.titulo, 'Nuevo');
      expect(guardado.contenido, 'texto nuevo');
      expect(guardado.fecha, apunte.fecha);
    },
  );

  test('borrar una materia borra sus apuntes', () async {
    final id = await crearMateriaBasica('A');
    await repositorio.crearApunte(materiaId: id, titulo: 'x', contenido: '1');
    await repositorio.crearApunte(materiaId: id, titulo: 'y', contenido: '2');

    await repositorio.borrarMateria(id);

    expect(await repositorio.obtenerMaterias(), isEmpty);
    final filas = await repositorio.baseDatos.rawQuery(
      'SELECT COUNT(*) AS n FROM apuntes',
    );
    expect(filas.single['n'], 0);
  });

  test('borrar un apunte no toca los demás', () async {
    final id = await crearMateriaBasica('A');
    final x = await repositorio.crearApunte(
      materiaId: id,
      titulo: 'x',
      contenido: '1',
    );
    await repositorio.crearApunte(materiaId: id, titulo: 'y', contenido: '2');

    await repositorio.borrarApunte(x.id);

    final apuntes = (await repositorio.obtenerMaterias()).single.apuntes;
    expect(apuntes.map((a) => a.titulo), ['y']);
  });

  test('los datos sobreviven a cerrar y reabrir', () async {
    final directorio = Directory.systemTemp.createTempSync('studybuddy_test_');
    addTearDown(() => directorio.deleteSync(recursive: true));
    final ruta = p.join(directorio.path, 'prueba.db');

    final primera = await MateriasRepositorySqflite.abrir(ruta: ruta);
    final materia = await primera.crearMateria(
      nombre: 'Persistente',
      descripcion: '',
      colorIndice: 1,
      iconoClave: 'red',
    );
    await primera.crearApunte(
      materiaId: materia.id,
      titulo: 'DHCP',
      contenido: 'DORA',
    );
    await primera.cerrar();

    final segunda = await MateriasRepositorySqflite.abrir(ruta: ruta);
    addTearDown(segunda.cerrar);
    final materias = await segunda.obtenerMaterias();

    expect(materias.single.nombre, 'Persistente');
    expect(materias.single.apuntes.single.titulo, 'DHCP');
  });

  group('sesiones de enfoque e intentos de quiz', () {
    test('registra y devuelve sesiones del más nuevo al más viejo', () async {
      await repositorio.registrarSesionEnfoque(
        materiaId: null,
        inicio: DateTime(2026, 10, 26, 9),
        duracionSegundos: 1500,
      );
      await repositorio.registrarSesionEnfoque(
        materiaId: 'mat_x',
        inicio: DateTime(2026, 10, 27, 9),
        duracionSegundos: 1200,
      );

      final sesiones = await repositorio.obtenerSesionesEnfoque();

      expect(sesiones, hasLength(2));
      expect(sesiones.map((s) => s.materiaId), ['mat_x', null]);
      expect(sesiones.first.duracionSegundos, 1200);
      expect(sesiones.first.inicio, DateTime(2026, 10, 27, 9));
    });

    test(
      'registra y devuelve intentos de quiz del más nuevo al más viejo',
      () async {
        await repositorio.registrarIntentoQuiz(
          materiaId: 'mat_a',
          aciertos: 3,
          total: 5,
        );
        await repositorio.registrarIntentoQuiz(
          materiaId: 'mat_a',
          aciertos: 5,
          total: 5,
        );

        final intentos = await repositorio.obtenerIntentosQuiz();

        expect(intentos.map((i) => i.aciertos), [5, 3]);
        expect(intentos.first.total, 5);
        expect(intentos.first.materiaId, 'mat_a');
      },
    );

    test(
      'borrar una materia borra sus sesiones e intentos pero no los de otras',
      () async {
        final a = await crearMateriaBasica('A');
        final b = await crearMateriaBasica('B');
        for (final id in [a, b, null]) {
          await repositorio.registrarSesionEnfoque(
            materiaId: id,
            inicio: DateTime(2026, 10, 27, 9),
            duracionSegundos: 1500,
          );
        }
        await repositorio.registrarIntentoQuiz(
          materiaId: a,
          aciertos: 4,
          total: 5,
        );
        await repositorio.registrarIntentoQuiz(
          materiaId: b,
          aciertos: 2,
          total: 5,
        );

        await repositorio.borrarMateria(a);

        final sesiones = await repositorio.obtenerSesionesEnfoque();
        final intentos = await repositorio.obtenerIntentosQuiz();
        expect(sesiones.map((s) => s.materiaId), unorderedEquals([b, null]));
        expect(intentos.map((i) => i.materiaId), [b]);
      },
    );

    test('los datos nuevos sobreviven a cerrar y reabrir', () async {
      final directorio = Directory.systemTemp.createTempSync(
        'studybuddy_test_',
      );
      addTearDown(() => directorio.deleteSync(recursive: true));
      final ruta = p.join(directorio.path, 'estadisticas.db');

      final primera = await MateriasRepositorySqflite.abrir(ruta: ruta);
      await primera.registrarSesionEnfoque(
        materiaId: 'mat_a',
        inicio: DateTime(2026, 10, 27, 9),
        duracionSegundos: 1500,
      );
      await primera.registrarIntentoQuiz(
        materiaId: 'mat_a',
        aciertos: 4,
        total: 5,
      );
      await primera.cerrar();

      final segunda = await MateriasRepositorySqflite.abrir(ruta: ruta);
      addTearDown(segunda.cerrar);

      expect(await segunda.obtenerSesionesEnfoque(), hasLength(1));
      expect((await segunda.obtenerIntentosQuiz()).single.aciertos, 4);
    });
  });

  test('actualizar desde la versión 1 conserva materias y apuntes y habilita las tablas nuevas', () async {
    final directorio = Directory.systemTemp.createTempSync('studybuddy_test_');
    addTearDown(() => directorio.deleteSync(recursive: true));
    final ruta = p.join(directorio.path, 'v1.db');

    // Base creada como la dejó la Parte 1 (versión 1, sin tablas de estadísticas).
    final dbVieja = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE materias (
              id TEXT PRIMARY KEY,
              nombre TEXT NOT NULL,
              descripcion TEXT NOT NULL,
              color_indice INTEGER NOT NULL,
              icono_clave TEXT NOT NULL,
              creada INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE apuntes (
              id TEXT PRIMARY KEY,
              materia_id TEXT NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
              titulo TEXT NOT NULL,
              contenido TEXT NOT NULL,
              creada INTEGER NOT NULL,
              modificada INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    await dbVieja.insert('materias', {
      'id': 'mat_vieja',
      'nombre': 'Materia de la v1',
      'descripcion': '',
      'color_indice': 1,
      'icono_clave': 'red',
      'creada': 1000,
    });
    await dbVieja.insert('apuntes', {
      'id': 'apu_viejo',
      'materia_id': 'mat_vieja',
      'titulo': 'Apunte de la v1',
      'contenido': 'texto',
      'creada': 2000,
      'modificada': 2000,
    });
    await dbVieja.close();

    final actualizada = await MateriasRepositorySqflite.abrir(ruta: ruta);
    addTearDown(actualizada.cerrar);

    final materias = await actualizada.obtenerMaterias();
    expect(materias.single.nombre, 'Materia de la v1');
    expect(materias.single.apuntes.single.titulo, 'Apunte de la v1');

    await actualizada.registrarSesionEnfoque(
      materiaId: 'mat_vieja',
      inicio: DateTime(2026, 10, 27, 9),
      duracionSegundos: 1500,
    );
    expect(await actualizada.obtenerSesionesEnfoque(), hasLength(1));
  });
}
