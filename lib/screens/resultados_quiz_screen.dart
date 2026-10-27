import 'package:flutter/material.dart';
import '../models/materia.dart';
import '../theme/app_colors.dart';
import 'quiz_screen.dart';

/// Pantalla que presenta el veredicto final tras completar las 5 preguntas del quiz.
///
/// Muestra el porcentaje de aciertos en un círculo animado, un mensaje motivacional
/// calibrado según el resultado, y botones para reiniciar la prueba o volver a la materia.
class ResultadosQuizScreen extends StatelessWidget {
  /// Cantidad de preguntas respondidas correctamente.
  final int correctas;

  /// Total de preguntas del quiz (usualmente 5).
  final int totalPreguntas;

  /// Puntos acumulados en la sesión.
  final int puntosTotales;

  /// Materia a la que pertenecía la autoevaluación.
  final Materia materia;

  const ResultadosQuizScreen({
    super.key,
    required this.correctas,
    required this.totalPreguntas,
    required this.puntosTotales,
    required this.materia,
  });

  /// Determina el mensaje y el icono motivacional según el desempeño del estudiante.
  (String, String, IconData, Color) _obtenerDiagnostico(double porcentaje) {
    if (porcentaje >= 1.0) {
      return (
        '¡Desempeño Perfecto! 🏆',
        '¡Felicidades, Edwin! Has respondido todo de manera impecable. Dominas completamente los temas de esta sesión.',
        Icons.workspace_premium_rounded,
        const Color(0xFF2E7D32),
      );
    } else if (porcentaje >= 0.8) {
      return (
        '¡Muy Buen Trabajo! 🌟',
        '¡Excelente comprensión! Tienes bases conceptuales sólidas. Un repaso breve a los apuntes terminará de pulir los detalles.',
        Icons.stars_rounded,
        AppColors.primario,
      );
    } else if (porcentaje >= 0.6) {
      return (
        '¡Buen Intento! 📚',
        'Aprobaste la evaluación. Revisa las explicaciones de la IA en las preguntas fallidas para reforzar los puntos débiles.',
        Icons.trending_up_rounded,
        const Color(0xFFED6C02),
      );
    } else {
      return (
        '¡A Seguir Practicando! 💪',
        'El aprendizaje es iterativo. Te recomendamos leer el Resumen IA de esta materia y probar nuevamente.',
        Icons.refresh_rounded,
        const Color(0xFFB3261E),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final porcentaje = totalPreguntas > 0 ? (correctas / totalPreguntas) : 0.0;
    final (tituloDiagnostico, mensajeDiagnostico, iconoDiagnostico, colorDiagnostico) =
        _obtenerDiagnostico(porcentaje);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Círculo animado con el porcentaje obtenido
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: porcentaje),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) {
                  final porcentajeTexto = '${(valor * 100).toInt()}%';

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: valor,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          backgroundColor: esOscuro
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.07),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorDiagnostico,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconoDiagnostico,
                            color: colorDiagnostico,
                            size: 34,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            porcentajeTexto,
                            style: tema.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                          Text(
                            '$correctas de $totalPreguntas',
                            style: tema.textTheme.labelMedium?.copyWith(
                              color: esOscuro ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Tarjeta con veredicto motivacional de la IA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colorDiagnostico.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorDiagnostico.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      tituloDiagnostico,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorDiagnostico,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mensajeDiagnostico,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        height: 1.5,
                        color: esOscuro ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tarjetas de estadísticas de la sesión
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: esOscuro
                            ? const Color(0xFF23202B)
                            : const Color(0xFFF3EDF7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Color(0xFFFFA000),
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '+$puntosTotales',
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Puntos ganados',
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: esOscuro ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: esOscuro
                            ? const Color(0xFF23202B)
                            : const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32),
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$correctas / $totalPreguntas',
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Aciertos netos',
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: esOscuro ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Botones de acción: Repetir Quiz y Volver
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    // Reiniciar quiz reemplazando la ruta
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(materia: materia),
                      ),
                    );
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text(
                    'Repetir quiz',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    side: BorderSide(
                      color: esOscuro ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Volver a la materia',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
