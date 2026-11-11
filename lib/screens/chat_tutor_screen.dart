import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/materias_repository.dart';
import '../models/mensaje_chat.dart';
import '../providers/ajustes_provider.dart';
import '../providers/ia_provider.dart';
import '../providers/materias_provider.dart';
import '../services/servicio_ia.dart';
import '../theme/app_colors.dart';
import '../widgets/burbuja_chat.dart';
import '../widgets/dialogo_confirmar_borrado.dart';
import '../widgets/indicador_escribiendo.dart';

/// Pantalla de chat con el Tutor IA de una materia.
///
/// El tutor responde con la API de IA usando los apuntes de la materia como
/// contexto, y el texto aparece mientras se escribe (streaming). La
/// conversación se guarda en el dispositivo, así que sigue ahí al volver.
class ChatTutorScreen extends StatefulWidget {
  /// Materia sobre la cual el Tutor IA orientará las respuestas.
  final String materiaId;

  const ChatTutorScreen({super.key, required this.materiaId});

  @override
  State<ChatTutorScreen> createState() => _ChatTutorScreenState();
}

class _ChatTutorScreenState extends State<ChatTutorScreen> {
  /// Preguntas rápidas que se ofrecen como chips sobre el campo de texto.
  static const List<String> _sugerencias = [
    '¿Me explicas el concepto principal?',
    'Dame un ejemplo práctico y cotidiano',
    '¿Cómo suelen evaluar esto en un parcial?',
    'Hazme una pregunta rápida de prueba',
  ];

  /// Controlador para el campo de texto del chat.
  final TextEditingController _controladorTexto = TextEditingController();

  /// Controlador de desplazamiento para anclar la vista al último mensaje.
  final ScrollController _controladorScroll = ScrollController();

  /// Conversación guardada, del mensaje más viejo al más nuevo.
  List<MensajeChat> _mensajes = [];

  /// `true` hasta que se lee la conversación guardada.
  bool _cargando = true;

  /// `true` desde que se envía una pregunta hasta que el tutor termina de responder.
  bool _estaEscribiendo = false;

  /// Lo que el tutor lleva escrito de la respuesta en curso.
  String _respuestaParcial = '';

  /// Mensaje del error de la última respuesta; `null` si no hubo.
  String? _error;

  /// Suscripción a la respuesta en curso, para cancelarla al salir.
  StreamSubscription<String>? _suscripcion;

  late final MateriasRepository _repositorio;

  @override
  void initState() {
    super.initState();
    _repositorio = context.read<MateriasRepository>();
    _cargarConversacion();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _controladorTexto.dispose();
    _controladorScroll.dispose();
    super.dispose();
  }

  Future<void> _cargarConversacion() async {
    List<MensajeChat> mensajes = const [];
    try {
      mensajes = await _repositorio.obtenerMensajesChat(widget.materiaId);
    } catch (_) {
      // Sin historial se empieza una conversación nueva.
    }
    if (!mounted) return;
    setState(() {
      _mensajes = [...mensajes];
      _cargando = false;
    });
    _desplazarAlFinal();
  }

