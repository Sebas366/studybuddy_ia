import 'package:flutter/material.dart';
import '../models/materia.dart';
import '../widgets/accion_card.dart';
import 'resumen_ia_screen.dart';
import 'quiz_screen.dart';
import 'chat_tutor_screen.dart';
import 'pomodoro_screen.dart';

/// Pantalla detallada de una materia seleccionada.
///
/// Dispone de cabecera con degradado distintivo, Hero en el icono,
/// cuadrícula 2x2 para herramientas de IA (Resumir, Quiz IA, Tutor IA, Pomodoro),
/// listado interactivo de apuntes y botón flotante de escaneo con IA.
class DetalleMateriaScreen extends StatelessWidget {
  /// Materia seleccionada cuyos datos se presentarán.
  final Materia materia;

  const DetalleMateriaScreen({
    super.key,
    required this.materia,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Requisito: Botón flotante "Escanear" que solo muestra un SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de escaneo de apuntes con IA próximamente...'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: materia.colorInicio,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text(
          'Escanear',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // --- CABECERA CON DEGRADADO Y HERO ---
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: materia.coloresDegradado,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 75, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'icono-${materia.id}',
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                materia.icono,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  materia.nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  materia.subtitulo,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Barra de progreso dentro del banner
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: materia.progreso,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(materia.progreso * 100).toInt()}% dominado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- CUADRÍCULA 2X2 DE ACCIONES IA ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Herramientas de Estudio',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.25,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Acción 1: Resumir
                        AccionCard(
                          titulo: 'Resumir',
                          subtitulo: 'Ideas clave y síntesis',
                          icono: Icons.auto_awesome_rounded,
                          colorTema: const Color(0xFF6750A4),
                          onTap: () {
                            if (materia.apuntes.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResumenIaScreen(
                                    apunte: materia.apuntes.first,
                                    materia: materia,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No hay apuntes disponibles para resumir.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),

                        // Acción 2: Quiz IA
                        AccionCard(
                          titulo: 'Quiz IA',
                          subtitulo: '${materia.preguntas.length} preguntas',
                          icono: Icons.quiz_rounded,
                          colorTema: const Color(0xFFE65100),
                          onTap: () {
                            if (materia.preguntas.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuizScreen(materia: materia),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No hay preguntas configuradas para esta materia.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),

                        // Acción 3: Tutor IA
                        AccionCard(
                          titulo: 'Tutor IA',
                          subtitulo: 'Resuelve tus dudas',
                          icono: Icons.support_agent_rounded,
                          colorTema: const Color(0xFF00897B),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatTutorScreen(materia: materia),
                              ),
                            );
                          },
                        ),

                        // Acción 4: Pomodoro
                        AccionCard(
                          titulo: 'Pomodoro',
                          subtitulo: 'Sesión de 25 min',
                          icono: Icons.timer_rounded,
                          colorTema: const Color(0xFFD81B60),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PomodoroScreen(materia: materia),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- LISTA DE APUNTES ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Apuntes y Temas (${materia.apuntes.length})',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Toca para ver el resumen',
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: esOscuro ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (materia.apuntes.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: esOscuro
                            ? const Color(0xFF23202B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay apuntes cargados aún. Usa el botón "Escanear" para agregar.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ] else ...[
                    for (final apunte in materia.apuntes)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: esOscuro
                              ? const Color(0xFF23202B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: esOscuro
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: esOscuro ? 0.25 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: materia.colorInicio
                                    .withValues(alpha: esOscuro ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.article_rounded,
                                color: materia.colorInicio,
                              ),
                            ),
                            title: Text(
                              apunte.titulo,
                              style: tema.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${apunte.fecha} • ${apunte.ideasClave.length} ideas clave',
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: esOscuro
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResumenIaScreen(
                                    apunte: apunte,
                                    materia: materia,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
