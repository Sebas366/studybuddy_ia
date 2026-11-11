import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studybuddy_ia/data/materias_repository_sqflite.dart';
import 'package:studybuddy_ia/models/pregunta.dart';
import 'package:studybuddy_ia/models/resultados_ia.dart';

/// Pruebas de lo que agregó la versión 5 del esquema: lo que guarda la IA
/// (resumen, quiz y chat) y el plan de estudio (evaluaciones y sesiones).
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

  Future<String> crearMateria(String nombre) async {
    final materia = await repositorio.crearMateria(
      nombre: nombre,
      descripcion: '',
      colorIndice: 0,
      iconoClave: 'libro',
      semestre: '2026-2',
    );
    return materia.id;
  }

  const resumen = ResumenApunte(
    corto: 'Corto',
    medio: 'Medio',
    detallado: 'Detallado',
    ideasClave: ['Idea "uno"', 'Idea dos'],
  );

  Pregunta pregunta(String enunciado, int correcta) => Pregunta(
    id: 'ignorado',
    enunciado: enunciado,
    opciones: const ['A', 'B', 'C', 'D'],
    indiceRespuestaCorrecta: correcta,
    explicacionIa: 'Explicación de $enunciado',
  );

  group('resumen de un apunte', () {
    test('un apunte nuevo no tiene resumen', () async {
      final materiaId = await crearMateria('Redes');
      final creado = await repositorio.crearApunte(
        materiaId: materiaId,
        titulo: 'DHCP',
        contenido: 'DORA',
      );

      expect(creado.tieneResumen, isFalse);
      final leido = (await repositorio.obtenerMaterias()).single.apuntes.single;
      expect(leido.tieneResumen, isFalse);
      expect(leido.ideasClave, isEmpty);
    });

    test('guardarResumenApunte lo deja en el apunte', () async {
      final materiaId = await crearMateria('Redes');
      final apunte = await repositorio.crearApunte(
        materiaId: materiaId,
        titulo: 'DHCP',
        contenido: 'DORA',
      );

      await repositorio.guardarResumenApunte(apunte.id, resumen);

      final leido = (await repositorio.obtenerMaterias()).single.apuntes.single;
      expect(leido.resumenCorto, 'Corto');
      expect(leido.resumenMedio, 'Medio');
      expect(leido.resumenDetallado, 'Detallado');
      expect(leido.ideasClave, ['Idea "uno"', 'Idea dos']);
      expect(leido.contenido, 'DORA');
    });

    test('cambiar solo el título conserva el resumen', () async {
      final materiaId = await crearMateria('Redes');
      final apunte = await repositorio.crearApunte(
        materiaId: materiaId,
        titulo: 'DHCP',
        contenido: 'DORA',
      );
      await repositorio.guardarResumenApunte(apunte.id, resumen);

      await repositorio.actualizarApunte(
        id: apunte.id,
        titulo: 'DHCP y DORA',
        contenido: 'DORA',
      );

      final leido = (await repositorio.obtenerMaterias()).single.apuntes.single;
      expect(leido.titulo, 'DHCP y DORA');
      expect(leido.resumenMedio, 'Medio');
    });

    test('cambiar el texto borra el resumen, que ya no corresponde', () async {
      final materiaId = await crearMateria('Redes');
      final apunte = await repositorio.crearApunte(
        materiaId: materiaId,
        titulo: 'DHCP',
        contenido: 'DORA',
      );
      await repositorio.guardarResumenApunte(apunte.id, resumen);

      await repositorio.actualizarApunte(
        id: apunte.id,
        titulo: 'DHCP',
        contenido: 'Texto nuevo',
      );

      final leido = (await repositorio.obtenerMaterias()).single.apuntes.single;
      expect(leido.tieneResumen, isFalse);
      expect(leido.resumenCorto, '');
      expect(leido.ideasClave, isEmpty);
    });
  });

  group('quiz de una materia', () {
    test('reemplazarPreguntas guarda el quiz en orden', () async {
      final materiaId = await crearMateria('Redes');

      await repositorio.reemplazarPreguntas(materiaId, [
        pregunta('Primera', 2),
        pregunta('Segunda', 0),
      ]);

      final preguntas = (await repositorio.obtenerMaterias()).single.preguntas;
      expect(preguntas.map((p) => p.enunciado), ['Primera', 'Segunda']);
      expect(preguntas.first.opciones, ['A', 'B', 'C', 'D']);
      expect(preguntas.first.indiceRespuestaCorrecta, 2);
      expect(preguntas.first.explicacionIa, 'Explicación de Primera');
      expect(preguntas.map((p) => p.id).toSet(), hasLength(2));
    });

    test('un quiz nuevo reemplaza al anterior', () async {
      final materiaId = await crearMateria('Redes');
      await repositorio.reemplazarPreguntas(materiaId, [pregunta('Vieja', 0)]);

      await repositorio.reemplazarPreguntas(materiaId, [pregunta('Nueva', 1)]);

      final preguntas = (await repositorio.obtenerMaterias()).single.preguntas;
      expect(preguntas.single.enunciado, 'Nueva');
    });

    test('cada materia tiene su propio quiz', () async {
      final redes = await crearMateria('Redes');
      final legal = await crearMateria('Legal');
      await repositorio.reemplazarPreguntas(redes, [pregunta('De redes', 0)]);

      final materias = await repositorio.obtenerMaterias();
      expect(
        materias.firstWhere((m) => m.id == redes).preguntas.single.enunciado,
        'De redes',
      );
      expect(materias.firstWhere((m) => m.id == legal).preguntas, isEmpty);
    });
  });

  group('chat con el tutor', () {
    test('los mensajes se guardan en orden y por materia', () async {
      final redes = await crearMateria('Redes');
      final legal = await crearMateria('Legal');

      await repositorio.agregarMensajeChat(
        materiaId: redes,
        texto: '¿Qué es DHCP?',
        esUsuario: true,
      );
      await repositorio.agregarMensajeChat(
        materiaId: redes,
        texto: 'Es un protocolo.',
        esUsuario: false,
      );
      await repositorio.agregarMensajeChat(
        materiaId: legal,
        texto: 'Otra materia',
        esUsuario: true,
      );

      final mensajes = await repositorio.obtenerMensajesChat(redes);
      expect(mensajes.map((m) => m.texto), ['¿Qué es DHCP?', 'Es un protocolo.']);
      expect(mensajes.map((m) => m.esUsuario), [true, false]);
      expect(await repositorio.obtenerMensajesChat(legal), hasLength(1));
    });

    test('borrarMensajesChat solo borra los de esa materia', () async {
      final redes = await crearMateria('Redes');
      final legal = await crearMateria('Legal');
      await repositorio.agregarMensajeChat(
        materiaId: redes,
        texto: 'a',
        esUsuario: true,
      );
      await repositorio.agregarMensajeChat(
        materiaId: legal,
        texto: 'b',
        esUsuario: true,
      );

      await repositorio.borrarMensajesChat(redes);

      expect(await repositorio.obtenerMensajesChat(redes), isEmpty);
      expect(await repositorio.obtenerMensajesChat(legal), hasLength(1));
    });
  });

  group('evaluaciones', () {
    test('se devuelven de la más cercana a la más lejana', () async {
      final materiaId = await crearMateria('Redes');
      await repositorio.crearEvaluacion(
        materiaId: materiaId,
        titulo: 'Final',
        fecha: DateTime(2026, 12, 10),
        temas: 'Todo',
      );
      await repositorio.crearEvaluacion(
        materiaId: materiaId,
        titulo: 'Parcial',
        fecha: DateTime(2026, 11, 20),
        temas: '',
      );

      final evaluaciones = await repositorio.obtenerEvaluaciones();
      expect(evaluaciones.map((e) => e.titulo), ['Parcial', 'Final']);
      expect(evaluaciones.first.fecha, DateTime(2026, 11, 20));
      expect(evaluaciones.last.temas, 'Todo');
    });

    test('actualizar y borrar una evaluación', () async {
      final materiaId = await crearMateria('Redes');
      final evaluacion = await repositorio.crearEvaluacion(
        materiaId: materiaId,
        titulo: 'Parcial',
        fecha: DateTime(2026, 11, 20),
        temas: '',
      );

      await repositorio.actualizarEvaluacion(
        id: evaluacion.id,
        materiaId: materiaId,
        titulo: 'Parcial 1',
        fecha: DateTime(2026, 11, 22),
        temas: 'DHCP',
      );
      final editada = (await repositorio.obtenerEvaluaciones()).single;
      expect(editada.titulo, 'Parcial 1');
      expect(editada.fecha, DateTime(2026, 11, 22));
      expect(editada.temas, 'DHCP');

      await repositorio.borrarEvaluacion(evaluacion.id);
      expect(await repositorio.obtenerEvaluaciones(), isEmpty);
    });
  });

  group('sesiones del plan', () {
    test('se devuelven por hora de inicio y nacen sin completar', () async {
      final materiaId = await crearMateria('Redes');
      await repositorio.crearSesionPlan(
        materiaId: materiaId,
        tema: 'Tarde',
        inicio: DateTime(2026, 11, 10, 18),
        duracionMinutos: 60,
      );
      await repositorio.crearSesionPlan(
        tema: 'Mañana, sin materia',
        inicio: DateTime(2026, 11, 10, 8),
        duracionMinutos: 30,
      );

      final sesiones = await repositorio.obtenerSesionesPlan();
      expect(sesiones.map((s) => s.tema), ['Mañana, sin materia', 'Tarde']);
      expect(sesiones.first.materiaId, isNull);
      expect(sesiones.last.materiaId, materiaId);
      expect(sesiones.every((s) => !s.completada), isTrue);
      expect(sesiones.last.fin, DateTime(2026, 11, 10, 19));
    });

    test('marcar una sesión la deja completada; editarla no lo cambia', () async {
      final sesion = await repositorio.crearSesionPlan(
        tema: 'Repaso',
        inicio: DateTime(2026, 11, 10, 8),
        duracionMinutos: 30,
      );

      await repositorio.marcarSesionPlan(sesion.id, completada: true);
      await repositorio.actualizarSesionPlan(
        id: sesion.id,
        tema: 'Repaso general',
        inicio: DateTime(2026, 11, 11, 9),
        duracionMinutos: 45,
      );

      final leida = (await repositorio.obtenerSesionesPlan()).single;
      expect(leida.completada, isTrue);
      expect(leida.tema, 'Repaso general');
      expect(leida.inicio, DateTime(2026, 11, 11, 9));
      expect(leida.duracionMinutos, 45);

      await repositorio.borrarSesionPlan(sesion.id);
      expect(await repositorio.obtenerSesionesPlan(), isEmpty);
    });
  });

  test('borrar una materia borra su quiz, chat, evaluaciones y sesiones', () async {
    final redes = await crearMateria('Redes');
    final legal = await crearMateria('Legal');
    await repositorio.reemplazarPreguntas(redes, [pregunta('P', 0)]);
    await repositorio.agregarMensajeChat(
      materiaId: redes,
      texto: 'hola',
      esUsuario: true,
    );
    await repositorio.crearEvaluacion(
      materiaId: redes,
      titulo: 'Parcial',
      fecha: DateTime(2026, 11, 20),
      temas: '',
    );
    await repositorio.crearSesionPlan(
      materiaId: redes,
      tema: 'De redes',
      inicio: DateTime(2026, 11, 10, 8),
      duracionMinutos: 30,
    );
    await repositorio.crearSesionPlan(
      materiaId: legal,
      tema: 'De legal',
      inicio: DateTime(2026, 11, 10, 9),
      duracionMinutos: 30,
    );
    await repositorio.crearSesionPlan(
      tema: 'Libre',
      inicio: DateTime(2026, 11, 10, 10),
      duracionMinutos: 30,
    );

    await repositorio.borrarMateria(redes);

    expect(await repositorio.obtenerMensajesChat(redes), isEmpty);
    expect(await repositorio.obtenerEvaluaciones(), isEmpty);
    expect(
      (await repositorio.obtenerSesionesPlan()).map((s) => s.tema),
      ['De legal', 'Libre'],
    );
    final filas = await repositorio.baseDatos.query('preguntas');
    expect(filas, isEmpty);
  });

  test('una base de la versión 4 se actualiza conservando los datos', () async {
    final directorio = Directory.systemTemp.createTempSync('studybuddy_test_');
    addTearDown(() => directorio.deleteSync(recursive: true));
    final ruta = p.join(directorio.path, 'v4.db');

    // Base como la dejó la versión del Pomodoro global (versión 4).
    final dbVieja = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 4,
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
        },
      ),
    );
    await dbVieja.insert('materias', {
      'id': 'mat_v4',
      'nombre': 'Materia v4',
      'descripcion': '',
      'color_indice': 0,
      'icono_clave': 'libro',
      'semestre': '2026-2',
      'creada': 1,
    });
    await dbVieja.insert('apuntes', {
      'id': 'apu_v4',
      'materia_id': 'mat_v4',
      'titulo': 'Apunte v4',
      'contenido': 'texto',
      'creada': 1,
      'modificada': 1,
    });
    await dbVieja.insert('ajustes', {'clave': 'modo_demo', 'valor': '0'});
    await dbVieja.close();

    final actualizada = await MateriasRepositorySqflite.abrir(ruta: ruta);
    addTearDown(actualizada.cerrar);

    final materia = (await actualizada.obtenerMaterias()).single;
    expect(materia.nombre, 'Materia v4');
    expect(materia.preguntas, isEmpty);
    final apunte = materia.apuntes.single;
    expect(apunte.titulo, 'Apunte v4');
    expect(apunte.tieneResumen, isFalse);
    expect(await actualizada.obtenerAjuste('modo_demo'), '0');

    // Lo nuevo de la versión 5 funciona sobre la base actualizada.
    await actualizada.guardarResumenApunte('apu_v4', resumen);
    await actualizada.reemplazarPreguntas('mat_v4', [pregunta('P', 1)]);
    await actualizada.crearEvaluacion(
      materiaId: 'mat_v4',
      titulo: 'Parcial',
      fecha: DateTime(2026, 11, 20),
      temas: '',
    );
    final despues = (await actualizada.obtenerMaterias()).single;
    expect(despues.apuntes.single.resumenMedio, 'Medio');
    expect(despues.preguntas.single.enunciado, 'P');
    expect(await actualizada.obtenerEvaluaciones(), hasLength(1));
  });
}
