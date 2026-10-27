import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Notificador global reactivo para controlar el modo del tema (claro, oscuro o del sistema).
/// Por defecto se inicializa en [ThemeMode.system], permitiendo cambiarlo desde Perfil.
final ValueNotifier<ThemeMode> modoTemaGlobal =
    ValueNotifier<ThemeMode>(ThemeMode.system);

/// Configuración de temas visuales para StudyBuddy IA según la especificación Material 3.
/// Incluye tipografía Poppins y soporte completo para modo claro y modo oscuro.
class AppTheme {
  AppTheme._();

  /// Configuración del tema claro.
  static ThemeData get temaClaro {
    final esquemaColor = ColorScheme.fromSeed(
      seedColor: AppColors.colorSemilla,
      brightness: Brightness.light,
      surface: AppColors.superficieClara,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquemaColor,
      scaffoldBackgroundColor: AppColors.fondoClaro,
      // Se utiliza la tipografía Poppins para todos los estilos de texto
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: esquemaColor.onSurface,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: esquemaColor.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.tarjetaClara,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.bordeClaro.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: AppColors.superficieClara,
        indicatorColor: AppColors.primario.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primario,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secundario,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.bordeClaro.withValues(alpha: 0.8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.bordeClaro.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primario,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  /// Configuración del tema oscuro.
  static ThemeData get temaOscuro {
    final esquemaColor = ColorScheme.fromSeed(
      seedColor: AppColors.colorSemilla,
      brightness: Brightness.dark,
      surface: AppColors.superficieOscura,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquemaColor,
      scaffoldBackgroundColor: AppColors.fondoOscuro,
      // Tipografía Poppins adaptada al esquema de brillo oscuro
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: esquemaColor.onSurface,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: esquemaColor.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.tarjetaOscura,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.bordeOscuro.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: AppColors.superficieOscura,
        indicatorColor: AppColors.primarioClaro.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primarioClaro,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primarioClaro,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tarjetaOscura,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.bordeOscuro.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.bordeOscuro.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primarioClaro,
            width: 1.8,
          ),
        ),
      ),
    );
  }
}
