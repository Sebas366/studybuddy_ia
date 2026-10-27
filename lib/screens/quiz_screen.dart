import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/materia.dart';
import '../models/pregunta.dart';
import '../providers/estadisticas_provider.dart';
import '../theme/app_colors.dart';
import 'resultados_quiz_screen.dart';

/// Pantalla interactiva de evaluación tipo Quiz impulsada por IA.
///
/// Presenta 5 preguntas secuenciales con selección única, botón "Comprobar",
/// validación de colores verde/rojo, retroalimentación con la explicación de la IA,
/// puntos acumulativos y una barra de progreso animada.
class QuizScreen extends StatefulWidget {
  /// Materia de la cual se cargará el banco de preguntas.
  final Materia materia;

  const QuizScreen({super.key, required this.materia});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  /// Índice de la pregunta actualmente visible (base 0).
  int _indicePreguntaActual = 0;

  /// Opción seleccionada por el estudiante antes de comprobar.
  int? _opcionSeleccionada;

  /// Indica si la pregunta en curso ya fue verificada por el estudiante.
  bool _haComprobado = false;

  /// Contador de respuestas respondidas correctamente.
  int _respuestasCorrectas = 0;

  /// Puntos acumulados en la sesión (200 puntos por acierto).
  int _puntosTotales = 0;

  /// Evita guardar dos veces el mismo intento si se toca "Ver resultados" dos veces.
  bool _finalizado = false;

  /// Lista de preguntas a resolver.
  List<Pregunta> get _preguntas => widget.materia.preguntas;

  /// Pregunta activa actual.
  Pregunta get _preguntaActual => _preguntas[_indicePreguntaActual];

  /// Comprueba la respuesta seleccionada por el usuario.
  void _comprobarRespuesta() {
    if (_opcionSeleccionada == null || _haComprobado) return;

    final esCorrecta =
        _opcionSeleccionada == _preguntaActual.indiceRespuestaCorrecta;

    setState(() {
      _haComprobado = true;
      if (esCorrecta) {
        _respuestasCorrectas++;
        _puntosTotales += 200;
      }
    });
  }

  /// Avanza a la siguiente pregunta o navega a la pantalla de resultados si era la última.
  void _avanzarOSiguiente() {
    if (_indicePreguntaActual < _preguntas.length - 1) {
      setState(() {
        _indicePreguntaActual++;
        _opcionSeleccionada = null;
        _haComprobado = false;
      });
    } else {
      if (_finalizado) return;
      _finalizado = true;

      // Se guarda el resultado sin esperar: si falla, igual se muestran los resultados.
      unawaited(
        context.read<EstadisticasProvider>().registrarIntentoQuiz(
          materiaId: widget.materia.id,
          aciertos: _respuestasCorrectas,
          total: _preguntas.length,
        ),
      );

      // Reemplazamos la pantalla actual por la pantalla final de resultados
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultadosQuizScreen(
            correctas: _respuestasCorrectas,
            totalPreguntas: _preguntas.length,
            puntosTotales: _puntosTotales,
            materia: widget.materia,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final total = _preguntas.length;
    final progreso = total > 0 ? ((_indicePreguntaActual + 1) / total) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.materia.nombre}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFA000),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_puntosTotales pts',
                  style: const TextStyle(
                    color: Color(0xFFFFA000),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- BARRA DE PROGRESO ANIMADA SUPERIOR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pregunta ${_indicePreguntaActual + 1} de $total',
                        style: tema.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: esOscuro ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        '${(progreso * 100).toInt()}% completado',
                        style: tema.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primario,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: progreso),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      builder: (context, valor, _) {
                        return LinearProgressIndicator(
                          value: valor,
                          minHeight: 8,
                          backgroundColor: esOscuro
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.07),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primario,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENIDO DESPLAZABLE DEL QUIZ ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enunciado de la pregunta en tarjeta destacada
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: esOscuro
                            ? const Color(0xFF23202B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: esOscuro
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: esOscuro ? 0.3 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _preguntaActual.enunciado,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Elige la opción correcta:',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: esOscuro ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Opciones de respuesta con validación visual verde/rojo
                    for (var i = 0; i < _preguntaActual.opciones.length; i++)
                      _construirTarjetaOpcion(i),

                    // Explicación didáctica de la IA una vez comprobada la pregunta
                    if (_haComprobado) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: esOscuro
                              ? const Color(0xFF1E2822)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Explicación de la IA',
                                  style: tema.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _preguntaActual.explicacionIa,
                              style: tema.textTheme.bodyMedium?.copyWith(
                                fontSize: 13.5,
                                height: 1.45,
                                color: esOscuro
                                    ? Colors.white
                                    : const Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- BOTÓN PRINCIPAL DE ACCIÓN INFERIOR ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF1D1B20) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _haComprobado
                        ? AppColors.primario
                        : (_opcionSeleccionada != null
                              ? AppColors.primario
                              : (esOscuro ? Colors.white12 : Colors.grey[300])),
                    foregroundColor:
                        _haComprobado || _opcionSeleccionada != null
                        ? Colors.white
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _haComprobado
                      ? _avanzarOSiguiente
                      : (_opcionSeleccionada != null
                            ? _comprobarRespuesta
                            : null),
                  child: Text(
                    _haComprobado
                        ? (_indicePreguntaActual < _preguntas.length - 1
                              ? 'Siguiente pregunta'
                              : 'Ver resultados')
                        : 'Comprobar respuesta',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye cada una de las opciones con estilos reactivos (seleccionada, acierto o fallo).
  Widget _construirTarjetaOpcion(int indice) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final esSeleccionada = _opcionSeleccionada == indice;
    final esCorrecta = indice == _preguntaActual.indiceRespuestaCorrecta;

    Color colorFondo = esOscuro ? const Color(0xFF23202B) : Colors.white;
    Color colorBorde = esOscuro
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);
    Widget? iconoEstado;

    if (_haComprobado) {
      if (esCorrecta) {
        colorFondo = esOscuro
            ? const Color(0xFF1B3B24)
            : const Color(0xFFE8F5E9);
        colorBorde = const Color(0xFF2E7D32);
        iconoEstado = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF2E7D32),
          size: 22,
        );
      } else if (esSeleccionada) {
        colorFondo = esOscuro
            ? const Color(0xFF3B1E1E)
            : const Color(0xFFFFEBEE);
        colorBorde = const Color(0xFFB3261E);
        iconoEstado = const Icon(
          Icons.cancel_rounded,
          color: Color(0xFFB3261E),
          size: 22,
        );
      }
    } else if (esSeleccionada) {
      colorFondo = AppColors.primario.withValues(alpha: esOscuro ? 0.2 : 0.08);
      colorBorde = AppColors.primario;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorBorde,
          width: esSeleccionada || (_haComprobado && esCorrecta) ? 1.8 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _haComprobado
              ? null
              : () {
                  setState(() {
                    _opcionSeleccionada = indice;
                  });
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Identificador letrado de opción (A, B, C, D)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: esSeleccionada
                        ? AppColors.primario
                        : (esOscuro ? Colors.white12 : Colors.black12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    String.fromCharCode(65 + indice), // A, B, C, D...
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: esSeleccionada ? Colors.white : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Texto de la opción
                Expanded(
                  child: Text(
                    _preguntaActual.opciones[indice],
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: esSeleccionada
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (iconoEstado != null) ...[
                  const SizedBox(width: 8),
                  iconoEstado,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
