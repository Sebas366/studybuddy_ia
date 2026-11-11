import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/apunte.dart';
import '../providers/materias_provider.dart';
import '../utils/validadores.dart';

/// Pantalla para escribir un apunte nuevo o editar uno existente.
///
/// Si se pasa [apunte], se abre con sus datos y guarda los cambios; si no,
/// crea un apunte nuevo dentro de la materia [materiaId]. La fecha se asigna
/// sola al crear y no se puede editar.
///
/// Un apunte escaneado llega con [tituloInicial] y [contenidoInicial] (lo que
/// transcribió la IA) para que el usuario lo revise antes de guardarlo.
class FormularioApunteScreen extends StatefulWidget {
  /// Materia a la que pertenece (o pertenecerá) el apunte.
  final String materiaId;

  /// Apunte a editar; `null` para crear uno nuevo.
  final Apunte? apunte;

  /// Título propuesto para un apunte nuevo.
  final String? tituloInicial;

  /// Texto propuesto para un apunte nuevo.
  final String? contenidoInicial;

  const FormularioApunteScreen({
    super.key,
    required this.materiaId,
    this.apunte,
    this.tituloInicial,
    this.contenidoInicial,
  });

  @override
  State<FormularioApunteScreen> createState() => _FormularioApunteScreenState();
}

class _FormularioApunteScreenState extends State<FormularioApunteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controladorTitulo;
  late final TextEditingController _controladorTexto;

  /// Evita crear dos apuntes si el usuario toca "Guardar" varias veces seguidas.
  bool _guardando = false;

  bool get _esEdicion => widget.apunte != null;

  /// `true` si el formulario se abrió con el texto de una foto escaneada.
  bool get _esEscaneado => !_esEdicion && widget.contenidoInicial != null;

  @override
  void initState() {
    super.initState();
    _controladorTitulo = TextEditingController(
      text: widget.apunte?.titulo ?? widget.tituloInicial ?? '',
    );
    _controladorTexto = TextEditingController(
      text: widget.apunte?.contenido ?? widget.contenidoInicial ?? '',
    );
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorTexto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    _guardando = true;

    final provider = context.read<MateriasProvider>();
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      if (_esEdicion) {
        await provider.actualizarApunte(
          id: widget.apunte!.id,
          titulo: _controladorTitulo.text,
          contenido: _controladorTexto.text,
        );
      } else {
        await provider.crearApunte(
          materiaId: widget.materiaId,
          titulo: _controladorTitulo.text,
          contenido: _controladorTexto.text,
        );
      }
    } catch (_) {
      _guardando = false;
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el apunte. Inténtalo de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion
              ? 'Editar apunte'
              : (_esEscaneado ? 'Revisar apunte escaneado' : 'Nuevo apunte'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_esEscaneado) ...[
                  Text(
                    'La IA transcribió tu foto. Revisa el texto y corrige lo '
                    'que haga falta antes de guardar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const Key('campo-titulo-apunte'),
                  controller: _controladorTitulo,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: validarTituloApunte,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. DHCP y proceso DORA',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('campo-texto-apunte'),
                  controller: _controladorTexto,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 8,
                  maxLines: null,
                  validator: validarTextoApunte,
                  decoration: const InputDecoration(
                    labelText: 'Texto del apunte',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('guardar-apunte'),
                    onPressed: _guardar,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Guardar apunte'),
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
