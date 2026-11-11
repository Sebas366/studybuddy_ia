import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ajustes_provider.dart';
import '../providers/ia_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/servicio_ia.dart';
import '../theme/app_colors.dart';
import '../utils/plan.dart';
import '../widgets/dialogo_clave_ia.dart';
import '../widgets/dialogo_confirmar_borrado.dart';

/// Pantalla de Perfil y configuración de la aplicación StudyBuddy IA.
///
/// Permite editar el nombre y la carrera, alternar entre modo claro y oscuro,
/// programar el recordatorio diario, conectar la IA con la clave de la API y
/// consultar información de la app. Todo queda guardado en el dispositivo.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  /// `true` mientras se comprueba la clave de la IA contra la API.
  bool _probandoIa = false;

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Abre el diálogo para cambiar el nombre y la carrera.
  Future<void> _editarPerfil() async {
    final ajustes = context.read<AjustesProvider>();
    final perfil = await showDialog<({String nombre, String carrera})>(
      context: context,
      builder: (_) => _DialogoPerfil(
        nombre: ajustes.nombre == AjustesProvider.nombrePorDefecto
            ? ''
            : ajustes.nombre,
        carrera: ajustes.carrera,
      ),
    );
    if (perfil == null) return;
    await ajustes.cambiarPerfil(nombre: perfil.nombre, carrera: perfil.carrera);
  }

  /// Deja elegir la hora del recordatorio y lo deja encendido.
  Future<void> _elegirHoraRecordatorio() async {
    final ajustes = context.read<AjustesProvider>();
    final hora = await showTimePicker(
      context: context,
      initialTime: ajustes.horaRecordatorio,
      helpText: 'Hora del recordatorio',
    );
    if (hora == null) return;
    await ajustes.cambiarRecordatorio(activo: true, hora: hora);
  }

  /// Comprueba contra la API que la clave guardada funciona.
  Future<void> _probarIa() async {
    if (_probandoIa) return;
    final ia = context.read<IaProvider>();
    setState(() => _probandoIa = true);
    String mensaje;
    try {
      await ia.servicio.probarConexion();
      mensaje = 'Conexión correcta: la IA está lista.';
    } on ErrorIa catch (fallo) {
      mensaje = fallo.mensaje;
    } catch (_) {
      mensaje = 'No se pudo comprobar la conexión.';
    }
    if (!mounted) return;
    setState(() => _probandoIa = false);
    _avisar(mensaje);
  }

  Future<void> _quitarClaveIa() async {
    final ia = context.read<IaProvider>();
    final confirmado = await confirmarBorrado(
      context,
      titulo: 'Quitar la clave',
      mensaje:
          'El resumen, el quiz, el tutor y el escáner dejarán de funcionar '
          'hasta que vuelvas a conectar la IA. Lo que ya generaste se conserva.',
    );
    if (confirmado) await ia.borrarClave();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final ajustes = context.watch<AjustesProvider>();
    final ia = context.watch<IaProvider>();
    final horaRecordatorio = formatearHora(
      DateTime(
        2000,
        1,
        1,
        ajustes.horaRecordatorio.hour,
        ajustes.horaRecordatorio.minute,
      ),
    );

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
              child: Stack(
                children: [
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      key: const Key('editar-perfil'),
                      tooltip: 'Editar perfil',
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      onPressed: _editarPerfil,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
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
                    child: Text(
                      ajustes.nombre.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    ajustes.nombre,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
                    child: Text(
                      ajustes.carrera.isEmpty
                          ? 'Toca el lápiz para escribir tu nombre y tu carrera'
                          : ajustes.carrera,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primario,
                      ),
                    ),
                  ),
                ],
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
                  // Switch para Modo Oscuro; el tema elegido queda guardado
                  Builder(
                    builder: (context) {
                      final modoTema = ajustes.modoTema;
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
                          ajustes.cambiarTema(
                            nuevoValor ? ThemeMode.dark : ThemeMode.light,
                          );
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

                  // Switch del modo demostración: bloques de Pomodoro cortos
                  Consumer<PomodoroProvider>(
                    builder: (context, pomodoro, _) => SwitchListTile(
                      key: const Key('modo-demo'),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B)
                              .withValues(alpha: esOscuro ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          color: Color(0xFF00897B),
                        ),
                      ),
                      title: Text(
                        'Modo demostración',
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Bloques cortos: 15 s de enfoque, 5 s de descanso y 10 s de descanso largo, para mostrar la app.',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: esOscuro ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      activeThumbColor: const Color(0xFF00897B),
                      value: pomodoro.modoDemo,
                      onChanged: pomodoro.alternarModoDemo,
                    ),
                  ),

                  Divider(
                    height: 1,
                    indent: 64,
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  // Switch del recordatorio diario; al tocar la fila se elige la hora
                  SwitchListTile(
                    key: const Key('recordatorio-estudio'),
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
                      'Aviso diario a las $horaRecordatorio para mantener la racha',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: esOscuro ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    activeThumbColor: const Color(0xFFFF6D00),
                    value: ajustes.recordatorioActivo,
                    onChanged: (nuevoValor) async {
                      await ajustes.cambiarRecordatorio(activo: nuevoValor);
                      if (!mounted) return;
                      _avisar(
                        nuevoValor
                            ? 'Recordatorio diario activado a las $horaRecordatorio.'
                            : 'Recordatorio desactivado.',
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 58, bottom: 6),
                      child: TextButton.icon(
                        key: const Key('hora-recordatorio'),
                        onPressed: _elegirHoraRecordatorio,
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: const Text('Cambiar hora'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 24),

            // --- SECCIÓN DE INTELIGENCIA ARTIFICIAL ---
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
                          color: AppColors.primario
                              .withValues(alpha: esOscuro ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primario,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inteligencia artificial',
                              style: tema.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ia.tieneClave
                                  ? 'Conectada · ${ia.proveedor.nombre} · ${ia.claveOculta}'
                                  : 'Sin conectar',
                              key: const Key('estado-ia'),
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: ia.tieneClave
                                    ? const Color(0xFF2E7D32)
                                    : (esOscuro
                                          ? Colors.white60
                                          : Colors.black54),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'El resumen, el quiz, el tutor, el escáner y el plan '
                    'sugerido usan Gemini (gratis) o Claude (de pago) con tu '
                    'propia clave. Se guarda cifrada en este dispositivo.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: esOscuro ? Colors.white70 : Colors.black87,
                      height: 1.5,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ElevatedButton.icon(
                        key: const Key('conectar-ia'),
                        onPressed: () => mostrarDialogoClaveIa(context),
                        icon: const Icon(Icons.key_rounded, size: 18),
                        label: Text(
                          ia.tieneClave ? 'Cambiar clave' : 'Conectar la IA',
                        ),
                      ),
                      if (ia.tieneClave) ...[
                        OutlinedButton(
                          key: const Key('probar-ia'),
                          onPressed: _probandoIa ? null : _probarIa,
                          child: Text(
                            _probandoIa ? 'Probando...' : 'Probar conexión',
                          ),
                        ),
                        TextButton(
                          key: const Key('quitar-clave-ia'),
                          onPressed: _quitarClaveIa,
                          child: const Text('Quitar clave'),
                        ),
                      ],
                    ],
                  ),
                ],
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
                            'Versión 1.0.0',
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
                    'StudyBuddy IA es un asistente para el estudio universitario: organiza tus materias y apuntes, los resume con IA, crea quizzes para autoevaluarte, responde tus dudas con un tutor, arma tu plan de estudio y mide tu avance con la técnica Pomodoro.',
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
                          'Flutter • SQLite • IA con Gemini o Claude',
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

/// Diálogo con los campos del perfil; devuelve lo escrito al pulsar "Guardar".
class _DialogoPerfil extends StatefulWidget {
  final String nombre;
  final String carrera;

  const _DialogoPerfil({required this.nombre, required this.carrera});

  @override
  State<_DialogoPerfil> createState() => _DialogoPerfilState();
}

class _DialogoPerfilState extends State<_DialogoPerfil> {
  late final TextEditingController _controladorNombre;
  late final TextEditingController _controladorCarrera;

  @override
  void initState() {
    super.initState();
    _controladorNombre = TextEditingController(text: widget.nombre);
    _controladorCarrera = TextEditingController(text: widget.carrera);
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorCarrera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('campo-nombre-perfil'),
              controller: _controladorNombre,
              textCapitalization: TextCapitalization.words,
              maxLength: AjustesProvider.maxTextoPerfil,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('campo-carrera-perfil'),
              controller: _controladorCarrera,
              textCapitalization: TextCapitalization.sentences,
              maxLength: AjustesProvider.maxTextoPerfil,
              decoration: const InputDecoration(
                labelText: 'Carrera (opcional)',
                prefixIcon: Icon(Icons.school_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('guardar-perfil'),
          onPressed: () => Navigator.pop(context, (
            nombre: _controladorNombre.text,
            carrera: _controladorCarrera.text,
          )),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
