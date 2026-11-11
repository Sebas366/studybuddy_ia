import '../models/apunte.dart';
import '../models/estado_pomodoro.dart';
import '../models/evaluacion.dart';
import '../models/intento_quiz.dart';
import '../models/materia.dart';
import '../models/mensaje_chat.dart';
import '../models/pregunta.dart';
import '../models/resultados_ia.dart';
import '../models/sesion_enfoque.dart';
import '../models/sesion_estudio.dart';

/// Contrato de almacenamiento de todo lo que el usuario guarda en la app:
/// materias, apuntes, resultados de la IA, plan de estudio y estadísticas.
///
/// Permite cambiar la implementación (SQLite en la app, memoria en las pruebas)
/// sin tocar el resto del código.
abstract class MateriasRepository {
  /// Devuelve todas las materias, la más nueva primero, con sus apuntes
  /// (también del más nuevo al más viejo) y las preguntas de su último quiz.
  Future<List<Materia>> obtenerMaterias();

  /// Crea una materia nueva y la devuelve sin apuntes.
  Future<Materia> crearMateria({
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
    required String semestre,
  });

  /// Cambia los datos de una materia existente.
  Future<void> actualizarMateria({
    required String id,
    required String nombre,
    required String descripcion,
    required int colorIndice,
    required String iconoClave,
    required String semestre,
  });

  /// Borra la materia y todo lo que cuelga de ella: apuntes, quiz, chat con el
  /// tutor, evaluaciones, sesiones del plan y estadísticas.
  Future<void> borrarMateria(String id);

  /// Crea un apunte nuevo en la materia indicada.
  Future<Apunte> crearApunte({
    required String materiaId,
    required String titulo,
    required String contenido,
  });

  /// Cambia el título y el contenido de un apunte, sin alterar su fecha de creación.
  ///
  /// Si el contenido cambia, se borra el resumen de la IA porque ya no corresponde.
  Future<void> actualizarApunte({
    required String id,
    required String titulo,
    required String contenido,
  });

  /// Borra un apunte.
  Future<void> borrarApunte(String id);

  /// Guarda el resumen que la IA generó para un apunte, reemplazando el anterior.
  Future<void> guardarResumenApunte(String apunteId, ResumenApunte resumen);

  /// Reemplaza el quiz de una materia por las [preguntas] recién generadas.
  ///
  /// Los ids de las preguntas recibidas se ignoran; se asignan nuevos.
  Future<void> reemplazarPreguntas(String materiaId, List<Pregunta> preguntas);

  /// Devuelve la conversación con el tutor de una materia, del mensaje más viejo al más nuevo.
  Future<List<MensajeChat>> obtenerMensajesChat(String materiaId);

  /// Agrega un mensaje a la conversación con el tutor de una materia.
  Future<MensajeChat> agregarMensajeChat({
    required String materiaId,
    required String texto,
    required bool esUsuario,
  });

  /// Borra toda la conversación con el tutor de una materia.
  Future<void> borrarMensajesChat(String materiaId);

  /// Devuelve todas las evaluaciones, la de fecha más cercana primero.
  Future<List<Evaluacion>> obtenerEvaluaciones();

  /// Crea una evaluación para una materia.
  Future<Evaluacion> crearEvaluacion({
    required String materiaId,
    required String titulo,
    required DateTime fecha,
    required String temas,
  });

  /// Cambia los datos de una evaluación.
  Future<void> actualizarEvaluacion({
    required String id,
    required String materiaId,
    required String titulo,
    required DateTime fecha,
    required String temas,
  });

  /// Borra una evaluación.
  Future<void> borrarEvaluacion(String id);

  /// Devuelve todas las sesiones del plan de estudio, la más próxima primero.
  Future<List<SesionEstudio>> obtenerSesionesPlan();

  /// Agrega una sesión al plan de estudio.
  Future<SesionEstudio> crearSesionPlan({
    String? materiaId,
    required String tema,
    required DateTime inicio,
    required int duracionMinutos,
  });

  /// Cambia los datos de una sesión del plan (no su estado de completada).
  Future<void> actualizarSesionPlan({
    required String id,
    String? materiaId,
    required String tema,
    required DateTime inicio,
    required int duracionMinutos,
  });

  /// Marca o desmarca una sesión del plan como completada.
  Future<void> marcarSesionPlan(String id, {required bool completada});

  /// Borra una sesión del plan.
  Future<void> borrarSesionPlan(String id);

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

  /// Devuelve el bloque de Pomodoro en curso, o `null` si no hay ninguno guardado.
  Future<EstadoPomodoro?> obtenerPomodoroEnCurso();

  /// Guarda el bloque de Pomodoro en curso, reemplazando el anterior.
  Future<void> guardarPomodoroEnCurso(EstadoPomodoro estado);

  /// Borra el bloque de Pomodoro en curso guardado.
  Future<void> borrarPomodoroEnCurso();

  /// Devuelve el valor de un ajuste de la app, o `null` si nunca se guardó.
  Future<String?> obtenerAjuste(String clave);

  /// Guarda un ajuste de la app, reemplazando su valor anterior.
  Future<void> guardarAjuste(String clave, String valor);
}
