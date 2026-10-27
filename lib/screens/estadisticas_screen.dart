import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intento_quiz.dart';
import '../models/materia.dart';
import '../providers/estadisticas_provider.dart';
import '../providers/materias_provider.dart';
import '../theme/app_colors.dart';
import '../utils/calculos_estadisticas.dart';

/// Pantalla de métricas y analítica de estudio para Edwin, con datos reales.
///
/// Muestra 3 tarjetas de indicadores (tiempo total, racha y quizzes), una gráfica
/// de barras de las horas de la semana actual construida con widgets nativos de
/// Flutter (sin paquetes de terceros) y el tiempo de estudio de cada materia real.
class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estadisticas = context.watch<EstadisticasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas y Rendimiento')),
      body: SafeArea(
        top: false,
        child: _construirCuerpo(context, estadisticas),
      ),
    );
  }

  /// Elige qué mostrar: carga, error con reintento o las estadísticas.
  Widget _construirCuerpo(
    BuildContext context,
    EstadisticasProvider estadisticas,
  ) {
    if (estadisticas.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estadisticas.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54),
              const SizedBox(height: 16),
              Text(estadisticas.error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                key: const Key('reintentar-estadisticas'),
                onPressed: estadisticas.cargar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return _construirEstadisticas(context, estadisticas);
  }

  Widget _construirEstadisticas(
    BuildContext context,
    EstadisticasProvider estadisticas,
  ) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final materias = context.watch<MateriasProvider>().materias;
    final sesiones = estadisticas.sesiones;
    final intentos = estadisticas.intentos;
    final ahora = DateTime.now();

    final racha = calcularRacha(sesiones, ahora);
    final horasSemana = horasPorDiaDeLaSemana(sesiones, ahora);
    final totalSemana = horasSemana.fold<double>(
      0,
      (suma, horas) => suma + horas,
    );
    final indicePico = indicePicoSemanal(horasSemana);
    final maxHoras = indicePico == null ? 1.0 : horasSemana[indicePico];
    final sinDatos = sesiones.isEmpty && intentos.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 3 MINI TARJETAS DE MÉTRICAS CLAVE ---
          Row(
            children: [
              Expanded(
                child: _construirMiniTarjeta(
                  context: context,
                  titulo: 'Tiempo',
                  valor: formatearDuracion(segundosTotales(sesiones)),
                  icono: Icons.timer_outlined,
                  colorTema: const Color(0xFF6750A4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _construirMiniTarjeta(
                  context: context,
                  titulo: 'Racha',
                  valor: racha == 1 ? '1 día' : '$racha días',
                  icono: Icons.local_fire_department_rounded,
                  colorTema: const Color(0xFFFF6D00),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _construirMiniTarjeta(
                  context: context,
                  titulo: 'Quizzes',
                  valor: '${intentos.length}',
                  icono: Icons.verified_rounded,
                  colorTema: const Color(0xFF00897B),
                ),
              ),
            ],
          ),

          if (sinDatos) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primario.withValues(
                  alpha: esOscuro ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Completa un bloque de enfoque del Pomodoro para ver tus estadísticas.',
              ),
            ),
          ],

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
                  color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.04),
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
                    Expanded(
                      child: Column(
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
                            'Total de ${formatearTiempoSemanal(totalSemana)} esta semana',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: esOscuro ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (indicePico != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primario.withValues(
                            alpha: esOscuro ? 0.25 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Pico: ${nombresDiasCortos[indicePico]} (${formatearPico(horasSemana[indicePico])})',
                          style: const TextStyle(
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
                      for (var i = 0; i < horasSemana.length; i++)
                        _construirBarraSemanal(
                          context: context,
                          dia: nombresDiasCortos[i],
                          horas: horasSemana[i],
                          maxHoras: maxHoras,
                          esPico: i == indicePico,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // --- ESTUDIO POR MATERIA ---
          Text(
            'Estudio por Materia',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),

          if (materias.isEmpty)
            Text(
              'Crea una materia para ver tu estudio por materia.',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: esOscuro ? Colors.white60 : Colors.black54,
              ),
            )
          else
            for (final materia in materias)
              _construirTarjetaMateria(
                context: context,
                materia: materia,
                segundos: segundosTotales(sesiones, materiaId: materia.id),
                mejorQuiz: mejorIntento(intentos, materia.id),
              ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Tarjeta con el tiempo estudiado y el mejor quiz de una materia.
  Widget _construirTarjetaMateria({
    required BuildContext context,
    required Materia materia,
    required int segundos,
    required IntentoQuiz? mejorQuiz,
  }) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
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
            color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: materia.coloresDegradado),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(materia.icono, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  materia.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatearDuracion(segundos),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: materia.colorInicio,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (mejorQuiz != null)
            Text(
              'Mejor quiz: ${mejorQuiz.aciertos}/${mejorQuiz.total}',
              style: tema.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: materia.colorInicio,
              ),
            ),
        ],
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
            child: Icon(icono, color: colorTema, size: 20),
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
          etiquetaBarra(horas),
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
                    colors: [Color(0xFF6750A4), Color(0xFF9C27B0)],
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
}
