import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/apunte.dart';
import '../models/materia.dart';
import '../providers/materias_provider.dart';
import '../theme/app_colors.dart';
import 'resumen_ia_screen.dart';

/// Pantalla para leer un apunte: su título, fecha y texto, con acceso al
/// resumen que genera la IA.
///
/// El apunte se lee en vivo del [MateriasProvider], así que refleja de
/// inmediato si ya tiene resumen; si se borra, la pantalla se cierra.
class ApunteScreen extends StatelessWidget {
  /// Materia a la que pertenece el apunte.
  final String materiaId;

  /// Apunte que se muestra.
  final String apunteId;

  const ApunteScreen({
    super.key,
    required this.materiaId,
    required this.apunteId,
  });

  /// Copia el título, la materia y el texto del apunte al portapapeles.
  Future<void> _copiar(
    BuildContext context,
    Materia materia,
    Apunte apunte,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    final texto = StringBuffer()
      ..writeln('📌 ${apunte.titulo}')
      ..writeln('Materia: ${materia.nombre}')
      ..writeln('Fecha: ${apunte.fecha}')
      ..writeln()
      ..write(apunte.contenido);

    await Clipboard.setData(ClipboardData(text: texto.toString()));

    mensajero.showSnackBar(
      const SnackBar(
        content: Text('¡Apunte copiado al portapapeles!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final materia = context.watch<MateriasProvider>().porId(materiaId);
    Apunte? buscado;
    for (final candidato in materia?.apuntes ?? const <Apunte>[]) {
      if (candidato.id == apunteId) buscado = candidato;
    }
    final apunte = buscado;
    if (materia == null || apunte == null) {
      // El apunte o su materia se borraron mientras la pantalla estaba abierta.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apunte'),
        actions: [
          IconButton(
            tooltip: 'Copiar apunte',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copiar(context, materia, apunte),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con etiqueta de la materia, fecha y título
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: materia.colorInicio.withValues(
                                alpha: esOscuro ? 0.25 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              materia.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: materia.colorInicio,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          apunte.fecha,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: esOscuro ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      apunte.titulo,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Texto del apunte
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: SelectableText(
                  apunte.contenido,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.5,
                    height: 1.55,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Acceso al resumen con IA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('resumir-apunte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResumenIaScreen(
                        materiaId: materiaId,
                        apunteId: apunteId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    apunte.tieneResumen
                        ? 'Ver resumen con IA'
                        : 'Resumir con IA',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
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
                  onPressed: () => _copiar(context, materia, apunte),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Copiar',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
