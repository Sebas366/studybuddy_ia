/// Longitud máxima permitida para el nombre de una materia.
const int maxNombreMateria = 60;

/// Longitud máxima permitida para el título de un apunte.
const int maxTituloApunte = 120;

/// Valida el nombre de una materia.
///
/// Devuelve `null` si es válido o el mensaje de error a mostrar al usuario.
String? validarNombreMateria(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Escribe el nombre de la materia.';
  }
  if (texto.length > maxNombreMateria) {
    return 'El nombre no puede pasar de $maxNombreMateria caracteres.';
  }
  return null;
}

/// Valida el título de un apunte.
///
/// Devuelve `null` si es válido o el mensaje de error a mostrar al usuario.
String? validarTituloApunte(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Escribe el título del apunte.';
  }
  if (texto.length > maxTituloApunte) {
    return 'El título no puede pasar de $maxTituloApunte caracteres.';
  }
  return null;
}

/// Valida el texto de un apunte.
///
/// Devuelve `null` si es válido o el mensaje de error a mostrar al usuario.
String? validarTextoApunte(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Escribe el texto del apunte.';
  }
  return null;
}

/// Longitud máxima permitida para el título de una evaluación o el tema de una sesión.
const int maxTextoPlan = 120;

/// Valida el título de una evaluación.
///
/// Devuelve `null` si es válido o el mensaje de error a mostrar al usuario.
String? validarTituloEvaluacion(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Escribe el nombre de la evaluación.';
  }
  if (texto.length > maxTextoPlan) {
    return 'El nombre no puede pasar de $maxTextoPlan caracteres.';
  }
  return null;
}

/// Valida el tema de una sesión de estudio.
///
/// Devuelve `null` si es válido o el mensaje de error a mostrar al usuario.
String? validarTemaSesion(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Escribe qué vas a estudiar.';
  }
  if (texto.length > maxTextoPlan) {
    return 'El tema no puede pasar de $maxTextoPlan caracteres.';
  }
  return null;
}
