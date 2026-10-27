import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/apunte.dart';
import '../models/materia.dart';
import '../widgets/aviso_ia_fase3.dart';

/// Pantalla para leer un apunte real: su título, fecha y texto.
///
/// Las ideas clave, los resúmenes y el quiz con IA no existen todavía para los
/// apuntes reales, así que en su lugar se muestra el [AvisoIaFase3].
class ApunteScreen extends StatelessWidget {
  /// Apunte que se muestra.
  final Apunte apunte;

  /// Materia a la que pertenece el apunte.
  final Materia materia;

  const ApunteScreen({
    super.key,
    required this.apunte,
    required this.materia,
  });

  /// Copia el título, la materia y el texto del apunte al portapapeles.
  Future<void> _copiar(BuildContext context) async {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apunte'),
        actions: [
          IconButton(
            tooltip: 'Copiar apunte',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copiar(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: materia.colorInicio
                                .withValues(alpha: esOscuro ? 0.25 : 0.15),
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

            const AvisoIaFase3(),
            const SizedBox(height: 20),

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
                onPressed: () => _copiar(context),
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
    );
  }
}
