import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ia_provider.dart';
import '../providers/materias_provider.dart';
import '../services/servicio_ia.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogo_clave_ia.dart';
import '../widgets/estado_ia.dart';
import 'quiz_screen.dart';

/// Antesala del quiz de una materia.
///
/// Si la materia ya tiene un quiz guardado, ofrece empezarlo o generar
/// preguntas nuevas. Si no tiene, le pide a la IA que lo cree a partir de los
/// apuntes y lo guarda, para poder repetirlo después sin conexión.
class PrepararQuizScreen extends StatefulWidget {
  /// Materia de la que se hará el quiz.
  final String materiaId;

  /// Si es `true`, genera preguntas nuevas al abrir aunque ya haya un quiz guardado.
  final bool regenerar;

  const PrepararQuizScreen({
    super.key,
    required this.materiaId,
    this.regenerar = false,
  });

  @override
  State<PrepararQuizScreen> createState() => _PrepararQuizScreenState();
}

class _PrepararQuizScreenState extends State<PrepararQuizScreen> {
  /// Cantidad de preguntas que se le piden a la IA.
  static const int _cantidadPreguntas = 5;

  /// `true` mientras la IA escribe las preguntas.
  bool _generando = false;

  /// Mensaje del último error de la IA; `null` si no hubo.
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final materia = context.read<MateriasProvider>().porId(widget.materiaId);
      if (materia == null) return;
      if (materia.preguntas.isEmpty || widget.regenerar) _generar();
    });
  }

  /// Pide un quiz nuevo a la IA y lo guarda en la materia.
  Future<void> _generar() async {
    if (_generando) return;
    final provider = context.read<MateriasProvider>();
    final ia = context.read<IaProvider>();
    final materia = provider.porId(widget.materiaId);
    if (materia == null) return;
    if (materia.apuntes.isEmpty) {
      setState(
        () => _error = 'Agrega un apunte para que la IA pueda crear el quiz.',
      );
      return;
    }

    if (!await asegurarClaveIa(context)) {
      if (mounted) {
        setState(() => _error = const ErrorIa.sinClave().mensaje);
      }
      return;
    }
    if (!mounted) return;

    setState(() {
      _generando = true;
      _error = null;
    });
    try {
      final preguntas = await ia.servicio.generarQuiz(
        materia: materia.nombre,
        apuntes: materia.apuntes,
        cantidad: _cantidadPreguntas,
      );
      await provider.guardarPreguntas(materia.id, preguntas);
    } on ErrorIa catch (fallo) {
      _error = fallo.mensaje;
    } catch (_) {
      _error = 'No se pudo guardar el quiz. Inténtalo de nuevo.';
    }
    if (mounted) setState(() => _generando = false);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final materia = context.watch<MateriasProvider>().porId(widget.materiaId);
    if (materia == null) {
      // La materia se borró mientras la pantalla estaba abierta.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }

    final Widget cuerpo;
    if (_generando) {
      cuerpo = const CargandoIa(mensaje: 'Creando tu quiz con IA...');
    } else if (materia.preguntas.isEmpty) {
      cuerpo = ErrorDeIa(
        mensaje: _error ?? 'Esta materia todavía no tiene quiz.',
        onReintentar: _generar,
      );
    } else {
      cuerpo = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  size: 46,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Tu quiz está listo',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${materia.preguntas.length} preguntas de opción múltiple, '
                'creadas por la IA a partir de tus apuntes de '
                '${materia.nombre}.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('empezar-quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(materia: materia),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Empezar quiz',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('generar-quiz-nuevo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _generar,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    'Generar preguntas nuevas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${materia.nombre}')),
      body: SafeArea(top: false, child: cuerpo),
    );
  }
}
