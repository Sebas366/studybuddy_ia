import '../models/intento_quiz.dart';
import '../models/sesion_enfoque.dart';

/// Nombres cortos de los días de la semana, de lunes a domingo.
const List<String> nombresDiasCortos = [
  'Lun',
  'Mar',
  'Mié',
  'Jue',
  'Vie',
  'Sáb',
  'Dom',
];

/// Devuelve solo la fecha (sin hora) de un momento, en hora local.
DateTime _soloFecha(DateTime momento) =>
    DateTime(momento.year, momento.month, momento.day);

/// Día (sin hora) al que se acredita una sesión: el día en que terminó el bloque.
///
/// Un bloque que empieza a las 23:50 y termina a las 00:15 cuenta para el día
/// siguiente, que es cuando realmente se completó.
DateTime _diaDeSesion(SesionEnfoque sesion) =>
    _soloFecha(sesion.inicio.add(Duration(seconds: sesion.duracionSegundos)));

/// Calcula la racha de estudio: días consecutivos con al menos una sesión.
///
/// Cuenta hacia atrás desde hoy; si hoy todavía no hay sesión pero ayer sí,
/// la racha sigue viva y cuenta desde ayer. Devuelve 0 si no hay racha.
int calcularRacha(List<SesionEnfoque> sesiones, DateTime hoy) {
  final dias = {for (final sesion in sesiones) _diaDeSesion(sesion)};
  var dia = _soloFecha(hoy);
  if (!dias.contains(dia)) {
    dia = DateTime(dia.year, dia.month, dia.day - 1);
  }

  var racha = 0;
  while (dias.contains(dia)) {
    racha++;
    dia = DateTime(dia.year, dia.month, dia.day - 1);
  }
  return racha;
}

/// Horas estudiadas en cada día de la semana (lunes a domingo) que contiene [hoy].
List<double> horasPorDiaDeLaSemana(List<SesionEnfoque> sesiones, DateTime hoy) {
  final fechaHoy = _soloFecha(hoy);
  final lunes = DateTime(
    fechaHoy.year,
    fechaHoy.month,
    fechaHoy.day - (fechaHoy.weekday - 1),
  );

  return List.generate(7, (indice) {
    final dia = DateTime(lunes.year, lunes.month, lunes.day + indice);
    final segundos = sesiones
        .where((sesion) => _diaDeSesion(sesion) == dia)
        .fold<int>(0, (suma, sesion) => suma + sesion.duracionSegundos);
    return segundos / 3600;
  });
}

/// Índice del día con más horas; el primero si hay empate; `null` si todo es 0.
int? indicePicoSemanal(List<double> horas) {
  int? indicePico;
  var maximo = 0.0;
  for (var i = 0; i < horas.length; i++) {
    if (horas[i] > maximo) {
      maximo = horas[i];
      indicePico = i;
    }
  }
  return indicePico;
}

/// Suma los segundos de las sesiones; con [materiaId] solo cuenta las de esa materia.
int segundosTotales(List<SesionEnfoque> sesiones, {String? materiaId}) {
  return sesiones
      .where((sesion) => materiaId == null || sesion.materiaId == materiaId)
      .fold<int>(0, (suma, sesion) => suma + sesion.duracionSegundos);
}

/// Formatea segundos como `0 min`, `15 s`, `45 min`, `1 h` o `2 h 30 min`.
///
/// Menos de un minuto se muestra en segundos; desde un minuto, los minutos se
/// redondean hacia abajo.
String formatearDuracion(int segundos) {
  if (segundos > 0 && segundos < 60) return '$segundos s';
  final minutosTotales = segundos ~/ 60;
  final horas = minutosTotales ~/ 60;
  final minutos = minutosTotales % 60;

  if (horas == 0) return '$minutos min';
  if (minutos == 0) return '$horas h';
  return '$horas h $minutos min';
}

/// Formatea horas con un decimal y sin `.0` cuando es entero (`2`, `2.5`).
String formatearHoras(double horas) {
  final texto = horas.toStringAsFixed(1);
  return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
}

/// Mejor intento de una materia: mayor proporción de aciertos; en empate, el más reciente.
IntentoQuiz? mejorIntento(List<IntentoQuiz> intentos, String materiaId) {
  IntentoQuiz? mejor;
  for (final intento in intentos.where((i) => i.materiaId == materiaId)) {
    if (mejor == null ||
        intento.proporcion > mejor.proporcion ||
        (intento.proporcion == mejor.proporcion &&
            intento.fecha.isAfter(mejor.fecha))) {
      mejor = intento;
    }
  }
  return mejor;
}
