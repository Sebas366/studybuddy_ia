import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/apunte.dart';
import '../models/estado_pomodoro.dart';
import '../models/intento_quiz.dart';
import '../models/materia.dart';
import '../models/modo_pomodoro.dart';
import '../models/sesion_enfoque.dart';
import '../utils/formato_fecha.dart';
import 'catalogo_materia.dart';
import 'materias_repository.dart';

/// Implementación de [MateriasRepository] sobre una base de datos SQLite local.
///
/// Esquema versión 2: tablas `materias`, `apuntes`, `sesiones_enfoque` e
/// `intentos_quiz`. La versión 2 solo agrega las dos últimas (la migración desde
/// la 1 conserva todo lo guardado). Las fechas se guardan como milisegundos desde la época. Al borrar una materia, SQLite borra sus apuntes
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
      version: 4,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE materias (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            descripcion TEXT NOT NULL,
            color_indice INTEGER NOT NULL,
            icono_clave TEXT NOT NULL,
            semestre TEXT NOT NULL,
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
        await _crearTablasVersion2(db);
        await _crearTablasVersion4(db);
      },
      onUpgrade: (db, versionAnterior, versionNueva) async {
        if (versionAnterior < 2) await _crearTablasVersion2(db);
        if (versionAnterior < 3) await _agregarSemestreVersion3(db);
        if (versionAnterior < 4) await _crearTablasVersion4(db);
      },
    );
    return MateriasRepositorySqflite._(db);
  }

  /// Crea las tablas que se agregaron en la versión 2 del esquema.
  ///
  /// No tienen llave foránea a `materias`: las materias de demostración no
  /// existen en esa tabla, así que `borrarMateria` limpia estas filas a mano.
  static Future<void> _crearTablasVersion2(Database db) async {
    await db.execute('''
      CREATE TABLE sesiones_enfoque (
        id TEXT PRIMARY KEY,
        materia_id TEXT,
        inicio INTEGER NOT NULL,
        duracion_segundos INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE intentos_quiz (
        id TEXT PRIMARY KEY,
        materia_id TEXT NOT NULL,
        aciertos INTEGER NOT NULL,
        total INTEGER NOT NULL,
        fecha INTEGER NOT NULL
      )
    ''');
  }

  /// Crea las tablas de la versión 4: el Pomodoro en curso (un solo registro) y los ajustes.
  static Future<void> _crearTablasVersion4(Database db) async {
    await db.execute('''
      CREATE TABLE pomodoro_en_curso (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        modo TEXT NOT NULL,
        corriendo INTEGER NOT NULL,
        fin INTEGER,
        segundos_restantes INTEGER NOT NULL,
        segundos_totales INTEGER NOT NULL,
        ciclos INTEGER NOT NULL,
        materia_id TEXT,
        materia_nombre TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE ajustes (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');
  }

  /// Agrega la columna `semestre` (versión 3 del esquema).
  ///
  /// Las materias que ya existían reciben el semestre que corresponde a su fecha
  /// de creación: de enero a junio `AAAA-1` y de julio a diciembre `AAAA-2`.
  static Future<void> _agregarSemestreVersion3(Database db) async {
    await db.execute(
      "ALTER TABLE materias ADD COLUMN semestre TEXT NOT NULL DEFAULT ''",
    );
    await db.execute('''
      UPDATE materias SET semestre =
        strftime('%Y', creada / 1000, 'unixepoch', 'localtime') || '-' ||
        CASE WHEN CAST(strftime('%m', creada / 1000, 'unixepoch', 'localtime') AS INTEGER) <= 6
             THEN '1' ELSE '2' END
    ''');
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
      semestre: fila['semestre'] as String,
    );
  }

  @override
  Future<List<Materia>> obtenerMaterias() async {
    final filasMaterias = await _db.query(
      'materias',
      orderBy: 'creada DESC, rowid DESC',
    );
    final filasApuntes = await _db.query(
      'apuntes',
      orderBy: 'creada DESC, rowid DESC',
    );

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
    required String semestre,
  }) async {
    final fila = <String, Object?>{
      'id': _nuevoId('mat'),
      'nombre': nombre,
      'descripcion': descripcion,
      'color_indice': colorIndice,
      'icono_clave': iconoClave,
      'semestre': semestre,
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
    required String semestre,
  }) async {
    await _db.update(
      'materias',
      {
        'nombre': nombre,
        'descripcion': descripcion,
        'color_indice': colorIndice,
        'icono_clave': iconoClave,
        'semestre': semestre,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> borrarMateria(String id) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'sesiones_enfoque',
        where: 'materia_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'intentos_quiz',
        where: 'materia_id = ?',
        whereArgs: [id],
      );
      await txn.delete('materias', where: 'id = ?', whereArgs: [id]);
    });
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

  SesionEnfoque _sesionDesdeFila(Map<String, Object?> fila) {
    return SesionEnfoque(
      id: fila['id'] as String,
      materiaId: fila['materia_id'] as String?,
      inicio: DateTime.fromMillisecondsSinceEpoch(fila['inicio'] as int),
      duracionSegundos: fila['duracion_segundos'] as int,
    );
  }

  IntentoQuiz _intentoDesdeFila(Map<String, Object?> fila) {
    return IntentoQuiz(
      id: fila['id'] as String,
      materiaId: fila['materia_id'] as String,
      aciertos: fila['aciertos'] as int,
      total: fila['total'] as int,
      fecha: DateTime.fromMillisecondsSinceEpoch(fila['fecha'] as int),
    );
  }

  @override
  Future<SesionEnfoque> registrarSesionEnfoque({
    String? materiaId,
    required DateTime inicio,
    required int duracionSegundos,
  }) async {
    final fila = <String, Object?>{
      'id': _nuevoId('ses'),
      'materia_id': materiaId,
      'inicio': inicio.millisecondsSinceEpoch,
      'duracion_segundos': duracionSegundos,
    };
    await _db.insert('sesiones_enfoque', fila);
    return _sesionDesdeFila(fila);
  }

  @override
  Future<List<SesionEnfoque>> obtenerSesionesEnfoque() async {
    final filas = await _db.query(
      'sesiones_enfoque',
      orderBy: 'inicio DESC, rowid DESC',
    );
    return filas.map(_sesionDesdeFila).toList();
  }

  @override
  Future<IntentoQuiz> registrarIntentoQuiz({
    required String materiaId,
    required int aciertos,
    required int total,
  }) async {
    final fila = <String, Object?>{
      'id': _nuevoId('qz'),
      'materia_id': materiaId,
      'aciertos': aciertos,
      'total': total,
      'fecha': DateTime.now().millisecondsSinceEpoch,
    };
    await _db.insert('intentos_quiz', fila);
    return _intentoDesdeFila(fila);
  }

  @override
  Future<List<IntentoQuiz>> obtenerIntentosQuiz() async {
    final filas = await _db.query(
      'intentos_quiz',
      orderBy: 'fecha DESC, rowid DESC',
    );
    return filas.map(_intentoDesdeFila).toList();
  }

  @override
  Future<EstadoPomodoro?> obtenerPomodoroEnCurso() async {
    final filas = await _db.query('pomodoro_en_curso', limit: 1);
    if (filas.isEmpty) return null;
    final fila = filas.single;
    final fin = fila['fin'] as int?;
    return EstadoPomodoro(
      modo: ModoPomodoro.values.byName(fila['modo'] as String),
      corriendo: (fila['corriendo'] as int) == 1,
      fin: fin == null ? null : DateTime.fromMillisecondsSinceEpoch(fin),
      segundosRestantes: fila['segundos_restantes'] as int,
      segundosTotales: fila['segundos_totales'] as int,
      ciclos: fila['ciclos'] as int,
      materiaId: fila['materia_id'] as String?,
      materiaNombre: fila['materia_nombre'] as String?,
    );
  }

  @override
  Future<void> guardarPomodoroEnCurso(EstadoPomodoro estado) async {
    await _db.insert('pomodoro_en_curso', {
      'id': 1,
      'modo': estado.modo.name,
      'corriendo': estado.corriendo ? 1 : 0,
      'fin': estado.fin?.millisecondsSinceEpoch,
      'segundos_restantes': estado.segundosRestantes,
      'segundos_totales': estado.segundosTotales,
      'ciclos': estado.ciclos,
      'materia_id': estado.materiaId,
      'materia_nombre': estado.materiaNombre,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> borrarPomodoroEnCurso() async {
    await _db.delete('pomodoro_en_curso');
  }

  @override
  Future<String?> obtenerAjuste(String clave) async {
    final filas = await _db.query(
      'ajustes',
      where: 'clave = ?',
      whereArgs: [clave],
      limit: 1,
    );
    return filas.isEmpty ? null : filas.single['valor'] as String;
  }

  @override
  Future<void> guardarAjuste(String clave, String valor) async {
    await _db.insert('ajustes', {
      'clave': clave,
      'valor': valor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