  /// Desplaza suavemente la lista hacia el último mensaje enviado o recibido.
  void _desplazarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controladorScroll.hasClients) {
        _controladorScroll.animateTo(
          _controladorScroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Guarda la pregunta del estudiante y pide la respuesta del tutor.
  Future<void> _enviarMensaje([String? textoOpcional]) async {
    final texto = (textoOpcional ?? _controladorTexto.text).trim();
    if (texto.isEmpty || _estaEscribiendo || _cargando) return;
    if (textoOpcional == null) _controladorTexto.clear();

    MensajeChat mensaje;
    try {
      mensaje = await _repositorio.agregarMensajeChat(
        materiaId: widget.materiaId,
        texto: texto,
        esUsuario: true,
      );
    } catch (_) {
      // Si no se pudo guardar, la conversación sigue solo en pantalla.
      mensaje = MensajeChat(
        id: 'usr_${DateTime.now().microsecondsSinceEpoch}',
        texto: texto,
        esUsuario: true,
        fecha: DateTime.now(),
      );
    }
    if (!mounted) return;
    setState(() => _mensajes.add(mensaje));
    _pedirRespuesta();
  }

  /// Pide al tutor que responda a la conversación actual.
  ///
  /// También sirve para reintentar: no agrega ninguna pregunta nueva.
  void _pedirRespuesta() {
    final materia = context.read<MateriasProvider>().porId(widget.materiaId);
    if (materia == null || _estaEscribiendo) return;

    final Stream<String> respuesta;
    try {
      respuesta = context.read<IaProvider>().servicio.responderTutor(
        materia: materia.nombre,
        nombreEstudiante: context.read<AjustesProvider>().nombre,
        apuntes: materia.apuntes,
        historial: List.of(_mensajes),
      );
    } on ErrorIa catch (fallo) {
      setState(() => _error = fallo.mensaje);
      return;
    }

    setState(() {
      _estaEscribiendo = true;
      _respuestaParcial = '';
      _error = null;
    });
    _desplazarAlFinal();

    _suscripcion = respuesta.listen(
      (parte) {
        setState(() => _respuestaParcial += parte);
        _desplazarAlFinal();
      },
      onError: (Object fallo) {
        // Lo que alcanzó a llegar se descarta: una respuesta a medias confunde.
        setState(() {
          _estaEscribiendo = false;
          _respuestaParcial = '';
          _error = fallo is ErrorIa
              ? fallo.mensaje
              : 'El tutor no pudo responder. Inténtalo de nuevo.';
        });
      },
      onDone: _alTerminarRespuesta,
      cancelOnError: true,
    );
  }

  /// Guarda la respuesta completa del tutor en la conversación.
  Future<void> _alTerminarRespuesta() async {
    final texto = _respuestaParcial.trim();
    if (texto.isEmpty) {
      setState(() {
        _estaEscribiendo = false;
        _error = 'El tutor no respondió. Inténtalo de nuevo.';
      });
      return;
    }

    MensajeChat mensaje;
    try {
      mensaje = await _repositorio.agregarMensajeChat(
        materiaId: widget.materiaId,
        texto: texto,
        esUsuario: false,
      );
    } catch (_) {
      mensaje = MensajeChat(
        id: 'ia_${DateTime.now().microsecondsSinceEpoch}',
        texto: texto,
        esUsuario: false,
        fecha: DateTime.now(),
      );
    }
    if (!mounted) return;
    setState(() {
      _mensajes.add(mensaje);
      _respuestaParcial = '';
      _estaEscribiendo = false;
    });
    _desplazarAlFinal();
  }

  /// Borra la conversación guardada, previa confirmación.
  Future<void> _nuevaConversacion() async {
    final confirmado = await confirmarBorrado(
      context,
      titulo: 'Nueva conversación',
      mensaje: 'Se borrarán los mensajes de este chat con el tutor.',
    );
    if (!confirmado) return;
    // Sin esperar: cancelar una respuesta que ya terminó puede no avisar nunca.
    unawaited(_suscripcion?.cancel());
    _suscripcion = null;
    try {
      await _repositorio.borrarMensajesChat(widget.materiaId);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _mensajes = [];
      _respuestaParcial = '';
      _estaEscribiendo = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final materia = context.watch<MateriasProvider>().porId(widget.materiaId);
    if (materia == null) {
      // La materia se borró mientras el chat estaba abierto.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }
    final nombre = context.select<AjustesProvider, String>((a) => a.nombre);

    // El saludo se muestra siempre arriba pero no se guarda ni se envía a la IA.
    final saludo = MensajeChat(
      id: 'saludo',
      texto:
          '¡Hola, $nombre! Soy tu Tutor IA para ${materia.nombre}. '
          '${materia.apuntes.isEmpty ? 'Todavía no tienes apuntes aquí, pero puedo ayudarte con la materia.' : 'Ya leí tus apuntes.'} '
          '¿Qué duda quieres que aclaremos hoy?',
      esUsuario: false,
      fecha: _mensajes.isEmpty ? DateTime.now() : _mensajes.first.fecha,
    );
    final burbujas = [
      saludo,
      ..._mensajes,
      if (_respuestaParcial.isNotEmpty)
        MensajeChat(
          id: 'respuesta-en-curso',
          texto: _respuestaParcial,
          esUsuario: false,
          fecha: DateTime.now(),
        ),
    ];
    // Los tres puntos solo se ven mientras el tutor piensa, antes del primer texto.
    final pensando = _estaEscribiendo && _respuestaParcial.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Tutor IA: ${materia.nombre}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _error == null
                        ? const Color(0xFF4CAF50)
                        : tema.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _estaEscribiendo
                      ? (pensando ? 'Pensando...' : 'Escribiendo...')
                      : 'Responde con tus apuntes',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: esOscuro ? Colors.white60 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_mensajes.isNotEmpty)
            IconButton(
              key: const Key('nueva-conversacion'),
              tooltip: 'Nueva conversación',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _nuevaConversacion,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- LISTA DE MENSAJES CON SCROLL ---
            Expanded(
              child: ListView.builder(
                controller: _controladorScroll,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: burbujas.length + (pensando ? 1 : 0),
                itemBuilder: (context, index) {
                  // Si llegamos al final y la IA está pensando, mostramos el indicador animado
                  if (index == burbujas.length) {
                    return const IndicadorEscribiendo();
                  }
                  return BurbujaChat(mensaje: burbujas[index]);
                },
              ),
            ),

            // --- AVISO DE ERROR CON BOTÓN PARA REINTENTAR ---
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: tema.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _error!,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    // Solo se puede reintentar si quedó una pregunta sin responder.
                    if (_mensajes.isNotEmpty && _mensajes.last.esUsuario)
                      TextButton(
                        key: const Key('reintentar-tutor'),
                        onPressed: _pedirRespuesta,
                        child: const Text('Reintentar'),
                      ),
                  ],
                ),
              ),

            // --- CHIPS CON SUGERENCIAS RÁPIDAS DE PREGUNTA ---
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sugerencias.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sugerencia = _sugerencias[index];
                  return ActionChip(
                    avatar: const Icon(
                      Icons.tips_and_updates_rounded,
                      size: 15,
                      color: AppColors.primario,
                    ),
                    label: Text(sugerencia),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: esOscuro ? Colors.white : Colors.black87,
                    ),
                    backgroundColor: esOscuro
                        ? const Color(0xFF282433)
                        : const Color(0xFFEDE7F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide.none,
                    onPressed: () => _enviarMensaje(sugerencia),
                  );
                },
              ),
            ),

            // --- CAMPO DE TEXTO INFERIOR Y BOTÓN DE ENVÍO ---
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF1D1B20) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controladorTexto,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Pregúntale a tu Tutor IA...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: esOscuro ? Colors.white38 : Colors.black38,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: esOscuro
                            ? const Color(0xFF2B2831)
                            : const Color(0xFFF3EDF7),
                      ),
                      onSubmitted: (_) => _enviarMensaje(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.degradadoEncabezado,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primario.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _enviarMensaje(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
