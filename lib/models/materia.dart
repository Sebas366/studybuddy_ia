import 'package:flutter/material.dart';
import 'apunte.dart';
import 'pregunta.dart';

/// Representa una materia o asignatura del estudiante.
///
/// Agrupa los apuntes, preguntas de quiz generadas, progreso del alumno
/// y configuraciones visuales (colores e icono para animaciones Hero).
class Materia {
  /// Identificador único de la materia.
  final String id;

  /// Nombre oficial de la materia.
  final String nombre;

  /// Subtítulo o resumen de estado de la materia (ej. "Laboratorios MIPS • 1 Quiz pendiente").
  final String subtitulo;

  /// Descripción detallada de los contenidos o enfoque de la asignatura.
  final String descripcion;

  /// Porcentaje de progreso de estudio entre 0.0 y 1.0.
  final double progreso;

  /// Icono representativo de la materia para uso en tarjetas y transiciones Hero.
  final IconData icono;

  /// Color inicial del degradado característico de la materia.
  final Color colorInicio;

  /// Color final del degradado característico de la materia.
  final Color colorFin;

  /// Lista de apuntes cargados y procesados para esta materia.
  final List<Apunte> apuntes;

  /// Banco de preguntas de evaluación generadas por la IA para esta materia.
  final List<Pregunta> preguntas;

  /// Respuestas simuladas que el Tutor IA utilizará al dialogar sobre esta materia.
  final List<String> respuestasSimuladasIa;

  const Materia({
    required this.id,
    required this.nombre,
    required this.subtitulo,
    required this.descripcion,
    required this.progreso,
    required this.icono,
    required this.colorInicio,
    required this.colorFin,
    required this.apuntes,
    required this.preguntas,
    required this.respuestasSimuladasIa,
  });

  /// Devuelve la lista de colores del degradado para usar directamente en BoxDecoration.
  List<Color> get coloresDegradado => [colorInicio, colorFin];
}
