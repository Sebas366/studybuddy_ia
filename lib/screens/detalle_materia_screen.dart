import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/apunte.dart';
import '../models/materia.dart';
import '../models/modo_pomodoro.dart';
import '../providers/estadisticas_provider.dart';
import '../providers/ia_provider.dart';
import '../providers/materias_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/selector_imagen.dart';
import '../services/servicio_ia.dart';
import '../utils/calculos_estadisticas.dart';
import '../widgets/accion_card.dart';
import '../widgets/dialogo_clave_ia.dart';
import '../widgets/dialogo_confirmar_borrado.dart';
import '../widgets/formulario_materia.dart';
import 'apunte_screen.dart';
import 'chat_tutor_screen.dart';
import 'formulario_apunte_screen.dart';
import 'pomodoro_screen.dart';
import 'preparar_quiz_screen.dart';
import 'resumen_ia_screen.dart';

/// Acciones del menú de la cabecera de una materia.
enum _AccionMateria { editar, borrar }

/// Acciones al mantener pulsado un apunte.
enum _AccionApunte { editar, borrar }

/// Pantalla detallada de una materia seleccionada.
///
/// Dispone de cabecera con degradado distintivo, Hero en el icono,
/// cuadrícula 2x2 de herramientas (Resumir, Quiz IA, Tutor IA, Pomodoro),
/// listado de apuntes y botón flotante para escanear un apunte con la cámara.
///
/// La materia se lee en vivo del [MateriasProvider], así que la pantalla se
/// actualiza sola al editarla y se cierra si se borra.
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

  /// Evita lanzar dos escaneos a la vez.
  bool _escaneando = false;

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  /// Abre el resumen de un apunte; si la materia tiene varios, deja elegir cuál.
  Future<void> _resumir(Materia materia) async {
    if (materia.apuntes.isEmpty) {
      _avisar('Agrega un apunte para poder resumirlo.');
      return;
    }
    var apunte = materia.apuntes.first;
    if (materia.apuntes.length > 1) {
      final elegido = await showModalBottomSheet<Apunte>(
        context: context,
        builder: (contextHoja) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  '¿Qué apunte quieres resumir?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final opcion in materia.apuntes)
                ListTile(
                  leading: Icon(
                    opcion.tieneResumen
                        ? Icons.auto_awesome_rounded
                        : Icons.article_rounded,
                  ),
                  title: Text(opcion.titulo),
                  subtitle: Text(
                    opcion.tieneResumen ? 'Resumen listo' : opcion.fecha,
                  ),
                  onTap: () => Navigator.pop(contextHoja, opcion),
                ),
            ],
          ),
        ),
      );
      if (!mounted || elegido == null) return;
      apunte = elegido;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResumenIaScreen(materiaId: materia.id, apunteId: apunte.id),
      ),
    );
  }

  /// Abre el quiz de la materia (lo genera con IA si aún no existe).
  void _abrirQuiz(Materia materia) {
    if (materia.apuntes.isEmpty && materia.preguntas.isEmpty) {
      _avisar('Agrega un apunte para que la IA pueda crear el quiz.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrepararQuizScreen(materiaId: materia.id),
      ),
    );
  }

  /// Abre el chat con el tutor, pidiendo antes la clave de IA si falta.
  Future<void> _abrirTutor(Materia materia) async {
    if (!await asegurarClaveIa(context)) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatTutorScreen(materiaId: materia.id),
      ),
    );
  }

  /// Toma o elige una foto, la transcribe con IA y abre el apunte para revisarlo.
  Future<void> _escanear(Materia materia) async {
    if (_escaneando) return;
    if (!await asegurarClaveIa(context)) return;
    if (!mounted) return;

    final origen = await showModalBottomSheet<OrigenImagen>(
      context: context,
      builder: (contextHoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('escanear-camara'),
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(contextHoja, OrigenImagen.camara),
            ),
            ListTile(
              key: const Key('escanear-galeria'),
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(contextHoja, OrigenImagen.galeria),
            ),
          ],
        ),
      ),
    );
    if (!mounted || origen == null) return;

    final selector = context.read<SelectorImagen>();
    final ia = context.read<IaProvider>();
    final navegador = Navigator.of(context);
    _escaneando = true;
    try {
      final imagen = await selector.elegir(origen);
      if (!mounted || imagen == null) return;

      // Diálogo de espera que no se puede cerrar mientras la IA lee la foto.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(child: Text('Leyendo tu apunte con IA...')),
              ],
            ),
          ),
        ),
      );

      String? error;
      try {
        final escaneado = await ia.servicio.transcribirImagen(
          imagen: imagen.bytes,
          tipoMime: imagen.tipoMime,
          materia: materia.nombre,
        );
        navegador.pop(); // cierra el diálogo de espera
        await navegador.push(
          MaterialPageRoute(
            builder: (context) => FormularioApunteScreen(
              materiaId: materia.id,
              tituloInicial: escaneado.titulo,
              contenidoInicial: escaneado.contenido,
            ),
          ),
        );
        return;
      } on ErrorIa catch (fallo) {
        error = fallo.mensaje;
      } catch (_) {
        error = 'No se pudo leer la foto. Inténtalo de nuevo.';
      }
      navegador.pop(); // cierra el diálogo de espera
      if (mounted) _avisar(error);
    } catch (_) {
      if (mounted) _avisar('No se pudo abrir la cámara o la galería.');
    } finally {
      _escaneando = false;
    }
  }

  /// Atiende el menú de la cabecera: editar o borrar la materia.
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

  /// Abre la hoja con las opciones "Editar" y "Borrar" de un apunte.
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
    // Solo se reconstruye si cambia el modo demostración (no en cada segundo del Pomodoro).
    final modoDemo = context.select<PomodoroProvider, bool>((p) => p.modoDemo);

    // La materia se lee en vivo; si ya no existe, se cierra la pantalla.
    final materia = context.watch<MateriasProvider>().porId(widget.materia.id);
    if (materia == null) {
      if (!_cerrando) {
        _cerrando = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return const Scaffold();
    }
    // Mejor resultado en los quizzes de la materia; `null` si no ha hecho ninguno.
    final dominio = mejorIntento(
      context.watch<EstadisticasProvider>().intentos,
      materia.id,
    )?.proporcion;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('escanear-apunte'),
        onPressed: () => _escanear(materia),
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
                      // El dominio sale del mejor quiz; sin quizzes no se muestra
                      if (dominio != null) ...[
                        const SizedBox(height: 16),
                        // Barra de progreso dentro del banner
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: dominio,
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
                              '${(dominio * 100).round()}% dominado',
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
                      // Sin esto la cuadrícula hereda el alto de la barra de estado como margen.
                      padding: EdgeInsets.zero,
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
                          onTap: () => _resumir(materia),
                        ),

                        // Acción 2: Quiz IA
                        AccionCard(
                          titulo: 'Quiz IA',
                          subtitulo: materia.preguntas.isEmpty
                              ? 'Generar con IA'
                              : '${materia.preguntas.length} preguntas',
                          icono: Icons.quiz_rounded,
                          colorTema: const Color(0xFFE65100),
                          onTap: () => _abrirQuiz(materia),
                        ),

                        // Acción 3: Tutor IA
                        AccionCard(
                          titulo: 'Tutor IA',
                          subtitulo: 'Resuelve tus dudas',
                          icono: Icons.support_agent_rounded,
                          colorTema: const Color(0xFF00897B),
                          onTap: () => _abrirTutor(materia),
                        ),

                        // Acción 4: Pomodoro
                        AccionCard(
                          titulo: 'Pomodoro',
                          subtitulo:
                              'Sesión de ${formatearDuracion(ModoPomodoro.enfoque.segundos(demo: modoDemo))}',
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
                  if (materia.apuntes.isNotEmpty)
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
                          'Aún no tienes apuntes. Toca "+ Nuevo" para escribir '
                          'el primero o "Escanear" para pasar una foto a texto.',
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
                                apunte.tieneResumen
                                    ? '${apunte.fecha} • Resumen listo'
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ApunteScreen(
                                    materiaId: materia.id,
                                    apunteId: apunte.id,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () => _mostrarOpcionesApunte(apunte),
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
