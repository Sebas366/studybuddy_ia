import 'modo_pomodoro.dart';

/// Estado de un bloque de Pomodoro en curso, tal como se guarda en el dispositivo.
///
/// Permite retomar el bloque si la app se cierra mientras el tiempo corre.
class EstadoPomodoro {
  /// Modo del bloque actual.
  final ModoPomodoro modo;

  /// `true` si el temporizador está corriendo; `false` si está en pausa.
  final bool corriendo;

  /// Hora a la que termina el bloque; solo existe mientras [corriendo] es `true`.
  final DateTime? fin;

  /// Segundos que faltan para terminar el bloque.
  final int segundosRestantes;

  /// Duración total del bloque en segundos (para calcular su hora de inicio).
  final int segundosTotales;

  /// Bloques de enfoque completados en la ronda actual.
  final int ciclos;

  /// Materia a la que se dedica el bloque; `null` si se estudia sin materia.
  final String? materiaId;

  /// Nombre de la materia (para mostrarlo sin consultar la lista).
  final String? materiaNombre;

  const EstadoPomodoro({
    required this.modo,
    required this.corriendo,
    this.fin,
    required this.segundosRestantes,
    required this.segundosTotales,
    required this.ciclos,
    this.materiaId,
    this.materiaNombre,
  });
}
