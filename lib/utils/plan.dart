import '../models/evaluacion.dart';
import '../models/sesion_estudio.dart';

/// Nombres de los días de la semana, de lunes a domingo.
const List<String> _nombresDias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Nombres de los meses, de enero a diciembre.
const List<String> _nombresMeses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Devuelve solo la fecha (sin hora) de un momento, en hora local.
DateTime soloFecha(DateTime momento) =>
    DateTime(momento.year, momento.month, momento.day);

/// Días completos que faltan desde [hoy] hasta [fecha] (0 si es hoy, negativo si ya pasó).
int diasRestantes(DateTime fecha, DateTime hoy) {
  // Se compara en UTC para que un cambio de horario no altere la cuenta.
  final destino = DateTime.utc(fecha.year, fecha.month, fecha.day);
  final origen = DateTime.utc(hoy.year, hoy.month, hoy.day);
  return destino.difference(origen).inDays;
}

/// Texto de la cuenta regresiva: `Hoy`, `Mañana` o `En 5 días`.
String textoDiasRestantes(int dias) {
  if (dias <= 0) return 'Hoy';
  if (dias == 1) return 'Mañana';
  return 'En $dias días';
}

/// Fecha larga en español, por ejemplo `Jueves, 24 de septiembre`.
String formatearFechaLarga(DateTime fecha) {
  return '${_nombresDias[fecha.weekday - 1]}, ${fecha.day} de '
      '${_nombresMeses[fecha.month - 1]}';
}

/// Hora en formato de 12 horas, por ejemplo `4:05 PM`.
String formatearHora(DateTime momento) {
  final hora12 = momento.hour % 12 == 0 ? 12 : momento.hour % 12;
  final minutos = momento.minute.toString().padLeft(2, '0');
  return '$hora12:$minutos ${momento.hour < 12 ? 'AM' : 'PM'}';
}

/// Evaluaciones de hoy en adelante, la más cercana primero.
List<Evaluacion> evaluacionesPendientes(
  List<Evaluacion> evaluaciones,
  DateTime hoy,
) {
  final pendientes = [
    for (final evaluacion in evaluaciones)
      if (diasRestantes(evaluacion.fecha, hoy) >= 0) evaluacion,
  ];
  pendientes.sort((a, b) => a.fecha.compareTo(b.fecha));
  return pendientes;
}

/// Sesiones que empiezan el día [dia], de la más temprana a la más tarde.
List<SesionEstudio> sesionesDelDia(List<SesionEstudio> sesiones, DateTime dia) {
  final fecha = soloFecha(dia);
  final delDia = [
    for (final sesion in sesiones)
      if (soloFecha(sesion.inicio) == fecha) sesion,
  ];
  delDia.sort((a, b) => a.inicio.compareTo(b.inicio));
  return delDia;
}

/// Sesiones de los días posteriores a [hoy], de la más cercana a la más lejana.
List<SesionEstudio> sesionesProximas(
  List<SesionEstudio> sesiones,
  DateTime hoy,
) {
  final fecha = soloFecha(hoy);
  final proximas = [
    for (final sesion in sesiones)
      if (soloFecha(sesion.inicio).isAfter(fecha)) sesion,
  ];
  proximas.sort((a, b) => a.inicio.compareTo(b.inicio));
  return proximas;
}
