import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda la clave de la API de IA del usuario.
///
/// Es una interfaz para poder cambiar el almacenamiento cifrado real por uno
/// en memoria en las pruebas.
abstract class AlmacenClave {
  /// Devuelve la clave guardada, o `null` si no hay ninguna.
  Future<String?> leer();

  /// Guarda la clave, reemplazando la anterior.
  Future<void> guardar(String clave);

  /// Borra la clave guardada.
  Future<void> borrar();
}

/// Almacén real: la clave queda cifrada con el Keystore de Android.
///
/// La clave es un secreto que da acceso a la cuenta de la API, por eso no se
/// guarda en la base de datos junto con los demás ajustes.
class AlmacenClaveSeguro implements AlmacenClave {
  const AlmacenClaveSeguro();

  static const FlutterSecureStorage _almacen = FlutterSecureStorage();
  static const String _nombre = 'clave_api_claude';

  @override
  Future<String?> leer() => _almacen.read(key: _nombre);

  @override
  Future<void> guardar(String clave) =>
      _almacen.write(key: _nombre, value: clave);

  @override
  Future<void> borrar() => _almacen.delete(key: _nombre);
}

/// Almacén que solo vive mientras la app está abierta.
///
/// Se usa en las pruebas y como respaldo si el almacenamiento cifrado falla.
class AlmacenClaveMemoria implements AlmacenClave {
  AlmacenClaveMemoria([this._clave]);

  String? _clave;

  @override
  Future<String?> leer() async => _clave;

  @override
  Future<void> guardar(String clave) async => _clave = clave;

  @override
  Future<void> borrar() async => _clave = null;
}
