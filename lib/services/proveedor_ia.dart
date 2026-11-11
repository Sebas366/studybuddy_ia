/// Servicio de IA con el que el usuario conecta la app.
enum ProveedorIa {
  /// API de Gemini, de Google: tiene un nivel gratuito.
  gemini(
    nombre: 'Gemini',
    etiqueta: 'Gemini (gratis)',
    dondeConseguirla:
        'Créala gratis en aistudio.google.com, en "Get API key", con tu '
        'cuenta de Google.',
    ejemplo: 'AIza...',
    aviso:
        'En el plan gratuito, Google puede usar lo que envías para mejorar '
        'sus productos: no escanees ni resumas datos personales.',
  ),

  /// API de Claude, de Anthropic: se paga por uso.
  claude(
    nombre: 'Claude',
    etiqueta: 'Claude (pago)',
    dondeConseguirla:
        'Créala en platform.claude.com, en "API keys". Se paga por uso y es '
        'aparte de la suscripción de claude.ai.',
    ejemplo: 'sk-ant-...',
    aviso: '',
  );

  const ProveedorIa({
    required this.nombre,
    required this.etiqueta,
    required this.dondeConseguirla,
    required this.ejemplo,
    required this.aviso,
  });

  /// Nombre corto del servicio.
  final String nombre;

  /// Nombre para mostrar en el selector, con su costo.
  final String etiqueta;

  /// Dónde se crea la clave de este servicio.
  final String dondeConseguirla;

  /// Cómo empieza una clave de este servicio.
  final String ejemplo;

  /// Advertencia que se muestra al elegir este servicio; vacía si no hay.
  final String aviso;

  /// Proveedor al que parece pertenecer una clave por su forma; `null` si no se reconoce.
  static ProveedorIa? porForma(String clave) {
    final limpia = clave.trim();
    if (limpia.startsWith('sk-ant-')) return ProveedorIa.claude;
    if (limpia.startsWith('AIza')) return ProveedorIa.gemini;
    return null;
  }
}
