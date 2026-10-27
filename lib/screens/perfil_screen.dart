import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Pantalla de Perfil y configuración de la aplicación StudyBuddy IA.
///
/// Permite gestionar las preferencias de usuario, alternar entre modo claro y oscuro
/// mediante [modoTemaGlobal], configurar recordatorios y consultar información de la app.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  /// Estado del interruptor de recordatorios diarios de estudio.
  bool _recordatoriosActivos = true;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // --- TARJETA DE USUARIO CON AVATAR ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: esOscuro ? 0.3 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar con inicial y degradado morado
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.degradadoEncabezado,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primario.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'E',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Edwin',
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'edwin.estudiante@universidad.edu.co',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: esOscuro ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primario
                          .withValues(alpha: esOscuro ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Estudiante de Ingeniería de Sistemas',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primario,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- SECCIÓN DE PREFERENCIAS Y APARIENCIA ---
            Container(
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: Column(
                children: [
                  // Switch para Modo Oscuro reactivo con ValueListenableBuilder
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: modoTemaGlobal,
                    builder: (context, modoTema, _) {
                      // Si está en sistema, reflejamos el brillo de la plataforma
                      final bool interruptorOscuro =
                          modoTema == ThemeMode.dark ||
                              (modoTema == ThemeMode.system && esOscuro);

                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primario
                                .withValues(alpha: esOscuro ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            interruptorOscuro
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: AppColors.primario,
                          ),
                        ),
                        title: Text(
                          'Modo Oscuro',
                          style: tema.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          interruptorOscuro
                              ? 'Tema oscuro activado'
                              : 'Tema claro activado',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: esOscuro ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        activeThumbColor: AppColors.primario,
                        value: interruptorOscuro,
                        onChanged: (nuevoValor) {
                          modoTemaGlobal.value =
                              nuevoValor ? ThemeMode.dark : ThemeMode.light;
                        },
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    indent: 64,
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  // Switch para Recordatorios diarios de estudio
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 4),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6D00)
                            .withValues(alpha: esOscuro ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFFFF6D00),
                      ),
                    ),
                    title: Text(
                      'Recordatorios de Estudio',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Aviso diario a las 06:00 PM para mantener la racha',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: esOscuro ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    activeThumbColor: const Color(0xFFFF6D00),
                    value: _recordatoriosActivos,
                    onChanged: (nuevoValor) {
                      setState(() {
                        _recordatoriosActivos = nuevoValor;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            nuevoValor
                                ? 'Recordatorios de estudio activados.'
                                : 'Recordatorios desactivados.',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 24),

            // --- SECCIÓN "ACERCA DE" ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B)
                              .withValues(alpha: esOscuro ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF00897B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acerca de StudyBuddy IA',
                            style: tema.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Versión 1.0.0 (Fase 1 - Mockup)',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: esOscuro ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'StudyBuddy IA es un asistente inteligente enfocado en transformar la experiencia de estudio universitario. Incorpora resúmenes multinivel, autoevaluaciones adaptativas tipo Quiz, acompañamiento pedagógico con Tutor IA y técnica Pomodoro.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: esOscuro ? Colors.white70 : Colors.black87,
                      height: 1.5,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 15,
                        color: esOscuro ? Colors.white54 : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Material 3 • Fuente Poppins • Flutter & Dart',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: esOscuro ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
