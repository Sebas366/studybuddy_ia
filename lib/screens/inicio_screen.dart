import 'package:flutter/material.dart';
import '../data/datos_demo.dart';
import '../models/materia.dart';
import '../theme/app_colors.dart';
import '../widgets/materia_card.dart';
import 'detalle_materia_screen.dart';

/// Pantalla de Inicio principal de StudyBuddy IA.
///
/// Presenta el encabezado con saludo a Edwin, la tarjeta de racha de estudio,
/// buscador reactivo en vivo, lista de asignaturas y hoja inferior para registrar nuevas materias.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  /// Controlador para el campo de búsqueda de materias.
  final TextEditingController _controladorBusqueda = TextEditingController();

  /// Copia local mutable de las materias registradas para permitir filtrado y adición.
  late List<Materia> _materiasDisponibles;

  /// Texto actual aplicado en el filtro.
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _materiasDisponibles = List.from(DatosDemo.materias);
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  /// Filtra las materias según el texto digitado por el usuario.
  List<Materia> get _materiasFiltradas {
    if (_filtroBusqueda.trim().isEmpty) {
      return _materiasDisponibles;
    }
    final busqueda = _filtroBusqueda.toLowerCase();
    return _materiasDisponibles.where((materia) {
      return materia.nombre.toLowerCase().contains(busqueda) ||
          materia.subtitulo.toLowerCase().contains(busqueda) ||
          materia.descripcion.toLowerCase().contains(busqueda);
    }).toList();
  }

  /// Despliega una hoja modal inferior para registrar una nueva materia.
  void _mostrarModalNuevaMateria() {
    final controladorNombre = TextEditingController();
    final controladorSubtitulo = TextEditingController();
    final controladorDescripcion = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (contextModal) {
        final tema = Theme.of(contextModal);
        final esOscuro = tema.brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(contextModal).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: esOscuro ? const Color(0xFF23202B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nueva Materia',
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registra una nueva asignatura para comenzar a estudiar con la IA.',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: esOscuro ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controladorNombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la materia',
                      hintText: 'Ej. Redes de Computadores',
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controladorSubtitulo,
                    decoration: const InputDecoration(
                      labelText: 'Subtítulo o código',
                      hintText: 'Ej. Telecomunicaciones • Semestre VI',
                      prefixIcon: Icon(Icons.bookmark_border_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controladorDescripcion,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descripción corta',
                      hintText: 'Ej. Protocolos TCP/IP, enrutamiento y conmutación...',
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final nombre = controladorNombre.text.trim();
                        final subtitulo = controladorSubtitulo.text.trim();
                        final descripcion = controladorDescripcion.text.trim();

                        if (nombre.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor escribe el nombre de la materia.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Creamos una nueva materia y la agregamos al estado
                        final nuevaMateria = Materia(
                          id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
                          nombre: nombre,
                          subtitulo: subtitulo.isEmpty
                              ? 'Nueva materia agregada'
                              : subtitulo,
                          descripcion: descripcion.isEmpty
                              ? 'Sin descripción'
                              : descripcion,
                          progreso: 0.1,
                          icono: Icons.auto_stories_rounded,
                          colorInicio: const Color(0xFF6750A4),
                          colorFin: const Color(0xFF9C27B0),
                          apuntes: const [],
                          preguntas: const [],
                          respuestasSimuladasIa: const [
                            '¡Excelente tema! Estoy lista para ayudarte con tus dudas sobre esta nueva asignatura.',
                          ],
                        );

                        setState(() {
                          _materiasDisponibles.insert(0, nuevaMateria);
                        });

                        Navigator.pop(contextModal);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡Materia "$nombre" creada con éxito!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Crear Materia'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final materias = _materiasFiltradas;

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
                  // --- TARJETA DE RACHA DE ESTUDIO ---
                  Container(
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
                              const Text(
                                '¡Racha de 7 días activa! 🔥',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Estás en racha. Tu constancia te acerca a dominar todos tus parciales.',
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
                  ),

                  const SizedBox(height: 22),

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
                        onPressed: _mostrarModalNuevaMateria,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Nueva materia',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // --- LISTA DE MATERIAS O MENSAJE VACÍO ---
                  if (materias.isEmpty) ...[
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
                              color: esOscuro ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    for (final materia in materias)
                      MateriaCard(
                        materia: materia,
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
