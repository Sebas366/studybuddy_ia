/// Reloj controlado por la prueba, para simular el paso del tiempo real.
///
/// Se pasa a las pantallas como su función de "ahora"; `avanzar` mueve la hora
/// sin necesidad de esperar.
class RelojFalso {
  /// Hora actual simulada.
  DateTime actual;

  RelojFalso(this.actual);

  /// Devuelve la hora simulada (permite usar el reloj como `DateTime Function()`).
  DateTime call() => actual;

  /// Adelanta la hora simulada.
  void avanzar(Duration duracion) {
    actual = actual.add(duracion);
  }
}
