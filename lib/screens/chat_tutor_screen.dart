import 'package:flutter/material.dart';
import '../data/datos_demo.dart';
import '../models/materia.dart';
import '../models/mensaje_chat.dart';
import '../theme/app_colors.dart';
import '../widgets/burbuja_chat.dart';
import '../widgets/indicador_escribiendo.dart';

/// Pantalla de chat conversacional con el Tutor IA pedagógico.
///
/// Implementa burbujas de mensaje, avatar de la IA, indicador reactivo de pensamiento,
/// chips interactivos con preguntas sugeridas y simulación de respuesta con 1.3 s de retardo.
class ChatTutorScreen extends StatefulWidget {
  /// Materia sobre la cual el Tutor IA orientará las respuestas.
  final Materia materia;

  const ChatTutorScreen({
    super.key,
    required this.materia,
  });

  @override
  State<ChatTutorScreen> createState() => _ChatTutorScreenState();
}

class _ChatTutorScreenState extends State<ChatTutorScreen> {
  /// Controlador para el campo de texto del chat.
  final TextEditingController _controladorTexto = TextEditingController();

  /// Controlador de desplazamiento para anclar automáticamente la vista al último mensaje.
  final ScrollController _controladorScroll = ScrollController();

  /// Historial dinámico de mensajes en la sesión actual.
  final List<MensajeChat> _mensajes = [];

  /// Bandera que indica si la IA está generando su respuesta.
  bool _estaEscribiendo = false;

  /// Índice rotativo para ciclar entre las respuestas simuladas de la materia.
  int _indiceRespuestaIa = 0;

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida inicial generado por la IA personalizado según la materia
    _mensajes.add(
      MensajeChat(
        id: 'msg_inicio',
        texto:
            '¡Hola, Edwin! Soy tu Tutor IA para ${widget.materia.nombre}. ¿Qué concepto o duda te gustaría que aclaremos hoy?',
        esUsuario: false,
        fecha: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _controladorScroll.dispose();
    super.dispose();
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

  /// Procesa el envío de un mensaje de usuario y activa la simulación de respuesta de la IA.
  Future<void> _enviarMensaje([String? textoOpcional]) async {
    final texto = textoOpcional ?? _controladorTexto.text.trim();
    if (texto.isEmpty || _estaEscribiendo) return;

    if (textoOpcional == null) {
      _controladorTexto.clear();
    }

    // 1. Agregar el mensaje del estudiante
    final nuevoMensajeUsuario = MensajeChat(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      texto: texto,
      esUsuario: true,
      fecha: DateTime.now(),
    );

    setState(() {
      _mensajes.add(nuevoMensajeUsuario);
      _estaEscribiendo = true;
    });

    _desplazarAlFinal();

    // 2. Simulación de latencia de red y razonamiento de IA: exactamente 1.3 s (1300 ms)
    await Future.delayed(const Duration(milliseconds: 1300));

    if (!mounted) return;

    // 3. Obtener respuesta pedagógica simulada del banco de la materia
    final respuestas = widget.materia.respuestasSimuladasIa;
    final respuestaTexto = respuestas.isNotEmpty
        ? respuestas[_indiceRespuestaIa % respuestas.length]
        : 'He procesado tu consulta sobre ${widget.materia.nombre}. Repasa los conceptos clave en tus apuntes para consolidar este tema.';

    _indiceRespuestaIa++;

    final nuevoMensajeIa = MensajeChat(
      id: 'ia_${DateTime.now().millisecondsSinceEpoch}',
      texto: respuestaTexto,
      esUsuario: false,
      fecha: DateTime.now(),
    );

    // 4. Actualizar estado y quitar indicador de escritura
    setState(() {
      _mensajes.add(nuevoMensajeIa);
      _estaEscribiendo = false;
    });

    _desplazarAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Tutor IA: ${widget.materia.nombre}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _estaEscribiendo ? 'Pensando...' : 'En línea 24/7',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: esOscuro ? Colors.white60 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                itemCount: _mensajes.length + (_estaEscribiendo ? 1 : 0),
                itemBuilder: (context, index) {
                  // Si llegamos al final y la IA está pensando, mostramos el indicador animado
                  if (index == _mensajes.length && _estaEscribiendo) {
                    return const IndicadorEscribiendo();
                  }
                  return BurbujaChat(mensaje: _mensajes[index]);
                },
              ),
            ),

            // --- CHIPS CON SUGERENCIAS RÁPIDAS DE PREGUNTA ---
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: DatosDemo.sugerenciasChat.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sugerencia = DatosDemo.sugerenciasChat[index];
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
