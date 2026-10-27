/// Formatea segundos como cronómetro `MM:SS` (por ejemplo `25:00` o `00:15`).
String formatearCronometro(int totalSegundos) {
  final minutos = totalSegundos ~/ 60;
  final segundos = totalSegundos % 60;
  return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
}
