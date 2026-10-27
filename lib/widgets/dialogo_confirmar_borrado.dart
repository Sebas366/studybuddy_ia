import 'package:flutter/material.dart';

/// Pide confirmación antes de borrar algo.
///
/// Devuelve `true` solo si el usuario pulsa "Borrar"; si pulsa "Cancelar" o
/// cierra el diálogo tocando fuera, devuelve `false`.
Future<bool> confirmarBorrado(
  BuildContext context, {
  required String titulo,
  required String mensaje,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contextDialogo) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contextDialogo, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(contextDialogo, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(contextDialogo).colorScheme.error,
          ),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}

/// Mensaje de confirmación para borrar una materia, con el conteo de apuntes
/// que se perderían (singular y plural correctos).
String mensajeBorradoMateria(String nombre, int cantidadApuntes) {
  final String apuntes;
  if (cantidadApuntes == 0) {
    apuntes = '';
  } else if (cantidadApuntes == 1) {
    apuntes = ' y su 1 apunte';
  } else {
    apuntes = ' y sus $cantidadApuntes apuntes';
  }
  return 'Se borrará "$nombre"$apuntes. Esta acción no se puede deshacer.';
}
