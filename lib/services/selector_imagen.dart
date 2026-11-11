import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// De dónde sale la foto de un apunte.
enum OrigenImagen { camara, galeria }

/// Foto elegida por el usuario, lista para enviarla a la IA.
class ImagenElegida {
  /// Contenido del archivo de imagen.
  final Uint8List bytes;

  /// Formato de la imagen (ej. `image/jpeg`).
  final String tipoMime;

  const ImagenElegida({required this.bytes, required this.tipoMime});
}

/// Deja que el usuario tome o elija la foto de un apunte.
///
/// Es una interfaz para poder cambiar la cámara real por una falsa en las pruebas.
abstract class SelectorImagen {
  /// Abre la cámara o la galería. Devuelve `null` si el usuario cancela.
  Future<ImagenElegida?> elegir(OrigenImagen origen);
}

/// Selector real, sobre la cámara y la galería del sistema.
class SelectorImagenSistema implements SelectorImagen {
  const SelectorImagenSistema();

  @override
  Future<ImagenElegida?> elegir(OrigenImagen origen) async {
    // Se reduce la foto para que suba rápido; a este tamaño el texto de una
    // hoja sigue siendo legible para el modelo.
    final archivo = await ImagePicker().pickImage(
      source: origen == OrigenImagen.camara
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (archivo == null) return null;
    return ImagenElegida(
      bytes: await archivo.readAsBytes(),
      tipoMime: _tipoMime(archivo),
    );
  }

  /// Formato de la imagen, según lo que informe el sistema o su extensión.
  String _tipoMime(XFile archivo) {
    const admitidos = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'};
    final informado = archivo.mimeType;
    if (informado != null && admitidos.contains(informado)) return informado;
    final nombre = archivo.name.toLowerCase();
    if (nombre.endsWith('.png')) return 'image/png';
    if (nombre.endsWith('.webp')) return 'image/webp';
    if (nombre.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
