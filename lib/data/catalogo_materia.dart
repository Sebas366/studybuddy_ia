import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lista corta de degradados e iconos que el usuario puede elegir para una materia.
///
/// En la base de datos solo se guarda el índice del degradado y la clave del
/// icono; este catálogo los traduce a colores e [IconData] de Flutter.
class CatalogoMateria {
  CatalogoMateria._();

  /// Degradados disponibles (color inicial y color final), en orden de elección.
  static const List<List<Color>> degradados = [
    AppColors.degradadoArquitectura,
    AppColors.degradadoIaDatos,
    AppColors.degradadoDesarrolloMovil,
    [Color(0xFFC2185B), Color(0xFFF06292)],
    [Color(0xFF512DA8), Color(0xFF9575CD)],
    [Color(0xFF2E7D32), Color(0xFF81C784)],
  ];

  /// Iconos disponibles, indexados por su clave estable de almacenamiento.
  static const Map<String, IconData> iconos = {
    'memoria': Icons.memory_rounded,
    'cerebro': Icons.psychology_rounded,
    'movil': Icons.smartphone_rounded,
    'red': Icons.lan_rounded,
    'balanza': Icons.balance_rounded,
    'codigo': Icons.code_rounded,
    'libro': Icons.auto_stories_rounded,
  };

  /// Clave del icono que se usa cuando no se elige ninguno.
  static const String iconoPorDefecto = 'libro';

  /// Devuelve el degradado del [indice]; si está fuera de rango, el primero.
  static List<Color> degradadoPorIndice(int indice) {
    if (indice < 0 || indice >= degradados.length) {
      return degradados.first;
    }
    return degradados[indice];
  }

  /// Devuelve el icono de la [clave]; si no existe, el icono por defecto.
  static IconData iconoPorClave(String clave) {
    return iconos[clave] ?? iconos[iconoPorDefecto]!;
  }
}
