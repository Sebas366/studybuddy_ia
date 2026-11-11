import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evaluacion.dart';
import '../models/materia.dart';
import '../models/sesion_estudio.dart';
import '../providers/materias_provider.dart';
import '../providers/plan_provider.dart';
import '../utils/formato_fecha.dart';
import '../utils/plan.dart';
import '../utils/reloj.dart';
import '../utils/validadores.dart';

/// Muestra la hoja modal para crear una evaluación o editar una existente.
///
/// Devuelve `true` si se guardó.
Future<bool> mostrarFormularioEvaluacion(
  BuildContext context, {
  Evaluacion? evaluacion,
}) async {
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FormularioEvaluacion(evaluacion: evaluacion),
  );
  return guardado ?? false;
}

/// Muestra la hoja modal para crear una sesión de estudio o editar una existente.
///
/// Devuelve `true` si se guardó.
Future<bool> mostrarFormularioSesion(
  BuildContext context, {
  SesionEstudio? sesion,
}) async {
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FormularioSesion(sesion: sesion),
  );
  return guardado ?? false;
}

/// Marco común de las hojas del plan: fondo, barra de arrastre y título.
class _HojaPlan extends StatelessWidget {
  final String titulo;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;

  const _HojaPlan({
    required this.titulo,
    required this.formKey,
    required this.campos,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final medidas = MediaQuery.of(context);
    // Con el teclado abierto ya se respeta su altura; si no, se deja libre la
    // barra de navegación del sistema para que no tape el botón "Guardar".
    final margenSistema = medidas.viewInsets.bottom > 0
        ? 0.0
        : medidas.padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: medidas.viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + margenSistema),
        decoration: BoxDecoration(
          color: esOscuro ? const Color(0xFF23202B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  titulo,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ...campos,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón con aspecto de campo que muestra un valor (fecha, hora) y abre su selector.
class _CampoSelector extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;
  final VoidCallback onTap;

  const _CampoSelector({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono),
        ),
        child: Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Lista desplegable para elegir la materia; con [opcional] permite "Sin materia".
class _CampoMateria extends StatelessWidget {
  final List<Materia> materias;
  final String? valor;
  final bool opcional;
  final ValueChanged<String?> onChanged;

  const _CampoMateria({
    required this.materias,
    required this.valor,
    required this.opcional,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      key: const Key('campo-materia-plan'),
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Materia',
        prefixIcon: Icon(Icons.book_rounded),
      ),
      items: [
        if (opcional)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Sin materia'),
          ),
        for (final materia in materias)
          DropdownMenuItem<String?>(
            value: materia.id,
            child: Text(materia.nombre, overflow: TextOverflow.ellipsis),
          ),
      ],
      validator: (elegida) =>
          !opcional && elegida == null ? 'Elige la materia.' : null,
      onChanged: onChanged,
    );
  }
}

/// Avisa con un SnackBar que no se pudo guardar.
void _avisarFallo(ScaffoldMessengerState mensajero, String que) {
  mensajero.showSnackBar(
    SnackBar(
      content: Text('No se pudo guardar $que. Inténtalo de nuevo.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// -----------------------------------------------------------------------------
// Evaluación
// -----------------------------------------------------------------------------

class _FormularioEvaluacion extends StatefulWidget {
  final Evaluacion? evaluacion;

  const _FormularioEvaluacion({this.evaluacion});

  @override
  State<_FormularioEvaluacion> createState() => _FormularioEvaluacionState();
}

class _FormularioEvaluacionState extends State<_FormularioEvaluacion> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controladorTitulo;
  late final TextEditingController _controladorTemas;
  String? _materiaId;
  late DateTime _fecha;

  /// Evita crear dos registros si el usuario toca "Guardar" varias veces seguidas.
  bool _guardando = false;

  bool get _esEdicion => widget.evaluacion != null;

  @override
  void initState() {
    super.initState();
    final evaluacion = widget.evaluacion;
    final materias = context.read<MateriasProvider>().materias;
    final hoy = soloFecha(context.read<Reloj>()());
    _controladorTitulo = TextEditingController(text: evaluacion?.titulo ?? '');
    _controladorTemas = TextEditingController(text: evaluacion?.temas ?? '');
    _materiaId =
        evaluacion?.materiaId ?? (materias.isEmpty ? null : materias.first.id);
    // Una evaluación nueva se propone para dentro de una semana.
    _fecha =
        evaluacion?.fecha ?? DateTime(hoy.year, hoy.month, hoy.day + 7);
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorTemas.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = soloFecha(context.read<Reloj>()());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(hoy) ? hoy : _fecha,
      firstDate: _fecha.isBefore(hoy) ? _fecha : hoy,
      lastDate: DateTime(hoy.year + 2, hoy.month, hoy.day),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    _guardando = true;

    final provider = context.read<PlanProvider>();
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    try {
      if (_esEdicion) {
        await provider.actualizarEvaluacion(
          id: widget.evaluacion!.id,
          materiaId: _materiaId!,
          titulo: _controladorTitulo.text,
          fecha: _fecha,
          temas: _controladorTemas.text,
        );
      } else {
        await provider.crearEvaluacion(
          materiaId: _materiaId!,
          titulo: _controladorTitulo.text,
          fecha: _fecha,
          temas: _controladorTemas.text,
        );
      }
    } catch (_) {
      _guardando = false;
      _avisarFallo(mensajero, 'la evaluación');
      return;
    }
    navegador.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final materias = context.watch<MateriasProvider>().materias;

    return _HojaPlan(
      titulo: _esEdicion ? 'Editar evaluación' : 'Nueva evaluación',
      formKey: _formKey,
      campos: [
        _CampoMateria(
          materias: materias,
          valor: _materiaId,
          opcional: false,
          onChanged: (id) => setState(() => _materiaId = id),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('campo-titulo-evaluacion'),
          controller: _controladorTitulo,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          validator: validarTituloEvaluacion,
          decoration: const InputDecoration(
            labelText: 'Evaluación',
            hintText: 'Ej. Primer parcial',
            prefixIcon: Icon(Icons.assignment_rounded),
          ),
        ),
        const SizedBox(height: 14),
        _CampoSelector(
          key: const Key('campo-fecha-evaluacion'),
          etiqueta: 'Fecha',
          valor: formatearFechaLarga(_fecha),
          icono: Icons.event_rounded,
          onTap: _elegirFecha,
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('campo-temas-evaluacion'),
          controller: _controladorTemas,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Temas que entran (opcional)',
            hintText: 'Ej. Pipeline, riesgos y memoria caché',
            prefixIcon: Icon(Icons.bookmark_rounded),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('guardar-evaluacion'),
            onPressed: _guardar,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Guardar evaluación'),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Sesión de estudio
// -----------------------------------------------------------------------------

class _FormularioSesion extends StatefulWidget {
  final SesionEstudio? sesion;

  const _FormularioSesion({this.sesion});

  @override
  State<_FormularioSesion> createState() => _FormularioSesionState();
}

class _FormularioSesionState extends State<_FormularioSesion> {
  /// Duraciones que se ofrecen, en minutos.
  static const List<int> _duraciones = [25, 30, 45, 60, 90, 120];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controladorTema;
  String? _materiaId;
  late DateTime _dia;
  late TimeOfDay _hora;
  late int _duracion;

  /// Evita crear dos registros si el usuario toca "Guardar" varias veces seguidas.
  bool _guardando = false;

  bool get _esEdicion => widget.sesion != null;

  @override
  void initState() {
    super.initState();
    final sesion = widget.sesion;
    final ahora = context.read<Reloj>()();
    _controladorTema = TextEditingController(text: sesion?.tema ?? '');
    _materiaId = sesion?.materiaId;
    _dia = soloFecha(sesion?.inicio ?? ahora);
    // Una sesión nueva se propone para la próxima hora en punto.
    _hora = sesion != null
        ? TimeOfDay.fromDateTime(sesion.inicio)
        : TimeOfDay(hour: (ahora.hour + 1) % 24, minute: 0);
    _duracion = sesion?.duracionMinutos ?? 60;
  }

  @override
  void dispose() {
    _controladorTema.dispose();
    super.dispose();
  }

  Future<void> _elegirDia() async {
    final hoy = soloFecha(context.read<Reloj>()());
    final elegido = await showDatePicker(
      context: context,
      initialDate: _dia,
      firstDate: _dia.isBefore(hoy) ? _dia : hoy,
      lastDate: DateTime(hoy.year + 1, hoy.month, hoy.day),
    );
    if (elegido != null) setState(() => _dia = elegido);
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(context: context, initialTime: _hora);
    if (elegida != null) setState(() => _hora = elegida);
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    _guardando = true;

    final provider = context.read<PlanProvider>();
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final inicio = DateTime(
      _dia.year,
      _dia.month,
      _dia.day,
      _hora.hour,
      _hora.minute,
    );
    try {
      if (_esEdicion) {
        await provider.actualizarSesion(
          id: widget.sesion!.id,
          materiaId: _materiaId,
          tema: _controladorTema.text,
          inicio: inicio,
          duracionMinutos: _duracion,
        );
      } else {
        await provider.crearSesion(
          materiaId: _materiaId,
          tema: _controladorTema.text,
          inicio: inicio,
          duracionMinutos: _duracion,
        );
      }
    } catch (_) {
      _guardando = false;
      _avisarFallo(mensajero, 'la sesión');
      return;
    }
    navegador.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final materias = context.watch<MateriasProvider>().materias;
    // Una sesión editada puede tener una duración que no está en la lista.
    final duraciones = {..._duraciones, _duracion}.toList()..sort();
    final inicio = DateTime(2000, 1, 1, _hora.hour, _hora.minute);

    return _HojaPlan(
      titulo: _esEdicion ? 'Editar sesión' : 'Nueva sesión de estudio',
      formKey: _formKey,
      campos: [
        _CampoMateria(
          materias: materias,
          valor: _materiaId,
          opcional: true,
          onChanged: (id) => setState(() => _materiaId = id),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('campo-tema-sesion'),
          controller: _controladorTema,
          textCapitalization: TextCapitalization.sentences,
          validator: validarTemaSesion,
          decoration: const InputDecoration(
            labelText: '¿Qué vas a estudiar?',
            hintText: 'Ej. Repaso de riesgos del pipeline',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _CampoSelector(
                key: const Key('campo-dia-sesion'),
                etiqueta: 'Día',
                valor: formatearFecha(_dia),
                icono: Icons.event_rounded,
                onTap: _elegirDia,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _CampoSelector(
                key: const Key('campo-hora-sesion'),
                etiqueta: 'Hora',
                valor: formatearHora(inicio),
                icono: Icons.access_time_rounded,
                onTap: _elegirHora,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          key: const Key('campo-duracion-sesion'),
          initialValue: _duracion,
          decoration: const InputDecoration(
            labelText: 'Duración',
            prefixIcon: Icon(Icons.timelapse_rounded),
          ),
          items: [
            for (final minutos in duraciones)
              DropdownMenuItem(value: minutos, child: Text('$minutos min')),
          ],
          onChanged: (minutos) {
            if (minutos != null) setState(() => _duracion = minutos);
          },
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('guardar-sesion'),
            onPressed: _guardar,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Guardar sesión'),
          ),
        ),
      ],
    );
  }
}
