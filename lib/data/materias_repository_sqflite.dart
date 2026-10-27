import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/apunte.dart';
import '../models/materia.dart';
import '../utils/formato_fecha.dart';
import 'catalogo_materia.dart';
import 'materias_repository.dart';

/// Implementación de [MateriasRepository] sobre una base de datos SQLite local.
///
/// Esquema versión 1: tablas `materias` y `apuntes`. Las fechas se guardan como
/// milisegundos desde la época. Al borrar una materia, SQLite borra sus apuntes
/// en cascada (requiere `PRAGMA foreign_keys = ON`).
class MateriasRepositorySqflite implements MateriasRepository {
  MateriasRepositorySqflite._(this._db);

  final Database _db;

  /// Último identificador generado; evita repetir ids creados en el mismo microsegundo.
  int _ultimoId = 0;

  /// Abre (o crea) la base de datos en [ruta].
  ///
  /// Si no se indica, usa `studybuddy.db` en la carpeta de bases de datos de la app.
  static Future<MateriasRepositorySqflite> abrir({String? ruta}) async {
    final rutaFinal = ruta ?? p.join(await getDatabasesPath(), 'studybuddy.db');
    final db = await openDatabase(
      rutaFinal,
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
    );
    return MateriasRepositorySqflite._(db);
  }

  /// Cierra la conexión con la base de datos.
  Future<void> cerrar() => _db.close();

  /// Acceso directo a la base de datos, solo para pruebas.
  @visibleForTesting
  Database get baseDatos => _db;

  String _nuevoId(String prefijo) {
    var id = DateTime.now().microsecondsSinceEpoch;
    if (id <= _ultimoId) id = _ultimoId + 1;
    _ultimoId = id;
    return '${prefijo}_$id';
  }

  Apunte _apunteDesdeFila(Map<String, Object?> fila) {
    return Apunte(
      id: fila['id'] as String,
      titulo: fila['titulo'] as String,
      materiaId: fila['materia_id'] as String,
      fecha: formatearFecha(
        DateTime.fromMillisecondsSinceEpoch(fila['creada'] as int),
      ),
      contenido: fila['contenido'] as String,
    );
  }

  Materia _materiaDesdeFila(Map<String, Object?> fila, List<Apunte> apuntes) {
    final colorIndice = fila['color_indice'] as int;
    final iconoClave = fila['icono_clave'] as String;
    final degradado = CatalogoMateria.degradadoPorIndice(colorIndice);
    return Materia(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String,
      subtitulo: Materia.subtituloPorConteo(apuntes.length),
      descripcion: fila['descripcion'] as String,
      progreso: 0,
      icono: CatalogoMateria.iconoPorClave(iconoClave),
      colorInicio: degradado[0],
      colorFin: degradado[1],
      apuntes: apuntes,
      preguntas: const [],
      respuestasSimuladasIa: const [],
      colorIndice: colorIndice,
      iconoClave: iconoClave,
    );
  }

  @override
  Future<List<Materia>> obtenerMaterias() async {
    final filasMaterias =
        await _db.query('materias', orderBy: 'creada DESC, rowid DESC');
    final filasApuntes =
        await _db.query('apuntes', orderBy: 'creada DESC, rowid DESC');

    final apuntesPorMateria = <String, List<Apunte>>{};
    for (final fila in filasApuntes) {
      final apunte = _apunteDesdeFila(fila);
      apuntesPorMateria.putIfAbsent(apunte.materiaId, () => []).add(apunte);
    }

    return [
      for (final fila in filasMaterias)
        _materiaDesdeFila(fila, apuntesPorMateria[fila['id'] as String] ?? []),
    ];
  }

  @override
  Future<Materia> crearMateria({
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
  }) async {
    final fila = <String, Object?>{
      'id': _nuevoId('mat'),
      'nombre': nombre,
      'descripcion': descripcion,
      'color_indice': colorIndice,
      'icono_clave': iconoClave,
      'creada': DateTime.now().millisecondsSinceEpoch,
    };
    await _db.insert('materias', fila);
    return _materiaDesdeFila(fila, const []);
  }

  @override
  Future<void> actualizarMateria({
    required String id,
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
  }) async {
    await _db.update(
      'materias',
      {
        'nombre': nombre,
        'descripcion': descripcion,
        'color_indice': colorIndice,
        'icono_clave': iconoClave,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> borrarMateria(String id) async {
    await _db.delete('materias', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Apunte> crearApunte({
    required String materiaId,
    required String titulo,
    required String contenido,
  }) async {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final fila = <String, Object?>{
      'id': _nuevoId('apu'),
      'materia_id': materiaId,
      'titulo': titulo,
      'contenido': contenido,
      'creada': ahora,
      'modificada': ahora,
    };
    await _db.insert('apuntes', fila);
    return _apunteDesdeFila(fila);
  }

  @override
  Future<void> actualizarApunte({
    required String id,
    required String titulo,
    required String contenido,
  }) async {
    await _db.update(
      'apuntes',
      {
        'titulo': titulo,
        'contenido': contenido,
        'modificada': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> borrarApunte(String id) async {
    await _db.delete('apuntes', where: 'id = ?', whereArgs: [id]);
  }
}
