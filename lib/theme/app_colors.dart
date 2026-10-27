import 'package:flutter/material.dart';

/// Paleta de colores centralizada para la aplicación StudyBuddy IA.
///
/// Define los colores principales, fondos, superficies, estados y degradados
/// utilizados en toda la interfaz de usuario en modo claro y oscuro.
class AppColors {
  // Evitamos la instanciación de esta clase utilitaria.
  AppColors._();

  /// Color semilla principal requerido por las especificaciones de diseño (Morado M3).
  static const Color colorSemilla = Color(0xFF6750A4);

  // --- Tonos Principales y Secundarios ---
  static const Color primario = Color(0xFF6750A4);
  static const Color primarioClaro = Color(0xFF7F67BE);
  static const Color primarioOscuro = Color(0xFF4F378B);
  static const Color secundario = Color(0xFF625B71);
  static const Color terciario = Color(0xFF7D5260);

  // --- Fondos y Superficies Modo Claro ---
  static const Color fondoClaro = Color(0xFFF7F5FA);
  static const Color superficieClara = Color(0xFFFFFFFF);
  static const Color tarjetaClara = Color(0xFFFFFFFF);
  static const Color bordeClaro = Color(0xFFE6E1E5);

  // --- Fondos y Superficies Modo Oscuro ---
  static const Color fondoOscuro = Color(0xFF141218);
  static const Color superficieOscura = Color(0xFF1D1B20);
  static const Color tarjetaOscura = Color(0xFF2B2831);
  static const Color bordeOscuro = Color(0xFF49454F);

  // --- Colores de Estado y Notificaciones ---
  static const Color exito = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB3261E);
  static const Color advertencia = Color(0xFFED6C02);
  static const Color rachaFuego = Color(0xFFFF6D00);

  // --- Degradados por Materia ---
  /// Degradado para Arquitectura de Computadores (Naranja / Ámbar intenso)
  static const List<Color> degradadoArquitectura = [
    Color(0xFFE65100),
    Color(0xFFFF8A65),
  ];

  /// Degradado para Bootcamp IA y Datos (Verde azulado / Teal tecnológico)
  static const List<Color> degradadoIaDatos = [
    Color(0xFF00695C),
    Color(0xFF26A69A),
  ];

  /// Degradado para Desarrollo Móvil (Azul brillante / Índigo moderno)
  static const List<Color> degradadoDesarrolloMovil = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ];

  /// Degradado de bienvenida en el encabezado principal
  static const List<Color> degradadoEncabezado = [
    Color(0xFF6750A4),
    Color(0xFF7F67BE),
  ];

  /// Degradado para la tarjeta de racha diaria
  static const List<Color> degradadoRacha = [
    Color(0xFFFF6F00),
    Color(0xFFFFAB40),
  ];
}
