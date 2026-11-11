import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evaluacion.dart';
import '../models/materia.dart';
import '../models/resultados_ia.dart';
import '../models/sesion_estudio.dart';
import '../providers/ia_provider.dart';
import '../providers/materias_provider.dart';
import '../providers/plan_provider.dart';
import '../services/servicio_ia.dart';
import '../theme/app_colors.dart';
import '../utils/plan.dart';
import '../utils/reloj.dart';
import '../widgets/dialogo_clave_ia.dart';
import '../widgets/dialogo_confirmar_borrado.dart';
import '../widgets/formulario_plan.dart';
import 'detalle_materia_screen.dart';

/// Qué se puede agregar al plan desde el botón de la barra superior.
enum _Nuevo { sesion, evaluacion }

/// Acciones al mantener pulsada una sesión o una evaluación.
enum _Accion { editar, borrar }

/// Pantalla del Plan de Estudio del estudiante.
///
/// Presenta la tarjeta de la próxima evaluación con su cuenta regresiva, las
/// demás evaluaciones pendientes y las sesiones de estudio (de hoy, atrasadas y
/// próximas) con casillas para marcarlas. Todo se guarda en el dispositivo. La
/// IA puede proponer las sesiones para preparar una evaluación.
class PlanEstudioScreen extends StatefulWidget {
  const PlanEstudioScreen({super.key});

  @override
  State<PlanEstudioScreen> createState() => _PlanEstudioScreenState();
}

class _PlanEstudioScreenState extends State<PlanEstudioScreen> {
  /// Evita pedir dos planes a la IA a la vez.
  bool _generandoPlan = false;

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  /// Abre el formulario de evaluación; antes hace falta tener alguna materia.
  void _nuevaEvaluacion() {
    if (context.read<MateriasProvider>().materias.isEmpty) {
      _avisar('Crea una materia en Inicio para agregarle una evaluación.');
      return;
    }
    mostrarFormularioEvaluacion(context);
  }

