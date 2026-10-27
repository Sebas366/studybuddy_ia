import 'package:flutter/material.dart';

/// Modalidades de tiempo de la técnica Pomodoro.
///
/// Cada modo tiene una duración normal (25, 5 y 15 minutos) y una corta para
/// la demostración (15, 5 y 10 segundos).
enum ModoPomodoro {
  enfoque,
  descansoCorto,
  descansoLargo;

  /// Nombre que se muestra al usuario.
  String get etiqueta => switch (this) {
    ModoPomodoro.enfoque => 'Enfoque',
    ModoPomodoro.descansoCorto => 'Descanso Corto',
    ModoPomodoro.descansoLargo => 'Descanso Largo',
  };

  /// Icono representativo del modo.
  IconData get icono => switch (this) {
    ModoPomodoro.enfoque => Icons.center_focus_strong_rounded,
    ModoPomodoro.descansoCorto => Icons.coffee_rounded,
    ModoPomodoro.descansoLargo => Icons.weekend_rounded,
  };

  /// Duración del modo en segundos; con [demo] activado, la versión corta.
  int segundos({required bool demo}) => switch (this) {
    ModoPomodoro.enfoque => demo ? 15 : 25 * 60,
    ModoPomodoro.descansoCorto => demo ? 5 : 5 * 60,
    ModoPomodoro.descansoLargo => demo ? 10 : 15 * 60,
  };
}
