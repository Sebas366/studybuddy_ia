import '../models/apunte.dart';
import '../models/intento_quiz.dart';
import '../models/materia.dart';
import '../models/sesion_enfoque.dart';

/// Contrato de almacenamiento de las materias y apuntes reales del usuario.
///
/// Permite cambiar la implementación (SQLite en la app, memoria en las pruebas)
/// sin tocar el resto del código.
abstract class MateriasRepository {
  /// Devuelve todas las materias, la más nueva primero, con sus apuntes
  /// cargados (también del más nuevo al más viejo).
  Future<List<Materia>> obtenerMaterias();

  /// Crea una materia nueva y la devuelve sin apuntes.
  Future<Materia> crearMateria({
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
  });

  /// Cambia los datos de una materia existente.
  Future<void> actualizarMateria({
    required String id,
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
  });

  /// Borra la materia y todos sus apuntes.
  Future<void> borrarMateria(String id);

  /// Crea un apunte nuevo en la materia indicada.
  Future<Apunte> crearApunte({
    required String materiaId,
    required String titulo,
    required String contenido,
  });

  /// Cambia el título y el contenido de un apunte, sin alterar su fecha de creación.
  Future<void> actualizarApunte({
    required String id,
    required String titulo,
    required String contenido,
  });

  /// Borra un apunte.
  Future<void> borrarApunte(String id);

  /// Guarda un bloque de enfoque completado del Pomodoro.
  ///
  /// [materiaId] es `null` si se estudió sin materia.
  Future<SesionEnfoque> registrarSesionEnfoque({
    String? materiaId,
    required DateTime inicio,
    required int duracionSegundos,
  });

  /// Devuelve todas las sesiones de enfoque, la de inicio más reciente primero.
  Future<List<SesionEnfoque>> obtenerSesionesEnfoque();

  /// Guarda el resultado de un quiz terminado.
  Future<IntentoQuiz> registrarIntentoQuiz({
    required String materiaId,
    required int aciertos,
    required int total,
  });

  /// Devuelve todos los intentos de quiz, el más reciente primero.
  Future<List<IntentoQuiz>> obtenerIntentosQuiz();
}
