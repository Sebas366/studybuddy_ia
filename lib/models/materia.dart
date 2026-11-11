import 'package:flutter/material.dart';

import 'apunte.dart';
import 'pregunta.dart';

/// Representa una materia o asignatura del estudiante.
///
/// Agrupa los apuntes, las preguntas del último quiz generado y la
/// configuración visual (colores e icono para animaciones Hero).
class Materia {
  /// Identificador único de la materia.
  final String id;

  /// Nombre oficial de la materia.
  final String nombre;

  /// Subtítulo con el estado de la materia (ej. "3 apuntes").
  final String subtitulo;

  /// Descripción detallada de los contenidos o enfoque de la asignatura.
  final String descripcion;

  /// Icono representativo de la materia para uso en tarjetas y transiciones Hero.
  final IconData icono;

  /// Color inicial del degradado característico de la materia.
  final Color colorInicio;

  /// Color final del degradado característico de la materia.
  final Color colorFin;

  /// Lista de apuntes cargados y procesados para esta materia.
  final List<Apunte> apuntes;

  /// Último quiz que la IA generó para esta materia (vacío si aún no hay ninguno).
  final List<Pregunta> preguntas;

  /// Índice del degradado elegido en el catálogo de colores.
  final int colorIndice;

  /// Clave del icono elegido en el catálogo de iconos.
  final String iconoClave;

  /// Semestre al que pertenece la materia (ej. `2026-2`).
  final String semestre;

  const Materia({
    required this.id,
    required this.nombre,
    required this.subtitulo,
    required this.descripcion,
    required this.icono,
    required this.colorInicio,
    required this.colorFin,
    required this.apuntes,
    this.preguntas = const [],
    this.colorIndice = 0,
    this.iconoClave = 'libro',
    this.semestre = '',
  });

  /// Texto de subtítulo según la cantidad de apuntes (ej. "3 apuntes").
  static String subtituloPorConteo(int cantidad) {
    if (cantidad == 0) return 'Sin apuntes';
    if (cantidad == 1) return '1 apunte';
    return '$cantidad apuntes';
  }

  /// Devuelve la lista de colores del degradado para usar directamente en BoxDecoration.
  List<Color> get coloresDegradado => [colorInicio, colorFin];
}
