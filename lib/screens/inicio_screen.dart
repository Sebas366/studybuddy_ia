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

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  /// Filtra las materias por nombre, descripción o título de sus apuntes.
  List<Materia> _filtrar(List<Materia> materias) {
    if (_filtroBusqueda.trim().isEmpty) {
      return materias;
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
        await mostrarFormularioMateria(context, materia: materia);
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
    final materias = _filtrar(todas);

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
                    _EstadoVacio(
                      onCrear: () => mostrarFormularioMateria(context),
                    )
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
                          onPressed: () => mostrarFormularioMateria(context),
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
