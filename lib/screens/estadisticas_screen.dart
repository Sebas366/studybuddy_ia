import 'package:flutter/material.dart';
import '../data/datos_demo.dart';
import '../theme/app_colors.dart';

/// Pantalla de métricas y analítica de estudio para Edwin.
///
/// Incluye 3 mini tarjetas de indicadores clave, una gráfica de barras semanal
/// construida artesanalmente con widgets nativos de Flutter (sin paquetes de terceros)
/// y el desglose de avance porcentual por cada asignatura.
class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final metricas = DatosDemo.metricasEstadisticas;
    final diasSemanales = DatosDemo.horasSemanales;

    // Calculamos el valor máximo de horas para normalizar la altura de las barras
    final maxHoras = diasSemanales.fold<double>(
      0.0,
      (max, item) => (item['horas'] as double) > max ? (item['horas'] as double) : max,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas y Rendimiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 3 MINI TARJETAS DE MÉTRICAS CLAVE ---
            Row(
              children: [
                // Métrica 1: Horas de estudio
                Expanded(
                  child: _construirMiniTarjeta(
                    context: context,
                    titulo: 'Tiempo',
                    valor: metricas['horasEstudio'] ?? '0 h',
                    icono: Icons.timer_outlined,
                    colorTema: const Color(0xFF6750A4),
                  ),
                ),
                const SizedBox(width: 10),
                // Métrica 2: Racha de días
                Expanded(
                  child: _construirMiniTarjeta(
                    context: context,
                    titulo: 'Racha',
                    valor: metricas['rachaDias'] ?? '0 d',
                    icono: Icons.local_fire_department_rounded,
                    colorTema: const Color(0xFFFF6D00),
                  ),
                ),
                const SizedBox(width: 10),
                // Métrica 3: Quizzes superados
                Expanded(
                  child: _construirMiniTarjeta(
                    context: context,
                    titulo: 'Quizzes',
                    valor: metricas['quizzesCompletados'] ?? '0',
                    icono: Icons.verified_rounded,
                    colorTema: const Color(0xFF00897B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- GRÁFICA DE BARRAS SEMANAL (SIN PAQUETES EXTERNOS) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horas de Estudio Semanal',
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total de 14.5 horas esta semana',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: esOscuro ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primario
                              .withValues(alpha: esOscuro ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Pico: Jue (4h)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primario,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Área de barras dibujada puramente con widgets (Container, Column, Row)
                  SizedBox(
                    height: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final item in diasSemanales) ...[
                          _construirBarraSemanal(
                            context: context,
                            dia: item['dia'] as String,
                            horas: item['horas'] as double,
                            maxHoras: maxHoras > 0 ? maxHoras : 1.0,
                            esPico: (item['horas'] as double) == maxHoras,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- PROGRESO POR MATERIA ---
            Text(
              'Progreso por Materia',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),

            for (final materia in DatosDemo.materias) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: esOscuro ? 0.25 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: materia.coloresDegradado,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            materia.icono,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                materia.nombre,
                                style: tema.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _obtenerNivelDominio(materia.progreso),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: materia.colorInicio,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(materia.progreso * 100).toInt()}%',
                          style: tema.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: materia.colorInicio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: materia.progreso,
                        minHeight: 7,
                        backgroundColor: esOscuro
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          materia.colorInicio,
                        ),
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
    );
  }

  /// Construye una mini tarjeta métrica individual.
  Widget _construirMiniTarjeta({
    required BuildContext context,
    required String titulo,
    required String valor,
    required IconData icono,
    required Color colorTema,
  }) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF23202B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: esOscuro
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorTema.withValues(alpha: esOscuro ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icono,
              color: colorTema,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: tema.textTheme.labelSmall?.copyWith(
              color: esOscuro ? Colors.white60 : Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una columna de barra semanal proporcional a las horas estudiadas.
  Widget _construirBarraSemanal({
    required BuildContext context,
    required String dia,
    required double horas,
    required double maxHoras,
    required bool esPico,
  }) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Altura máxima reservada para la columna visual de la barra (ej. 110 px)
    const alturaMaximaCanvas = 110.0;
    final alturaCalculada = (horas / maxHoras) * alturaMaximaCanvas;
    final alturaFinal = alturaCalculada < 8.0 ? 8.0 : alturaCalculada;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Etiqueta con las horas encima de la barra
        Text(
          '${horas.toStringAsFixed(horas % 1 == 0 ? 0 : 1)}h',
          style: TextStyle(
            fontSize: 10,
            fontWeight: esPico ? FontWeight.bold : FontWeight.w500,
            color: esPico
                ? AppColors.primario
                : (esOscuro ? Colors.white54 : Colors.black45),
          ),
        ),
        const SizedBox(height: 6),
        // Barra física dibujada con Container
        Container(
          width: 22,
          height: alturaFinal,
          decoration: BoxDecoration(
            gradient: esPico
                ? const LinearGradient(
                    colors: [
                      Color(0xFF6750A4),
                      Color(0xFF9C27B0),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: esPico
                ? null
                : (esOscuro
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.primario.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        // Etiqueta del día de la semana
        Text(
          dia,
          style: tema.textTheme.labelSmall?.copyWith(
            fontWeight: esPico ? FontWeight.bold : FontWeight.normal,
            color: esPico
                ? (esOscuro ? Colors.white : AppColors.primario)
                : (esOscuro ? Colors.white60 : Colors.black54),
          ),
        ),
      ],
    );
  }

  /// Retorna un texto descriptivo del nivel alcanzado según el porcentaje.
  String _obtenerNivelDominio(double progreso) {
    if (progreso >= 0.8) return 'Nivel Avanzado';
    if (progreso >= 0.6) return 'Nivel Intermedio';
    if (progreso >= 0.3) return 'En Progreso';
    return 'Inicial';
  }
}
