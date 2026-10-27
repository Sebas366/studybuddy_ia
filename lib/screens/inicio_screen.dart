import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/materia.dart';
import '../providers/estadisticas_provider.dart';
import '../providers/materias_provider.dart';
import '../theme/app_colors.dart';
import '../utils/calculos_estadisticas.dart';
import '../widgets/dialogo_confirmar_borrado.dart';
import '../widgets/formulario_materia.dart';
import '../widgets/materia_card.dart';
import 'detalle_materia_screen.dart';

/// Pantalla de Inicio principal de StudyBuddy IA.
///
/// Presenta el encabezado con saludo a Edwin, un estado vacío con botón para
/// crear la primera materia y, cuando ya hay materias, el buscador reactivo
/// en vivo y la lista de asignaturas reales guardadas en el dispositivo.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  /// Controlador para el campo de búsqueda de materias.
  final TextEditingController _controladorBusqueda = TextEditingController();

  /// Texto actual aplicado en el filtro.
  String _filtroBusqueda = '';

  /// Semestre elegido en el selector; `null` mientras se use el más reciente.
  String? _semestreElegido;

  /// `true` cuando el usuario eligió ver todos los semestres.
  bool _verTodos = false;

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  /// Semestre que se está viendo; `null` significa todos.
  ///
  /// Por defecto es el de la materia más reciente. Si el semestre elegido ya no
  /// existe (se borró o movió su última materia), vuelve a ese semestre.
  String? _semestreActivo(List<String> semestres) {
    if (_verTodos) return null;
    final elegido = _semestreElegido;
    if (elegido != null && semestres.contains(elegido)) return elegido;
    return semestres.isEmpty ? null : semestres.first;
  }

  /// Abre el formulario de materia y, si se guardó, hace que la vista siga a esa materia.
  Future<void> _abrirFormulario({Materia? materia}) async {
    final provider = context.read<MateriasProvider>();
    final semestreInicial = materia == null
        ? _semestreActivo(provider.semestres)
        : null;
    final guardado = await mostrarFormularioMateria(
      context,
      materia: materia,
      semestreInicial: semestreInicial,
    );
    if (!mounted || guardado == null) return;
    // Con "Todos" ya se ve todo; en un semestre concreto se salta al de la materia.
    if (!_verTodos) {
      setState(() => _semestreElegido = guardado);
    }
  }

  /// Filtra las materias por el semestre activo, o por texto si hay búsqueda.
  ///
  /// Al buscar se ignora el semestre: se busca por nombre, descripción o título
  /// de apuntes en todas las materias.
  List<Materia> _filtrar(List<Materia> materias, String? semestreActivo) {
    if (_filtroBusqueda.trim().isEmpty) {
      if (semestreActivo == null) return materias;
      return materias
          .where((materia) => materia.semestre == semestreActivo)
          .toList();
    }
    final busqueda = _filtroBusqueda.trim().toLowerCase();
    return materias.where((materia) {
      return materia.nombre.toLowerCase().contains(busqueda) ||
          materia.descripcion.toLowerCase().contains(busqueda) ||
          materia.apuntes.any(
            (apunte) => apunte.titulo.toLowerCase().contains(busqueda),
          );
    }).toList();
  }

  /// Abre la hoja con las opciones "Editar" y "Borrar" de una materia real.
  Future<void> _mostrarOpciones(Materia materia) async {
    final accion = await showModalBottomSheet<_AccionMateria>(
      context: context,
      builder: (contextHoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('opcion-editar-materia'),
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar'),
              onTap: () => Navigator.pop(contextHoja, _AccionMateria.editar),
            ),
            ListTile(
              key: const Key('opcion-borrar-materia'),
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Borrar'),
              onTap: () => Navigator.pop(contextHoja, _AccionMateria.borrar),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accion == null) return;

    switch (accion) {
      case _AccionMateria.editar:
        await _abrirFormulario(materia: materia);
      case _AccionMateria.borrar:
        final provider = context.read<MateriasProvider>();
        final confirmado = await confirmarBorrado(
          context,
          titulo: 'Borrar materia',
          mensaje: mensajeBorradoMateria(
            materia.nombre,
            materia.apuntes.length,
          ),
        );
        if (confirmado) await provider.borrarMateria(materia.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final provider = context.watch<MateriasProvider>();
    final racha = calcularRacha(
      context.watch<EstadisticasProvider>().sesiones,
      DateTime.now(),
    );
    final todas = provider.materias;
    final semestres = provider.semestres;
    final semestreActivo = _semestreActivo(semestres);
    final materias = _filtrar(todas, semestreActivo);
    // Se muestra el semestre en cada tarjeta cuando la lista mezcla semestres.
    final mostrarSemestre =
        semestreActivo == null || _filtroBusqueda.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // --- ENCABEZADO CON DEGRADADO Y SALUDO ---
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 54, 22, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.degradadoEncabezado,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(34),
                    bottomRight: Radius.circular(34),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'StudyBuddy IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        // Badge con foto o avatar de Edwin
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          child: const Text(
                            'E',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Hola, Edwin! 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '¿Qué vamos a repasar hoy?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- CONTENIDO DEL CUERPO ---
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // --- TARJETA DE RACHA DE ESTUDIO (solo si hay racha) ---
                  if (racha >= 1) ...[
                    _TarjetaRacha(dias: racha),
                    const SizedBox(height: 22),
                  ],
                  if (provider.cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.error != null)
                    _ErrorCarga(
                      mensaje: provider.error!,
                      onReintentar: provider.cargar,
                    )
                  else if (todas.isEmpty)
                    _EstadoVacio(onCrear: _abrirFormulario)
                  else ...[
                    // --- BUSCADOR EN VIVO ---
                    TextField(
                      controller: _controladorBusqueda,
                      onChanged: (valor) {
                        setState(() {
                          _filtroBusqueda = valor;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar materias, temas o apuntes...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _filtroBusqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _controladorBusqueda.clear();
                                  setState(() {
                                    _filtroBusqueda = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- SELECTOR DE SEMESTRE ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SelectorSemestre(
                        semestres: semestres,
                        activo: semestreActivo,
                        onElegir: (semestre) => setState(() {
                          _verTodos = semestre == null;
                          _semestreElegido = semestre;
                        }),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- ENCABEZADO DE SECCIÓN Y BOTÓN NUEVA MATERIA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Mis Materias (${materias.length})',
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _abrirFormulario,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Nueva materia',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // --- LISTA DE MATERIAS O MENSAJE SIN RESULTADOS ---
                    if (materias.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 54,
                              color: esOscuro ? Colors.white30 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron materias con "$_filtroBusqueda"',
                              style: tema.textTheme.bodyMedium?.copyWith(
                                color: esOscuro
                                    ? Colors.white54
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final materia in materias)
                        MateriaCard(
                          materia: materia,
                          semestre: mostrarSemestre ? materia.semestre : null,
                          onLongPress: () => _mostrarOpciones(materia),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetalleMateriaScreen(materia: materia),
                              ),
                            );
                          },
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

/// Botón en forma de píldora que abre el menú para elegir qué semestre ver.
class _SelectorSemestre extends StatelessWidget {
  /// Semestres disponibles, el de la materia más reciente primero.
  final List<String> semestres;

  /// Semestre que se está viendo; `null` significa "Todos".
  final String? activo;

  /// Se llama con el semestre elegido, o `null` si se eligió "Todos".
  final ValueChanged<String?> onElegir;

  const _SelectorSemestre({
    required this.semestres,
    required this.activo,
    required this.onElegir,
  });

  /// Valor interno de la opción "Todos" (el menú no admite `null` como valor).
  static const _valorTodos = '\u0000todos';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return PopupMenuButton<String>(
      key: const Key('selector-semestre'),
      tooltip: 'Elegir semestre',
      onSelected: (valor) => onElegir(valor == _valorTodos ? null : valor),
      itemBuilder: (contextMenu) => [
        for (final semestre in semestres)
          PopupMenuItem<String>(
            key: Key('semestre-$semestre'),
            value: semestre,
            child: Text(semestre),
          ),
        const PopupMenuItem<String>(
          key: Key('semestre-todos'),
          value: _valorTodos,
          child: Text('Todos'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primario.withValues(alpha: esOscuro ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_rounded,
              size: 18,
              color: AppColors.primario,
            ),
            const SizedBox(width: 8),
            Text(
              activo ?? 'Todos',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primario,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primario,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con los días consecutivos de estudio.
class _TarjetaRacha extends StatelessWidget {
  /// Días de racha (al menos 1).
  final int dias;

  const _TarjetaRacha({required this.dias});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.degradadoRacha,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.rachaFuego.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dias == 1
                      ? '¡Racha de 1 día activa! 🔥'
                      : '¡Racha de $dias días activa! 🔥',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu constancia te acerca a dominar todos tus parciales.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Acciones disponibles al mantener pulsada una materia.
enum _AccionMateria { editar, borrar }

/// Error de lectura en Inicio: explica el problema y ofrece reintentar.
class _ErrorCarga extends StatelessWidget {
  final String mensaje;

  /// Acción ejecutada al pulsar "Reintentar".
  final VoidCallback onReintentar;

  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 54),
          const SizedBox(height: 16),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            key: const Key('reintentar-carga'),
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío de Inicio: invita a crear la primera materia.
class _EstadoVacio extends StatelessWidget {
  /// Acción ejecutada al pulsar "Crear mi primera materia".
  final VoidCallback onCrear;

  const _EstadoVacio({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primario.withValues(
                alpha: esOscuro ? 0.25 : 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_books_rounded,
              size: 42,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aún no tienes materias',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea la primera para empezar a guardar tus apuntes.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: esOscuro ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('crear-primera-materia'),
              onPressed: onCrear,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear mi primera materia'),
            ),
          ),
        ],
      ),
    );
  }
}
