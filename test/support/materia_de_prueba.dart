import 'package:flutter/material.dart';
import 'package:studybuddy_ia/models/materia.dart';
import 'package:studybuddy_ia/models/pregunta.dart';

/// Materia fija con un quiz de cinco preguntas, para probar las pantallas del quiz
/// sin pasar por la IA ni por el repositorio.
const Materia materiaConQuiz = Materia(
  id: 'mat_quiz',
  nombre: 'Arquitectura',
  subtitulo: '1 apunte',
  descripcion: '',
  icono: Icons.memory_rounded,
  colorInicio: Color(0xFF5E35B1),
  colorFin: Color(0xFF7E57C2),
  apuntes: [],
  preguntas: [
    Pregunta(
      id: 'p0',
      enunciado: '¿Cuántas etapas tiene el pipeline clásico de MIPS?',
      opciones: ['Cinco', 'Tres', 'Siete', 'Dos'],
      indiceRespuestaCorrecta: 0,
      explicacionIa: 'Son IF, ID, EX, MEM y WB.',
    ),
    Pregunta(
      id: 'p1',
      enunciado: '¿Qué técnica mitiga los riesgos de datos?',
      opciones: ['Paginación', 'Forwarding', 'Fragmentación', 'Polling'],
      indiceRespuestaCorrecta: 1,
      explicacionIa: 'El adelantamiento entrega el dato antes de escribirlo.',
    ),
    Pregunta(
      id: 'p2',
      enunciado: '¿Qué aprovecha la memoria caché?',
      opciones: ['El azar', 'La latencia', 'La localidad', 'El voltaje'],
      indiceRespuestaCorrecta: 2,
      explicacionIa: 'Aprovecha la localidad temporal y espacial.',
    ),
    Pregunta(
      id: 'p3',
      enunciado: '¿Qué significa LRU?',
      opciones: ['Last Read Unit', 'Low Rate Use', 'Linear Run', 'Least Recently Used'],
      indiceRespuestaCorrecta: 3,
      explicacionIa: 'Reemplaza el bloque que lleva más tiempo sin usarse.',
    ),
    Pregunta(
      id: 'p4',
      enunciado: '¿Qué mide el AMAT?',
      opciones: ['El tiempo medio de acceso', 'El voltaje', 'La temperatura', 'El ancho de banda'],
      indiceRespuestaCorrecta: 0,
      explicacionIa: 'Es el tiempo medio de acceso a memoria.',
    ),
  ],
);
