import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/materia.dart';
import '../models/modo_pomodoro.dart';
import '../providers/pomodoro_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formato_tiempo.dart';

/// Pantalla del temporizador Pomodoro.
///
/// Es solo una vista del [PomodoroProvider], que vive en toda la app: el tiempo
/// sigue corriendo aunque se salga de esta pantalla, y al volver se ve el avance.
/// Soporta los modos Enfoque, Descanso Corto y Descanso Largo (25, 5 y 15 minutos,
/// o 15, 5 y 10 segundos en el modo demostración).
class PomodoroScreen extends StatefulWidget {
  /// Materia con la que se abrió la pantalla; `null` si se abrió desde la pastilla de Inicio.
  final Materia? materia;

  const PomodoroScreen({super.key, this.materia});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  @override
  void initState() {
    super.initState();
    final materia = widget.materia;
    // Se hace después del primer cuadro: no se puede notificar durante la construcción.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pomodoro = context.read<PomodoroProvider>();
      if (materia != null) {
        // El provider lo ignora si ya hay un bloque activo (de esta u otra materia).
        pomodoro.seleccionarMateria(materia.id, materia.nombre);
      }
      // Se pide el permiso aquí, y no al iniciar, para no interrumpir el bloque.
      pomodoro.prepararAvisos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final pomodoro = context.watch<PomodoroProvider>();
    final modoActual = pomodoro.modo;
    final fraccionProgreso = pomodoro.segundosTotales > 0
        ? pomodoro.segundosRestantes / pomodoro.segundosTotales
        : 0.0;
    final materiaPedida = widget.materia;
    final hayOtraMateriaEnCurso =
        materiaPedida != null &&
        pomodoro.hayBloqueActivo &&
        pomodoro.materiaId != materiaPedida.id;

    final colorPrimarioModo = modoActual == ModoPomodoro.enfoque
        ? AppColors.primario
        : (modoActual == ModoPomodoro.descansoCorto
              ? const Color(0xFF00897B)
              : const Color(0xFF3949AB));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pomodoro.materiaNombre != null
              ? 'Pomodoro: ${pomodoro.materiaNombre}'
              : 'Temporizador Pomodoro',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hayOtraMateriaEnCurso) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Ya hay un Pomodoro en curso de "${pomodoro.materiaNombre}". '
                    'Termínalo o reinícialo para cambiar de materia.',
                    style: tema.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Selector visual de modalidades
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: esOscuro
                      ? const Color(0xFF23202B)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    for (final modo in ModoPomodoro.values)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => pomodoro.cambiarModo(modo),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: modoActual == modo
                                  ? (esOscuro
                                        ? colorPrimarioModo
                                        : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: modoActual == modo
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              modo.etiqueta,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: modoActual == modo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: modoActual == modo
                                    ? (esOscuro
                                          ? Colors.white
                                          : colorPrimarioModo)
                                    : (esOscuro
                                          ? Colors.white60
                                          : Colors.black54),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Círculo central animado con la cuenta regresiva en MM:SS
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: fraccionProgreso,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: esOscuro
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorPrimarioModo,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        modoActual.icono,
                        color: colorPrimarioModo,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatearCronometro(pomodoro.segundosRestantes),
                        style: tema.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 44,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pomodoro.corriendo ? 'En progreso...' : 'Pausado',
                        style: tema.textTheme.labelMedium?.copyWith(
                          color: pomodoro.corriendo
                              ? colorPrimarioModo
                              : (esOscuro ? Colors.white54 : Colors.black45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Contador visual de ciclos completados (Ciclo X de 4)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      color: AppColors.primario,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Ciclo ${(pomodoro.ciclosCompletados % 4) + 1} de 4',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Indicadores esféricos de ciclos
                    Row(
                      children: List.generate(4, (index) {
                        final activo = index < (pomodoro.ciclosCompletados % 4);
                        return Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: activo
                                ? AppColors.primario
                                : (esOscuro ? Colors.white24 : Colors.black12),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Controles del temporizador: Reiniciar, Iniciar/Pausa, Saltar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    key: const Key('pomodoro-reiniciar'),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: esOscuro
                          ? const Color(0xFF2E2A36)
                          : Colors.grey.withValues(alpha: 0.15),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 26),
                    tooltip: 'Reiniciar tiempo',
                    onPressed: pomodoro.reiniciar,
                  ),

                  const SizedBox(width: 24),

                  ElevatedButton(
                    key: const Key('pomodoro-iniciar-pausar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimarioModo,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                      elevation: 4,
                      shadowColor: colorPrimarioModo.withValues(alpha: 0.4),
                    ),
                    onPressed: pomodoro.alternar,
                    child: Icon(
                      pomodoro.corriendo
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                    ),
                  ),

                  const SizedBox(width: 24),

                  IconButton.filledTonal(
                    key: const Key('pomodoro-saltar'),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: esOscuro
                          ? const Color(0xFF2E2A36)
                          : Colors.grey.withValues(alpha: 0.15),
                    ),
                    icon: const Icon(Icons.skip_next_rounded, size: 26),
                    tooltip: 'Saltar bloque',
                    onPressed: pomodoro.saltar,
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
