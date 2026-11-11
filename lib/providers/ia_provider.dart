import 'package:flutter/foundation.dart';

import '../services/almacen_clave.dart';
import '../services/proveedor_ia.dart';
import '../services/servicio_ia.dart';
import '../services/servicio_ia_claude.dart';
import '../services/servicio_ia_gemini.dart';

/// Crea el servicio de IA de un proveedor a partir de la clave del usuario.
typedef FabricaServicioIa =
    ServicioIa Function(ProveedorIa proveedor, String clave);

/// Estado de la conexión con la IA: el proveedor elegido, la clave del usuario
/// y el servicio listo para usar.
///
/// La app no trae una clave propia: cada usuario elige el servicio (Gemini,
/// gratis, o Claude, de pago) y escribe su clave en Perfil. Queda guardada
/// cifrada en el dispositivo.
class IaProvider extends ChangeNotifier {
  IaProvider({required this._almacen, FabricaServicioIa? fabrica})
    : _fabrica = fabrica ?? _crearServicio;

  final AlmacenClave _almacen;
  final FabricaServicioIa _fabrica;

  ProveedorIa _proveedor = ProveedorIa.gemini;
  String? _clave;
  ServicioIa? _servicio;

  static ServicioIa _crearServicio(ProveedorIa proveedor, String clave) {
    return switch (proveedor) {
      ProveedorIa.gemini => ServicioIaGemini(clave: clave),
      ProveedorIa.claude => ServicioIaClaude(clave: clave),
    };
  }

  /// Servicio con el que está conectada la app (o el propuesto, si aún no hay clave).
  ProveedorIa get proveedor => _proveedor;

  /// `true` si el usuario ya guardó su clave.
  bool get tieneClave => _servicio != null;

  /// Clave guardada con el centro oculto (ej. `sk-ant-…x9Qw`), para mostrarla en Perfil.
  String? get claveOculta {
    final clave = _clave;
    if (clave == null) return null;
    if (clave.length <= 12) return '••••';
    return '${clave.substring(0, 7)}…${clave.substring(clave.length - 4)}';
  }

  /// Servicio de IA listo para usar. Lanza [ErrorIa] si todavía no hay clave.
  ServicioIa get servicio => _servicio ?? (throw const ErrorIa.sinClave());

  /// Lee la clave guardada. Nunca lanza: sin clave, la IA queda sin configurar.
  Future<void> cargar() async {
    try {
      final guardado = await _almacen.leer();
      final (proveedor, clave) = _separar(guardado ?? '');
      _usar(proveedor, clave);
    } catch (_) {
      _usar(_proveedor, null);
    }
    notifyListeners();
  }

  /// Guarda la clave del usuario para ese [proveedor] y deja el servicio listo.
  ///
  /// Lanza [ArgumentError] si la clave está vacía.
  Future<void> guardarClave(ProveedorIa proveedor, String clave) async {
    final limpia = clave.trim();
    if (limpia.isEmpty) throw ArgumentError('Escribe tu clave de la API.');
    _usar(proveedor, limpia);
    notifyListeners();
    try {
      await _almacen.guardar('${proveedor.name}$_separador$limpia');
    } catch (_) {
      // La clave sirve hasta cerrar la app aunque no se haya podido guardar.
    }
  }

  /// Borra la clave guardada; la IA queda sin configurar.
  Future<void> borrarClave() async {
    _usar(_proveedor, null);
    notifyListeners();
    try {
      await _almacen.borrar();
    } catch (_) {}
  }

  void _usar(ProveedorIa proveedor, String? clave) {
    final limpia = clave?.trim() ?? '';
    _proveedor = proveedor;
    _clave = limpia.isEmpty ? null : limpia;
    _servicio = _clave == null ? null : _fabrica(proveedor, _clave!);
  }

  /// Separa el proveedor de la clave en el texto guardado.
  static const String _separador = '|';

  /// Lee el texto guardado, con formato `proveedor|clave`.
  ///
  /// Un texto sin proveedor es una clave suelta: se deduce por su forma.
  (ProveedorIa, String) _separar(String guardado) {
    final corte = guardado.indexOf(_separador);
    if (corte > 0) {
      final nombre = guardado.substring(0, corte);
      for (final proveedor in ProveedorIa.values) {
        if (proveedor.name == nombre) {
          return (proveedor, guardado.substring(corte + 1));
        }
      }
    }
    return (ProveedorIa.porForma(guardado) ?? ProveedorIa.gemini, guardado);
  }
}
