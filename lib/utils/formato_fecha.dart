/// Abreviaturas de los meses en español, de enero a diciembre.
const List<String> _mesesAbreviados = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

/// Devuelve la fecha en formato legible, por ejemplo `27 Oct 2026`.
///
/// El día se muestra sin ceros a la izquierda.
String formatearFecha(DateTime fecha) {
  return '${fecha.day} ${_mesesAbreviados[fecha.month - 1]} ${fecha.year}';
}
