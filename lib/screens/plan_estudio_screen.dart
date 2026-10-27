import 'package:flutter/material.dart';
import '../data/datos_demo.dart';
import '../models/sesion_estudio.dart';
import '../theme/app_colors.dart';
import 'detalle_materia_screen.dart';

/// Pantalla del Plan de Estudio del estudiante.
///
/// Presenta la tarjeta destacada del próximo parcial con cuenta regresiva,
/// y la lista interactiva de sesiones de estudio de la jornada con casillas de verificación (checkbox).
class PlanEstudioScreen extends StatefulWidget {
  const PlanEstudioScreen({super.key});

  @override
  State<PlanEstudioScreen> createState() => _PlanEstudioScreenState();
}

class _PlanEstudioScreenState extends State<PlanEstudioScreen> {
  /// Lista mutable de sesiones de estudio del día.
  late List<SesionEstudio> _sesiones;

  @override
  void initState() {
    super.initState();
    _sesiones = List.from(DatosDemo.sesionesDelDia);
  }

  /// Calcula la cantidad de sesiones completadas en el día.
  int get _sesionesCompletadas =>
      _sesiones.where((s) => s.completada).length;

  /// Abre un cuadro de diálogo para registrar una nueva sesión en el plan de hoy.
  void _mostrarDialogoNuevaSesion() {
    final controladorMateria = TextEditingController(text: 'Bootcamp IA y Datos');
    final controladorTema = TextEditingController();
    final controladorHora = TextEditingController(text: '08:30 PM - 09:30 PM');

    showDialog(
      context: context,
      builder: (contextDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Nueva Sesión de Estudio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controladorMateria,
                  decoration: const InputDecoration(
                    labelText: 'Materia',
                    prefixIcon: Icon(Icons.class_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controladorTema,
                  decoration: const InputDecoration(
                    labelText: 'Tema a repasar',
                    hintText: 'Ej. Ejercicios prácticos con árboles...',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controladorHora,
                  decoration: const InputDecoration(
                    labelText: 'Horario',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialog),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final temaTexto = controladorTema.text.trim();
                if (temaTexto.isEmpty) return;

                final nuevaSesion = SesionEstudio(
                  id: 'ses_${DateTime.now().millisecondsSinceEpoch}',
                  materia: controladorMateria.text.trim(),
                  tema: temaTexto,
                  hora: controladorHora.text.trim(),
                  duracionMinutos: 60,
                  completada: false,
                );

                setState(() {
                  _sesiones.add(nuevaSesion);
                });

                Navigator.pop(contextDialog);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final parcial = DatosDemo.proximoParcial;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de Estudio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Agregar sesión',
            onPressed: _mostrarDialogoNuevaSesion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TARJETA DEL PRÓXIMO PARCIAL ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5E35B1),
                    Color(0xFF7E57C2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5E35B1).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alarm_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'En ${parcial['diasRestantes']} días',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.school_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Próximo Parcial',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parcial['materia'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parcial['fecha'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Temas: ${parcial['temas']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5E35B1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // Navegamos a la materia correspondiente
                        final materiaParcial = DatosDemo.materias.firstWhere(
                          (m) => m.nombre == parcial['materia'],
                          orElse: () => DatosDemo.materias.first,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetalleMateriaScreen(materia: materiaParcial),
                          ),
                        );
                      },
                      child: const Text(
                        'Estudiar ahora con IA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- ENCABEZADO DE SESIONES DEL DÍA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesiones de Hoy',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_sesionesCompletadas de ${_sesiones.length} completadas',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: esOscuro ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                // Indicador circular de porcentaje completado hoy
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: _sesiones.isNotEmpty
                            ? (_sesionesCompletadas / _sesiones.length)
                            : 0,
                        strokeWidth: 4.5,
                        backgroundColor: esOscuro
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primario,
                        ),
                      ),
                    ),
                    Text(
                      '${_sesiones.isNotEmpty ? ((_sesionesCompletadas / _sesiones.length) * 100).toInt() : 0}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- LISTA DE SESIONES CON CHECKBOX ---
            for (final sesion in _sesiones)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF23202B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: sesion.completada
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                        : (esOscuro
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: esOscuro ? 0.25 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    activeColor: const Color(0xFF2E7D32),
                    value: sesion.completada,
                    onChanged: (valor) {
                      setState(() {
                        sesion.completada = valor ?? false;
                      });
                    },
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primario
                                .withValues(alpha: esOscuro ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sesion.materia,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primario,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${sesion.duracionMinutos} min',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: esOscuro ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sesion.tema,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              decoration: sesion.completada
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: sesion.completada
                                  ? (esOscuro ? Colors.white38 : Colors.black38)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color:
                                    esOscuro ? Colors.white54 : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sesion.hora,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: esOscuro
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
