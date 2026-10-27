import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/apunte.dart';
import '../models/materia.dart';
import '../theme/app_colors.dart';
import 'quiz_screen.dart';

/// Nivel de profundidad del resumen generado por la IA.
enum NivelResumen { corto, medio, detallado }

/// Pantalla que presenta el resumen estructurado de un apunte asistido por IA.
///
/// Incluye un [SegmentedButton] con tres niveles de detalle (Corto, Medio, Detallado),
/// tarjetas numeradas para las 4 ideas clave y acciones para copiar o generar un quiz.
class ResumenIaScreen extends StatefulWidget {
  /// Apunte seleccionado para visualizar su síntesis.
  final Apunte apunte;

  /// Materia a la que pertenece el apunte.
  final Materia materia;

  const ResumenIaScreen({
    super.key,
    required this.apunte,
    required this.materia,
  });

  @override
  State<ResumenIaScreen> createState() => _ResumenIaScreenState();
}

class _ResumenIaScreenState extends State<ResumenIaScreen> {
  /// Nivel de resumen actualmente seleccionado en el SegmentedButton.
  Set<NivelResumen> _seleccionResumen = {NivelResumen.medio};

  /// Obtiene el texto correspondiente según el nivel de resumen activo.
  String get _textoResumenActual {
    final nivel = _seleccionResumen.first;
    switch (nivel) {
      case NivelResumen.corto:
        return widget.apunte.resumenCorto;
      case NivelResumen.medio:
        return widget.apunte.resumenMedio;
      case NivelResumen.detallado:
        return widget.apunte.resumenDetallado;
    }
  }

  /// Copia el resumen actual y las ideas clave al portapapeles del dispositivo.
  Future<void> _copiarAlPortapapeles() async {
    final contenidoCompleto = StringBuffer()
      ..writeln('📌 ${widget.apunte.titulo}')
      ..writeln('Materia: ${widget.materia.nombre}')
      ..writeln('\n--- Resumen IA (${_seleccionResumen.first.name.toUpperCase()}) ---')
      ..writeln(_textoResumenActual)
      ..writeln('\n--- Ideas Clave ---');

    for (var i = 0; i < widget.apunte.ideasClave.length; i++) {
      contenidoCompleto.writeln('${i + 1}. ${widget.apunte.ideasClave[i]}');
    }

    await Clipboard.setData(ClipboardData(text: contenidoCompleto.toString()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('¡Resumen copiado al portapapeles!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Inteligente'),
        actions: [
          IconButton(
            tooltip: 'Copiar resumen',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copiarAlPortapapeles,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con título del apunte y etiqueta de la materia
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: esOscuro ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.materia.colorInicio
                              .withValues(alpha: esOscuro ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.materia.nombre,
                          style: TextStyle(
                            color: widget.materia.colorInicio,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.apunte.fecha,
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: esOscuro ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.apunte.titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Selector interactivo de nivel de profundidad (SegmentedButton)
            Center(
              child: SegmentedButton<NivelResumen>(
                segments: const [
                  ButtonSegment<NivelResumen>(
                    value: NivelResumen.corto,
                    label: Text('Corto'),
                    icon: Icon(Icons.flash_on_rounded, size: 16),
                  ),
                  ButtonSegment<NivelResumen>(
                    value: NivelResumen.medio,
                    label: Text('Medio'),
                    icon: Icon(Icons.menu_book_rounded, size: 16),
                  ),
                  ButtonSegment<NivelResumen>(
                    value: NivelResumen.detallado,
                    label: Text('Detallado'),
                    icon: Icon(Icons.auto_awesome_rounded, size: 16),
                  ),
                ],
                selected: _seleccionResumen,
                onSelectionChanged: (nuevaSeleccion) {
                  setState(() {
                    _seleccionResumen = nuevaSeleccion;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Tarjeta con el texto del resumen generado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: esOscuro
                    ? AppColors.primario.withValues(alpha: 0.12)
                    : const Color(0xFFF3EDF7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primario
                      .withValues(alpha: esOscuro ? 0.35 : 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology_rounded,
                        color: AppColors.primario,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Síntesis generada por IA',
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primario,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _textoResumenActual,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
                      height: 1.55,
                      color: esOscuro ? Colors.white : const Color(0xFF2B2533),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Sección de Ideas Clave (las 4 ideas de estudio)
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFFFA000),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ideas Clave (${widget.apunte.ideasClave.length})',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Iteración de las ideas clave en tarjetas numeradas
            for (var i = 0; i < widget.apunte.ideasClave.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: esOscuro ? 0.25 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.materia.colorInicio
                            .withValues(alpha: esOscuro ? 0.3 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: widget.materia.colorInicio,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.apunte.ideasClave[i],
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Botones inferiores: Copiar y Crear Quiz
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: esOscuro ? Colors.white30 : Colors.black26,
                      ),
                    ),
                    onPressed: _copiarAlPortapapeles,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text(
                      'Copiar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuizScreen(materia: widget.materia),
                        ),
                      );
                    },
                    icon: const Icon(Icons.quiz_rounded, size: 18),
                    label: const Text(
                      'Crear quiz',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
