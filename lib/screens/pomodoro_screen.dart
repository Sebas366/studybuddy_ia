import 'dart:async';
import 'package:flutter/material.dart';
import '../models/materia.dart';
import '../theme/app_colors.dart';

/// Modalidades de tiempo soportadas por la técnica Pomodoro.
enum ModoPomodoro {
  enfoque('Enfoque', 25 * 60, Icons.center_focus_strong_rounded),
  descansoCorto('Descanso Corto', 5 * 60, Icons.coffee_rounded),
  descansoLargo('Descanso Largo', 15 * 60, Icons.weekend_rounded);

  final String etiqueta;
  final int segundosTotales;
  final IconData icono;

  const ModoPomodoro(this.etiqueta, this.segundosTotales, this.icono);
}

/// Pantalla con temporizador Pomodoro 100% funcional.
///
/// Soporta los modos Enfoque (25 min), Descanso Corto (5 min) y Descanso Largo (15 min).
/// Permite pausar, reiniciar, saltar ciclos y contabilizar las rondas completadas.
/// Libera y cancela estrictamente su temporizador interno en [dispose].
class PomodoroScreen extends StatefulWidget {
  /// Materia opcional asociada a la sesión de enfoque.
  final Materia? materia;

  const PomodoroScreen({
    super.key,
    this.materia,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  /// Modo Pomodoro activo (por defecto Enfoque de 25 minutos).
  ModoPomodoro _modoActual = ModoPomodoro.enfoque;

  /// Segundos restantes de la cuenta regresiva.
  late int _segundosRestantes;

  /// Estado de ejecución del temporizador.
  bool _estaCorriendo = false;

  /// Contador de ciclos de enfoque completados (hasta 4 por ronda).
  int _ciclosCompletados = 0;

  /// Instancia del temporizador periódico de [dart:async].
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _segundosRestantes = _modoActual.segundosTotales;
  }

  @override
  void dispose() {
    // REQUISITO ESTRICTO: Cancelar el temporizador para prevenir fugas de memoria
    _temporizador?.cancel();
    super.dispose();
  }

  /// Inicia o pausa la cuenta regresiva del temporizador.
  void _alternarTemporizador() {
    if (_estaCorriendo) {
      _temporizador?.cancel();
      setState(() {
        _estaCorriendo = false;
      });
    } else {
      setState(() {
        _estaCorriendo = true;
      });

      _temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_segundosRestantes > 0) {
          setState(() {
            _segundosRestantes--;
          });
        } else {
          // El tiempo expiró
          _alCompletarTiempo();
        }
      });
    }
  }

  /// Maneja la finalización de un ciclo de tiempo.
  void _alCompletarTiempo() {
    _temporizador?.cancel();
    setState(() {
      _estaCorriendo = false;
    });

    if (_modoActual == ModoPomodoro.enfoque) {
      _ciclosCompletados++;
      // Notificación sonora o visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Excelente! Completaste el bloque de enfoque. '
            '${_ciclosCompletados % 4 == 0 ? "¡Hora de un descanso largo de 15 min!" : "Toma un descanso corto de 5 min."}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Auto-transición inteligente
      if (_ciclosCompletados % 4 == 0) {
        _cambiarModo(ModoPomodoro.descansoLargo);
      } else {
        _cambiarModo(ModoPomodoro.descansoCorto);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descanso terminado. ¡A concentrarse de nuevo!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cambiarModo(ModoPomodoro.enfoque);
    }
  }

  /// Cambia de modalidad manual o automáticamente, reiniciando la cuenta.
  void _cambiarModo(ModoPomodoro nuevoModo) {
    _temporizador?.cancel();
    setState(() {
      _modoActual = nuevoModo;
      _segundosRestantes = nuevoModo.segundosTotales;
      _estaCorriendo = false;
    });
  }

  /// Reinicia el contador del modo actual a su valor original.
  void _reiniciarTemporizador() {
    _temporizador?.cancel();
    setState(() {
      _segundosRestantes = _modoActual.segundosTotales;
      _estaCorriendo = false;
    });
  }

  /// Salta el bloque actual y avanza a la siguiente fase del ciclo.
  void _saltarBloque() {
    if (_modoActual == ModoPomodoro.enfoque) {
      _cambiarModo(ModoPomodoro.descansoCorto);
    } else {
      _cambiarModo(ModoPomodoro.enfoque);
    }
  }

  /// Formatea los segundos restantes en cadena "MM:SS".
  String _formatearTiempo(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final fraccionProgreso = _modoActual.segundosTotales > 0
        ? (_segundosRestantes / _modoActual.segundosTotales)
        : 0.0;

    final colorPrimarioModo = _modoActual == ModoPomodoro.enfoque
        ? AppColors.primario
        : (_modoActual == ModoPomodoro.descansoCorto
            ? const Color(0xFF00897B)
            : const Color(0xFF3949AB));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.materia != null
              ? 'Pomodoro: ${widget.materia!.nombre}'
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
                          onTap: () => _cambiarModo(modo),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _modoActual == modo
                                  ? (esOscuro
                                      ? colorPrimarioModo
                                      : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _modoActual == modo
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
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
                                fontWeight: _modoActual == modo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _modoActual == modo
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
                        _modoActual.icono,
                        color: colorPrimarioModo,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatearTiempo(_segundosRestantes),
                        style: tema.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 44,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _estaCorriendo ? 'En progreso...' : 'Pausado',
                        style: tema.textTheme.labelMedium?.copyWith(
                          color: _estaCorriendo
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                      'Ciclo ${(_ciclosCompletados % 4) + 1} de 4',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Indicadores esféricos de ciclos
                    Row(
                      children: List.generate(4, (index) {
                        final activo = index < (_ciclosCompletados % 4);
                        return Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: activo
                                ? AppColors.primario
                                : (esOscuro
                                    ? Colors.white24
                                    : Colors.black12),
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
                  // Botón Reiniciar
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: esOscuro
                          ? const Color(0xFF2E2A36)
                          : Colors.grey.withValues(alpha: 0.15),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 26),
                    tooltip: 'Reiniciar tiempo',
                    onPressed: _reiniciarTemporizador,
                  ),

                  const SizedBox(width: 24),

                  // Botón Iniciar / Pausar principal
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimarioModo,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                      elevation: 4,
                      shadowColor: colorPrimarioModo.withValues(alpha: 0.4),
                    ),
                    onPressed: _alternarTemporizador,
                    child: Icon(
                      _estaCorriendo
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Botón Saltar bloque
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: esOscuro
                          ? const Color(0xFF2E2A36)
                          : Colors.grey.withValues(alpha: 0.15),
                    ),
                    icon: const Icon(Icons.skip_next_rounded, size: 26),
                    tooltip: 'Saltar bloque',
                    onPressed: _saltarBloque,
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
