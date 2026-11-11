import 'dart:typed_data';

import '../models/apunte.dart';
import '../models/mensaje_chat.dart';
import '../models/pregunta.dart';
import '../models/resultados_ia.dart';

/// Motivo por el que una petición a la IA no se pudo completar.
enum TipoErrorIa {
  /// El usuario todavía no guardó su clave de la API.
  sinClave,

  /// La API rechazó la clave (no existe, se revocó o está mal copiada).
  claveInvalida,

  /// La cuenta no tiene saldo o permiso para usar el modelo.
  sinSaldo,

  /// No hay internet o el servidor no respondió a tiempo.
  sinConexion,

  /// Se hicieron demasiadas peticiones seguidas.
  limite,

  /// El servicio está saturado o caído.
  servicio,

  /// El modelo declinó responder.
  rechazo,

  /// La respuesta llegó incompleta o con un formato inesperado.
  respuestaInvalida,
}

/// Error de la IA con un mensaje listo para mostrar al usuario.
class ErrorIa implements Exception {
  /// Motivo del error.
  final TipoErrorIa tipo;

  /// Mensaje en español para mostrar en pantalla.
  final String mensaje;

  const ErrorIa(this.tipo, this.mensaje);

  /// Error estándar cuando falta la clave de la API.
  const ErrorIa.sinClave()
    : tipo = TipoErrorIa.sinClave,
      mensaje = 'Conecta la IA con tu clave para usar esta función.';

  @override
  String toString() => 'ErrorIa(${tipo.name}): $mensaje';
}

/// Funciones de IA que usa la app.
///
/// Es una interfaz para poder cambiar el proveedor (Gemini o Claude) y para
/// usar un servicio falso en las pruebas. Todas las operaciones lanzan [ErrorIa] si fallan.
abstract class ServicioIa {
  /// Resume un apunte en tres niveles de detalle y extrae sus ideas clave.
  Future<ResumenApunte> resumirApunte({
    required String materia,
    required String titulo,
    required String contenido,
  });

  /// Genera [cantidad] preguntas de opción múltiple a partir de los [apuntes].
  Future<List<Pregunta>> generarQuiz({
    required String materia,
    required List<Apunte> apuntes,
    int cantidad = 5,
  });

  /// Responde como tutor de la [materia], usando los [apuntes] como contexto.
  ///
  /// [historial] es la conversación completa y termina con la pregunta del
  /// estudiante. La respuesta llega por partes a medida que el modelo escribe.
  Stream<String> responderTutor({
    required String materia,
    required String nombreEstudiante,
    required List<Apunte> apuntes,
    required List<MensajeChat> historial,
  });

  /// Transcribe la foto de un apunte (cuaderno, tablero o diapositiva).
  ///
  /// [tipoMime] es el formato de la imagen (ej. `image/jpeg`).
  Future<ApunteEscaneado> transcribirImagen({
    required Uint8List imagen,
    required String tipoMime,
    required String materia,
  });

  /// Propone sesiones de estudio para preparar una evaluación.
  ///
  /// Las sesiones quedan entre [hoy] y el día anterior a [fechaEvaluacion]
  /// (o en [hoy] mismo si la evaluación es hoy o mañana).
  Future<List<SesionSugerida>> sugerirPlan({
    required String materia,
    required String evaluacion,
    required String temas,
    required List<Apunte> apuntes,
    required DateTime hoy,
    required DateTime fechaEvaluacion,
  });

  /// Hace una petición mínima para comprobar que la clave funciona.
  Future<void> probarConexion();
}