  /// Muestra "Editar" y "Borrar" en una hoja y devuelve lo elegido.
  Future<_Accion?> _elegirAccion() {
    return showModalBottomSheet<_Accion>(
      context: context,
      builder: (contextHoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('opcion-editar-plan'),
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar'),
              onTap: () => Navigator.pop(contextHoja, _Accion.editar),
            ),
            ListTile(
              key: const Key('opcion-borrar-plan'),
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Borrar'),
              onTap: () => Navigator.pop(contextHoja, _Accion.borrar),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _opcionesEvaluacion(Evaluacion evaluacion) async {
    final accion = await _elegirAccion();
    if (!mounted || accion == null) return;
    switch (accion) {
      case _Accion.editar:
        await mostrarFormularioEvaluacion(context, evaluacion: evaluacion);
      case _Accion.borrar:
        final provider = context.read<PlanProvider>();
        final confirmado = await confirmarBorrado(
          context,
          titulo: 'Borrar evaluación',
          mensaje:
              'Se borrará "${evaluacion.titulo}". Las sesiones de estudio se conservan.',
        );
        if (confirmado) await provider.borrarEvaluacion(evaluacion.id);
    }
  }

  Future<void> _opcionesSesion(SesionEstudio sesion) async {
    final accion = await _elegirAccion();
    if (!mounted || accion == null) return;
    switch (accion) {
      case _Accion.editar:
        await mostrarFormularioSesion(context, sesion: sesion);
      case _Accion.borrar:
        final provider = context.read<PlanProvider>();
        final confirmado = await confirmarBorrado(
          context,
          titulo: 'Borrar sesión',
          mensaje: 'Se borrará "${sesion.tema}" del plan.',
        );
        if (confirmado) await provider.borrarSesion(sesion.id);
    }
  }

  /// Pide a la IA las sesiones para preparar una evaluación y, si el usuario
  /// las acepta, las agrega al plan.
  Future<void> _planConIa(Evaluacion evaluacion, Materia materia) async {
    if (_generandoPlan) return;
    if (!await asegurarClaveIa(context)) return;
    if (!mounted) return;

    final ia = context.read<IaProvider>();
    final plan = context.read<PlanProvider>();
    final hoy = context.read<Reloj>()();
    final navegador = Navigator.of(context);

    setState(() => _generandoPlan = true);
    // Diálogo de espera que no se puede cerrar mientras la IA arma el plan.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Armando tu plan con IA...')),
            ],
          ),
        ),
      ),
    );

    List<SesionSugerida>? sugeridas;
    String? error;
    try {
      sugeridas = await ia.servicio.sugerirPlan(
        materia: materia.nombre,
        evaluacion: evaluacion.titulo,
        temas: evaluacion.temas,
        apuntes: materia.apuntes,
        hoy: hoy,
        fechaEvaluacion: evaluacion.fecha,
      );
    } on ErrorIa catch (fallo) {
      error = fallo.mensaje;
    } catch (_) {
      error = 'No se pudo armar el plan. Inténtalo de nuevo.';
    }
    navegador.pop(); // cierra el diálogo de espera
    if (!mounted) return;
    setState(() => _generandoPlan = false);

    if (sugeridas == null) {
      _avisar(error ?? 'No se pudo armar el plan.');
      return;
    }

    final aceptado = await _mostrarPlanSugerido(materia, sugeridas);
    if (!mounted || !aceptado) return;
    try {
      await plan.agregarSesionesSugeridas(materia.id, sugeridas);
      if (mounted) _avisar('Se agregaron ${sugeridas.length} sesiones a tu plan.');
    } catch (_) {
      if (mounted) _avisar('No se pudieron guardar las sesiones.');
    }
  }

  /// Muestra las sesiones que propone la IA; devuelve `true` si se aceptan.
  Future<bool> _mostrarPlanSugerido(
    Materia materia,
    List<SesionSugerida> sugeridas,
  ) async {
    final aceptado = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) {
        final tema = Theme.of(contextDialogo);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Plan sugerido por la IA'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sugeridas.length,
              separatorBuilder: (_, _) => const Divider(height: 18),
              itemBuilder: (_, indice) {
                final sesion = sugeridas[indice];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatearFechaLarga(sesion.inicio)} · '
                      '${formatearHora(sesion.inicio)} · '
                      '${sesion.duracionMinutos} min',
                      style: tema.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(sesion.tema, style: tema.textTheme.bodyMedium),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialogo, false),
              child: const Text('Descartar'),
            ),
            ElevatedButton(
              key: const Key('aceptar-plan-ia'),
              onPressed: () => Navigator.pop(contextDialogo, true),
              child: const Text('Agregar al plan'),
            ),
          ],
        );
      },
    );
    return aceptado ?? false;
  }

  void _abrirMateria(Materia materia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleMateriaScreen(materia: materia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final plan = context.watch<PlanProvider>();
    final materias = context.watch<MateriasProvider>();
    final hoy = context.watch<Reloj>()();

    final pendientes = evaluacionesPendientes(plan.evaluaciones, hoy);
    final deHoy = sesionesDelDia(plan.sesiones, hoy);
    final proximas = sesionesProximas(plan.sesiones, hoy);
    // Sesiones de días anteriores que quedaron sin hacer.
    final atrasadas = [
      for (final sesion in plan.sesiones)
        if (!sesion.completada && soloFecha(sesion.inicio).isBefore(soloFecha(hoy)))
          sesion,
    ];
    final completadasHoy = deHoy.where((sesion) => sesion.completada).length;
    final avanceHoy = deHoy.isEmpty ? 0.0 : completadasHoy / deHoy.length;

    Widget seccion(String titulo) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Text(
        titulo,
        style: tema.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de Estudio'),
        actions: [
          PopupMenuButton<_Nuevo>(
            key: const Key('agregar-al-plan'),
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Agregar al plan',
            onSelected: (nuevo) {
              switch (nuevo) {
                case _Nuevo.sesion:
                  mostrarFormularioSesion(context);
                case _Nuevo.evaluacion:
                  _nuevaEvaluacion();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                key: Key('nueva-sesion'),
                value: _Nuevo.sesion,
                child: Text('Nueva sesión de estudio'),
              ),
              PopupMenuItem(
                key: Key('nueva-evaluacion'),
                value: _Nuevo.evaluacion,
                child: Text('Nueva evaluación'),
              ),
            ],
          ),
        ],
      ),
      body: plan.cargando
          ? const Center(child: CircularProgressIndicator())
          : plan.error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(plan.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: plan.cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TARJETA DE LA PRÓXIMA EVALUACIÓN ---
                  if (pendientes.isEmpty)
                    _SinEvaluaciones(onAgregar: _nuevaEvaluacion)
                  else
                    _TarjetaEvaluacion(
                      evaluacion: pendientes.first,
                      materia: materias.porId(pendientes.first.materiaId),
                      dias: diasRestantes(pendientes.first.fecha, hoy),
                      generandoPlan: _generandoPlan,
                      onOpciones: () => _opcionesEvaluacion(pendientes.first),
                      onEstudiar: _abrirMateria,
                      onPlanConIa: (materia) =>
                          _planConIa(pendientes.first, materia),
                    ),

                  // --- DEMÁS EVALUACIONES PENDIENTES ---
                  if (pendientes.length > 1) ...[
                    const SizedBox(height: 12),
                    seccion('Otras evaluaciones'),
                    for (final evaluacion in pendientes.skip(1))
                      _FilaEvaluacion(
                        evaluacion: evaluacion,
                        materia: materias.porId(evaluacion.materiaId),
                        dias: diasRestantes(evaluacion.fecha, hoy),
                        onOpciones: () => _opcionesEvaluacion(evaluacion),
                      ),
                  ],

                  const SizedBox(height: 16),

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
                            deHoy.isEmpty
                                ? formatearFechaLarga(hoy)
                                : '$completadasHoy de ${deHoy.length} completadas',
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
                              value: avanceHoy,
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
                            '${(avanceHoy * 100).round()}%',
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
                  if (deHoy.isEmpty)
                    _SinSesiones(
                      onAgregar: () => mostrarFormularioSesion(context),
                    )
                  else
                    for (final sesion in deHoy)
                      _TarjetaSesion(
                        sesion: sesion,
                        materia: materias.porId(sesion.materiaId ?? ''),
                        mostrarDia: false,
                        onMarcar: (valor) =>
                            plan.marcarSesion(sesion.id, completada: valor),
                        onOpciones: () => _opcionesSesion(sesion),
                      ),

                  if (atrasadas.isNotEmpty) ...[
                    seccion('Atrasadas'),
                    for (final sesion in atrasadas)
                      _TarjetaSesion(
                        sesion: sesion,
                        materia: materias.porId(sesion.materiaId ?? ''),
                        mostrarDia: true,
                        onMarcar: (valor) =>
                            plan.marcarSesion(sesion.id, completada: valor),
                        onOpciones: () => _opcionesSesion(sesion),
                      ),
                  ],

                  if (proximas.isNotEmpty) ...[
                    seccion('Próximas sesiones'),
                    for (final sesion in proximas)
                      _TarjetaSesion(
                        sesion: sesion,
                        materia: materias.porId(sesion.materiaId ?? ''),
                        mostrarDia: true,
                        onMarcar: (valor) =>
                            plan.marcarSesion(sesion.id, completada: valor),
                        onOpciones: () => _opcionesSesion(sesion),
                      ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

/// Tarjeta destacada de la próxima evaluación, con cuenta regresiva y acciones.
class _TarjetaEvaluacion extends StatelessWidget {
  final Evaluacion evaluacion;

  /// Materia de la evaluación; `null` si todavía no cargó.
  final Materia? materia;

  /// Días que faltan para la evaluación.
  final int dias;

  /// `true` mientras la IA arma el plan (desactiva el botón).
  final bool generandoPlan;

  final VoidCallback onOpciones;
  final ValueChanged<Materia> onEstudiar;
  final ValueChanged<Materia> onPlanConIa;

  const _TarjetaEvaluacion({
    required this.evaluacion,
    required this.materia,
    required this.dias,
    required this.generandoPlan,
    required this.onOpciones,
    required this.onEstudiar,
    required this.onPlanConIa,
  });

  @override
  Widget build(BuildContext context) {
    final materia = this.materia;
    const morado = Color(0xFF5E35B1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [morado, Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: morado.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const Key('tarjeta-proxima-evaluacion'),
          borderRadius: BorderRadius.circular(24),
          onLongPress: onOpciones,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                            textoDiasRestantes(dias),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('opciones-proxima-evaluacion'),
                      tooltip: 'Editar o borrar',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: onOpciones,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Próxima evaluación',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  evaluacion.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${materia?.nombre ?? 'Materia'} · '
                  '${formatearFechaLarga(evaluacion.fecha)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                if (evaluacion.temas.isNotEmpty) ...[
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
                            'Temas: ${evaluacion.temas}',
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
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('estudiar-evaluacion'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: morado,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: materia == null
                            ? null
                            : () => onEstudiar(materia),
                        child: const Text(
                          'Estudiar ahora',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('plan-con-ia'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: materia == null || generandoPlan
                            ? null
                            : () => onPlanConIa(materia),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text(
                          'Plan con IA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que invita a agregar la primera evaluación.
class _SinEvaluaciones extends StatelessWidget {
  final VoidCallback onAgregar;

  const _SinEvaluaciones({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primario.withValues(alpha: esOscuro ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_available_rounded, color: AppColors.primario),
          const SizedBox(height: 10),
          Text(
            'Sin evaluaciones a la vista',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega tu próximo parcial y la IA te arma las sesiones de '
            'estudio para llegar preparado.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: esOscuro ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const Key('agregar-primera-evaluacion'),
            onPressed: onAgregar,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar evaluación'),
          ),
        ],
      ),
    );
  }
}

/// Fila compacta para las evaluaciones que vienen después de la próxima.
class _FilaEvaluacion extends StatelessWidget {
  final Evaluacion evaluacion;
  final Materia? materia;
  final int dias;
  final VoidCallback onOpciones;

  const _FilaEvaluacion({
    required this.evaluacion,
    required this.materia,
    required this.dias,
    required this.onOpciones,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF23202B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: esOscuro
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: const Icon(
            Icons.assignment_rounded,
            color: AppColors.primario,
          ),
          title: Text(
            evaluacion.titulo,
            style: tema.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${materia?.nombre ?? 'Materia'} · '
            '${formatearFechaLarga(evaluacion.fecha)}',
            style: tema.textTheme.bodySmall,
          ),
          trailing: Text(
            textoDiasRestantes(dias),
            style: tema.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primario,
            ),
          ),
          onTap: onOpciones,
          onLongPress: onOpciones,
        ),
      ),
    );
  }
}

/// Mensaje cuando no hay sesiones para hoy, con acceso para agregar una.
class _SinSesiones extends StatelessWidget {
  final VoidCallback onAgregar;

  const _SinSesiones({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF23202B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'No tienes sesiones planeadas para hoy.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('agregar-sesion-hoy'),
            onPressed: onAgregar,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Agregar sesión'),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una sesión de estudio con casilla para marcarla como hecha.
class _TarjetaSesion extends StatelessWidget {
  final SesionEstudio sesion;

  /// Materia de la sesión; `null` si es estudio libre.
  final Materia? materia;

  /// Si es `true`, muestra también el día (para sesiones que no son de hoy).
  final bool mostrarDia;

  final ValueChanged<bool> onMarcar;
  final VoidCallback onOpciones;

  const _TarjetaSesion({
    required this.sesion,
    required this.materia,
    required this.mostrarDia,
    required this.onMarcar,
    required this.onOpciones,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final cuando =
        '${formatearHora(sesion.inicio)} - ${formatearHora(sesion.fin)}';

    return Container(
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
            color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: GestureDetector(
          onLongPress: onOpciones,
          child: CheckboxListTile(
            key: Key('sesion-${sesion.id}'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            activeColor: const Color(0xFF2E7D32),
            value: sesion.completada,
            onChanged: (valor) => onMarcar(valor ?? false),
            title: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primario.withValues(
                        alpha: esOscuro ? 0.25 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      materia?.nombre ?? 'Estudio libre',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primario,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                        color: esOscuro ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mostrarDia
                              ? '${formatearFechaLarga(sesion.inicio)} · $cuando'
                              : cuando,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: esOscuro ? Colors.white54 : Colors.black45,
                          ),
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
    );
  }
}
