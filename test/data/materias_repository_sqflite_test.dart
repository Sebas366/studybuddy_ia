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
    repositorio =
        await MateriasRepositorySqflite.abrir(ruta: inMemoryDatabasePath);
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
        materiaId: idA, titulo: 'x', contenido: 'primero');
    await repositorio.crearApunte(
        materiaId: idA, titulo: 'y', contenido: 'segundo');

    final materias = await repositorio.obtenerMaterias();

    expect(materias.map((m) => m.nombre), ['B', 'A']);
    final materiaA = materias.last;
    expect(materiaA.apuntes.map((a) => a.titulo), ['y', 'x']);
    expect(materiaA.subtitulo, '2 apuntes');
  });

  test('actualiza nombre, descripción, color e icono de una materia',
      () async {
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

  test('actualiza título y contenido de un apunte sin cambiar su fecha',
      () async {
    final id = await crearMateriaBasica('A');
    final apunte = await repositorio.crearApunte(
        materiaId: id, titulo: 'Viejo', contenido: 'texto viejo');

    await repositorio.actualizarApunte(
        id: apunte.id, titulo: 'Nuevo', contenido: 'texto nuevo');

    final guardado = (await repositorio.obtenerMaterias()).single.apuntes.single;
    expect(guardado.titulo, 'Nuevo');
    expect(guardado.contenido, 'texto nuevo');
    expect(guardado.fecha, apunte.fecha);
  });

  test('borrar una materia borra sus apuntes', () async {
    final id = await crearMateriaBasica('A');
    await repositorio.crearApunte(materiaId: id, titulo: 'x', contenido: '1');
    await repositorio.crearApunte(materiaId: id, titulo: 'y', contenido: '2');

    await repositorio.borrarMateria(id);

    expect(await repositorio.obtenerMaterias(), isEmpty);
    final filas = await repositorio.baseDatos
        .rawQuery('SELECT COUNT(*) AS n FROM apuntes');
    expect(filas.single['n'], 0);
  });

  test('borrar un apunte no toca los demás', () async {
    final id = await crearMateriaBasica('A');
    final x = await repositorio.crearApunte(
        materiaId: id, titulo: 'x', contenido: '1');
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
        materiaId: materia.id, titulo: 'DHCP', contenido: 'DORA');
    await primera.cerrar();

    final segunda = await MateriasRepositorySqflite.abrir(ruta: ruta);
    addTearDown(segunda.cerrar);
    final materias = await segunda.obtenerMaterias();

    expect(materias.single.nombre, 'Persistente');
    expect(materias.single.apuntes.single.titulo, 'DHCP');
  });
}
