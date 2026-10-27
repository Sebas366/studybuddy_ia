import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/apunte.dart';
import '../models/materia.dart';
import '../providers/materias_provider.dart';
import '../widgets/accion_card.dart';
import '../widgets/aviso_ia_fase3.dart';
import '../widgets/dialogo_confirmar_borrado.dart';
import '../widgets/formulario_materia.dart';
import 'apunte_screen.dart';
import 'formulario_apunte_screen.dart';
import 'resumen_ia_screen.dart';
import 'quiz_screen.dart';
import 'chat_tutor_screen.dart';
import 'pomodoro_screen.dart';

/// Acciones del menú de la cabecera de una materia real.
enum _AccionMateria { editar, borrar }

/// Acciones al mantener pulsado un apunte real.
enum _AccionApunte { editar, borrar }

/// Pantalla detallada de una materia seleccionada.
///
/// Dispone de cabecera con degradado distintivo, Hero en el icono,
/// cuadrícula 2x2 para herramientas de IA (Resumir, Quiz IA, Tutor IA, Pomodoro),
/// listado interactivo de apuntes y botón flotante de escaneo con IA.
///
/// Las materias de demostración (`esDemo`) se muestran tal cual. Las reales se
/// leen en vivo del [MateriasProvider] y permiten editar, borrar y gestionar apuntes.
class DetalleMateriaScreen extends StatefulWidget {
  /// Materia seleccionada cuyos datos se presentarán.
  final Materia materia;

  const DetalleMateriaScreen({
    super.key,
    required this.materia,
  });

  @override
  State<DetalleMateriaScreen> createState() => _DetalleMateriaScreenState();
}

class _DetalleMateriaScreenState extends State<DetalleMateriaScreen> {
  /// Evita cerrar la pantalla más de una vez cuando la materia deja de existir.
  bool _cerrando = false;

  /// Atiende el menú de la cabecera: editar o borrar la materia real.
  Future<void> _alElegirAccionMateria(
      _AccionMateria accion, Materia materia) async {
    switch (accion) {
      case _AccionMateria.editar:
        await mostrarFormularioMateria(context, materia: materia);
      case _AccionMateria.borrar:
        final provider = context.read<MateriasProvider>();
        final confirmado = await confirmarBorrado(
          context,
          titulo: 'Borrar materia',
          mensaje: mensajeBorradoMateria(materia.nombre, materia.apuntes.length),
        );
        // La pantalla se cierra sola cuando la materia desaparece del provider.
        if (confirmado) await provider.borrarMateria(materia.id);
    }
  }

  /// Abre el formulario para crear un apunte nuevo en la materia.
  void _crearApunte(Materia materia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioApunteScreen(materiaId: materia.id),
      ),
    );
  }

  /// Abre la hoja con las opciones "Editar" y "Borrar" de un apunte real.
  Future<void> _mostrarOpcionesApunte(Apunte apunte) async {
    final accion = await showModalBottomSheet<_AccionApunte>(
      context: context,
      builder: (contextHoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('opcion-editar-apunte'),
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar'),
              onTap: () => Navigator.pop(contextHoja, _AccionApunte.editar),
            ),
            ListTile(
              key: const Key('opcion-borrar-apunte'),
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Borrar'),
              onTap: () => Navigator.pop(contextHoja, _AccionApunte.borrar),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accion == null) return;

    switch (accion) {
      case _AccionApunte.editar:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormularioApunteScreen(
              materiaId: apunte.materiaId,
              apunte: apunte,
            ),
          ),
        );
      case _AccionApunte.borrar:
        final provider = context.read<MateriasProvider>();
        final confirmado = await confirmarBorrado(
          context,
          titulo: 'Borrar apunte',
          mensaje:
              'Se borrará "${apunte.titulo}". Esta acción no se puede deshacer.',
        );
        if (confirmado) await provider.borrarApunte(apunte.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Las materias reales se leen en vivo; si ya no existen, se cierra la pantalla.
    var materia = widget.materia;
    if (!materia.esDemo) {
      final viva = context.watch<MateriasProvider>().porId(materia.id);
      if (viva == null) {
        if (!_cerrando) {
          _cerrando = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).maybePop();
          });
        }
        return const Scaffold();
      }
      materia = viva;
    }

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
              actions: [
                // Solo las materias reales se pueden editar o borrar
                if (!materia.esDemo)
                  PopupMenuButton<_AccionMateria>(
                    key: const Key('menu-materia'),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    onSelected: (accion) =>
                        _alElegirAccionMateria(accion, materia),
                    itemBuilder: (contextMenu) => const [
                      PopupMenuItem(
                        key: Key('menu-editar-materia'),
                        value: _AccionMateria.editar,
                        child: Text('Editar materia'),
                      ),
                      PopupMenuItem(
                        key: Key('menu-borrar-materia'),
                        value: _AccionMateria.borrar,
                        child: Text('Borrar materia'),
                      ),
                    ],
                  ),
              ],
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
                      // El progreso real llega en la Parte 2; solo las materias demo lo muestran
                      if (materia.esDemo) ...[
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
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
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
                            if (!materia.esDemo) {
                              mostrarAvisoIaFase3(context);
                              return;
                            }
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
                          subtitulo: materia.esDemo
                              ? '${materia.preguntas.length} preguntas'
                              : 'Próximamente',
                          icono: Icons.quiz_rounded,
                          colorTema: const Color(0xFFE65100),
                          onTap: () {
                            if (!materia.esDemo) {
                              mostrarAvisoIaFase3(context);
                              return;
                            }
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
                            if (!materia.esDemo) {
                              mostrarAvisoIaFase3(context);
                              return;
                            }
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
                      if (materia.esDemo)
                        Text(
                          'Toca para ver el resumen',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: esOscuro ? Colors.white54 : Colors.black45,
                          ),
                        )
                      else
                        TextButton.icon(
                          key: const Key('nuevo-apunte'),
                          onPressed: () => _crearApunte(materia),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Nuevo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  if (!materia.esDemo && materia.apuntes.isNotEmpty)
                    Text(
                      'Mantén pulsado un apunte para editar o borrar',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: esOscuro ? Colors.white54 : Colors.black45,
                      ),
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
                      child: Center(
                        child: Text(
                          materia.esDemo
                              ? 'No hay apuntes cargados aún. Usa el botón "Escanear" para agregar.'
                              : 'Aún no tienes apuntes. Toca "+ Nuevo" para crear el primero.',
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
                                materia.esDemo
                                    ? '${apunte.fecha} • ${apunte.ideasClave.length} ideas clave'
                                    : apunte.fecha,
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
                            // Los apuntes de demostración abren el resumen simulado;
                            // los reales, su texto con el aviso de IA.
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => materia.esDemo
                                      ? ResumenIaScreen(
                                          apunte: apunte,
                                          materia: materia,
                                        )
                                      : ApunteScreen(
                                          apunte: apunte,
                                          materia: materia,
                                        ),
                                ),
                              );
                            },
                            onLongPress: materia.esDemo
                                ? null
                                : () => _mostrarOpcionesApunte(apunte),
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
