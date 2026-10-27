/// Longitud máxima permitida para el nombre de un semestre.
const int maxSemestre = 20;

/// Semestre académico que corresponde a una [fecha], con formato `AAAA-N`.
///
/// De enero a junio es el semestre 1 y de julio a diciembre el semestre 2.
String semestreActual(DateTime fecha) {
  return '${fecha.year}-${fecha.month <= 6 ? 1 : 2}';
}

/// Valida el nombre de un semestre.
///
/// Devuelve `null` si es válido o el mensaje de error a mostrar al usuario.
String? validarSemestre(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Escribe el semestre.';
  }
  if (texto.length > maxSemestre) {
    return 'El semestre no puede pasar de $maxSemestre caracteres.';
  }
  return null;
}
