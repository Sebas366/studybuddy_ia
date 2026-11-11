import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ia_provider.dart';
import '../services/proveedor_ia.dart';

/// Abre el diálogo para elegir el servicio de IA y escribir su clave.
///
/// Devuelve `true` si el usuario guardó una clave.
Future<bool> mostrarDialogoClaveIa(BuildContext context) async {
  final guardada = await showDialog<bool>(
    context: context,
    builder: (_) => const _DialogoClaveIa(),
  );
  return guardada ?? false;
}

/// Comprueba que haya una clave de IA; si falta, ofrece configurarla ahí mismo.
///
/// Devuelve `true` si la IA quedó lista para usarse.
Future<bool> asegurarClaveIa(BuildContext context) async {
  if (context.read<IaProvider>().tieneClave) return true;
  return mostrarDialogoClaveIa(context);
}

class _DialogoClaveIa extends StatefulWidget {
  const _DialogoClaveIa();

  @override
  State<_DialogoClaveIa> createState() => _DialogoClaveIaState();
}

class _DialogoClaveIaState extends State<_DialogoClaveIa> {
  final _controlador = TextEditingController();
  late ProveedorIa _proveedor;
  String? _error;
  bool _oculta = true;

  @override
  void initState() {
    super.initState();
    _proveedor = context.read<IaProvider>().proveedor;
  }

  /// Si la clave pegada tiene la forma de la del otro servicio, lo selecciona.
  void _alCambiarClave(String texto) {
    final deducido = ProveedorIa.porForma(texto);
    if (deducido != null && deducido != _proveedor) {
      setState(() => _proveedor = deducido);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final provider = context.read<IaProvider>();
    final navegador = Navigator.of(context);
    try {
      await provider.guardarClave(_proveedor, _controlador.text);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message as String?);
      return;
    }
    navegador.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Conectar la IA'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El resumen, el quiz, el tutor, el escáner y el plan sugerido '
              'usan un servicio de IA con tu propia clave. Elige cuál:',
              style: tema.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ProveedorIa>(
                key: const Key('selector-proveedor-ia'),
                showSelectedIcon: false,
                segments: [
                  for (final proveedor in ProveedorIa.values)
                    ButtonSegment(
                      value: proveedor,
                      label: Text(
                        proveedor.etiqueta,
                        key: Key('proveedor-${proveedor.name}'),
                      ),
                    ),
                ],
                selected: {_proveedor},
                onSelectionChanged: (seleccion) =>
                    setState(() => _proveedor = seleccion.first),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _proveedor.dondeConseguirla,
              style: tema.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('campo-clave-ia'),
              controller: _controlador,
              obscureText: _oculta,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Clave de la API',
                hintText: _proveedor.ejemplo,
                errorText: _error,
                suffixIcon: IconButton(
                  tooltip: _oculta ? 'Mostrar clave' : 'Ocultar clave',
                  icon: Icon(
                    _oculta
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () => setState(() => _oculta = !_oculta),
                ),
              ),
              onChanged: _alCambiarClave,
              onSubmitted: (_) => _guardar(),
            ),
            const SizedBox(height: 12),
            Text(
              'La clave se guarda cifrada en este dispositivo y solo se envía '
              'a ${_proveedor.nombre}.'
              '${_proveedor.aviso.isEmpty ? '' : ' ${_proveedor.aviso}'}',
              style: tema.textTheme.labelSmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('guardar-clave-ia'),
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
