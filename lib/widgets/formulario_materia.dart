import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/catalogo_materia.dart';
import '../models/materia.dart';
import '../providers/materias_provider.dart';
import '../utils/validadores.dart';

/// Muestra la hoja modal para crear una materia nueva o editar una existente.
///
/// Si se pasa [materia], el formulario se abre con sus datos y guarda los cambios;
/// si no, crea una materia nueva.
Future<void> mostrarFormularioMateria(
  BuildContext context, {
  Materia? materia,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (contextModal) => _FormularioMateria(materia: materia),
  );
}

/// Contenido de la hoja modal: nombre, descripción, color e icono.
class _FormularioMateria extends StatefulWidget {
  final Materia? materia;

  const _FormularioMateria({this.materia});

  @override
  State<_FormularioMateria> createState() => _FormularioMateriaState();
}

class _FormularioMateriaState extends State<_FormularioMateria> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controladorNombre;
  late final TextEditingController _controladorDescripcion;
  late int _colorIndice;
  late String _iconoClave;

  /// Evita crear dos registros si el usuario toca "Guardar" varias veces seguidas.
  bool _guardando = false;

  bool get _esEdicion => widget.materia != null;

  @override
  void initState() {
    super.initState();
    final materia = widget.materia;
    _controladorNombre = TextEditingController(text: materia?.nombre ?? '');
    _controladorDescripcion =
        TextEditingController(text: materia?.descripcion ?? '');
    _colorIndice = materia?.colorIndice ?? 0;
    _iconoClave = materia?.iconoClave ?? CatalogoMateria.iconoPorDefecto;
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorDescripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    _guardando = true;

    final provider = context.read<MateriasProvider>();
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final nombre = _controladorNombre.text.trim();

    try {
      if (_esEdicion) {
        await provider.actualizarMateria(
          id: widget.materia!.id,
          nombre: nombre,
          descripcion: _controladorDescripcion.text,
          colorIndice: _colorIndice,
          iconoClave: _iconoClave,
        );
      } else {
        await provider.crearMateria(
          nombre: nombre,
          descripcion: _controladorDescripcion.text,
          colorIndice: _colorIndice,
          iconoClave: _iconoClave,
        );
      }
    } catch (_) {
      _guardando = false;
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la materia. Inténtalo de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    navegador.pop();
    mensajero.showSnackBar(
      SnackBar(
        content: Text(_esEdicion
            ? '¡Materia "$nombre" actualizada!'
            : '¡Materia "$nombre" creada!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final etiqueta = tema.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: esOscuro ? Colors.white70 : Colors.black54,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: esOscuro ? const Color(0xFF23202B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                  _esEdicion ? 'Editar materia' : 'Nueva materia',
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  key: const Key('campo-nombre'),
                  controller: _controladorNombre,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: validarNombreMateria,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la materia',
                    hintText: 'Ej. Servicios Telemáticos',
                    prefixIcon: Icon(Icons.book_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('campo-descripcion'),
                  controller: _controladorDescripcion,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Qué se ve en la materia...',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Color', style: etiqueta),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < CatalogoMateria.degradados.length; i++)
                      _OpcionColor(
                        key: Key('color-$i'),
                        colores: CatalogoMateria.degradados[i],
                        seleccionado: i == _colorIndice,
                        onTap: () => setState(() => _colorIndice = i),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Icono', style: etiqueta),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entrada in CatalogoMateria.iconos.entries)
                      _OpcionIcono(
                        key: Key('icono-${entrada.key}'),
                        icono: entrada.value,
                        seleccionado: entrada.key == _iconoClave,
                        colorAcento: CatalogoMateria
                            .degradadoPorIndice(_colorIndice)
                            .first,
                        onTap: () => setState(() => _iconoClave = entrada.key),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('guardar-materia'),
                    onPressed: _guardar,
                    icon: Icon(_esEdicion ? Icons.check_rounded : Icons.add_rounded),
                    label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar materia'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculo con el degradado de una opción de color.
class _OpcionColor extends StatelessWidget {
  final List<Color> colores;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionColor({
    super.key,
    required this.colores,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colores,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: seleccionado
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: seleccionado
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

/// Cuadro con el icono de una opción de icono.
class _OpcionIcono extends StatelessWidget {
  final IconData icono;
  final bool seleccionado;
  final Color colorAcento;
  final VoidCallback onTap;

  const _OpcionIcono({
    super.key,
    required this.icono,
    required this.seleccionado,
    required this.colorAcento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: seleccionado
              ? colorAcento.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.12),
          border: seleccionado ? Border.all(color: colorAcento, width: 2) : null,
        ),
        child: Icon(icono, color: seleccionado ? colorAcento : Colors.grey),
      ),
    );
  }
}
