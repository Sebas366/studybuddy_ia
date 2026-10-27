import 'package:flutter/material.dart';
import '../models/materia.dart';
import '../models/apunte.dart';
import '../models/pregunta.dart';
import '../models/sesion_estudio.dart';
import '../theme/app_colors.dart';

/// Proveedor centralizado de datos de prueba (Mock Data) para StudyBuddy IA.
///
/// Contiene 3 materias universitarias completas, con 2 apuntes de 4 ideas clave cada uno,
/// 5 preguntas de autoevaluación con explicación pedagógica, 3 respuestas de IA simuladas,
/// sesiones del día y estadísticas de rendimiento semanal.
class DatosDemo {
  DatosDemo._();

  /// Lista inicial y mutable de materias cargadas en la aplicación.
  static final List<Materia> materias = [
    // -------------------------------------------------------------
    // MATERIA 1: Arquitectura de Computadores
    // -------------------------------------------------------------
    Materia(
      id: 'mat_1',
      esDemo: true,
      nombre: 'Arquitectura de Computadores',
      subtitulo: 'Laboratorios MIPS • 1 Quiz pendiente',
      descripcion:
          'Estudio de la organización interna del procesador, conjunto de instrucciones MIPS, segmentación (pipeline), y jerarquía de memoria caché.',
      progreso: 0.68,
      icono: Icons.memory_rounded,
      colorInicio: AppColors.degradadoArquitectura[0],
      colorFin: AppColors.degradadoArquitectura[1],
      apuntes: [
        const Apunte(
          id: 'apunte_1_1',
          titulo: 'Segmentación de Instrucciones (Pipeline MIPS)',
          materiaId: 'mat_1',
          fecha: '18 Sep 2026',
          contenido:
              'La segmentación o pipeline en la arquitectura MIPS divide la ejecución de cada instrucción en cinco etapas consecutivas: IF (Instruction Fetch), ID (Instruction Decode), EX (Execute), MEM (Memory Access) y WB (Write Back). Esta técnica permite el solapamiento temporal de instrucciones, aumentando notablemente el throughput del procesador sin reducir la latencia de una instrucción individual. Sin embargo, introduce tres tipos de riesgos: estructurales (conflictos por recursos de hardware), de datos (dependencias entre lecturas y escrituras de registros) y de control (saltos condicionales e incondicionales que alteran el flujo del Program Counter).',
          ideasClave: [
            'El pipeline clásico de MIPS consta de 5 etapas: IF, ID, EX, MEM y WB.',
            'Aumenta el throughput de instrucciones por unidad de tiempo, pero no disminuye la latencia individual.',
            'Los riesgos de datos ocurren por dependencias RAW (Read After Write) y se mitigan con forwarding.',
            'Los riesgos de control surgen por ramas condicionales y se reducen mediante predicción de saltos.',
          ],
          resumenCorto:
              'El pipeline de MIPS optimiza la ejecución dividiendo las instrucciones en 5 fases solapadas, resolviendo riesgos de datos con forwarding y de control con predictores.',
          resumenMedio:
              'La segmentación de 5 etapas (IF, ID, EX, MEM, WB) permite procesar múltiples instrucciones simultáneamente. Aunque eleva el rendimiento general (Throughput), debe manejar riesgos estructurales, de datos y de control mediante técnicas como el adelantamiento (forwarding) y la predicción de ramas.',
          resumenDetallado:
              'En la arquitectura RISC clásica como MIPS, el pipeline de 5 etapas transforma la ejecución secuencial en una línea de ensamblaje. Durante IF se lee la instrucción en memoria; en ID se decodifica y leen registros; en EX opera la ALU; en MEM se accede a la memoria de datos y en WB se guardan los resultados en el banco de registros. Para evitar detenciones (stalls) por dependencias de datos, el hardware implementa cortocircuitos (bypassing/forwarding). Para los riesgos de control, se implementa predicción estática y dinámica de saltos, minimizando penalizaciones por vaciado del cauce.',
        ),
        const Apunte(
          id: 'apunte_1_2',
          titulo: 'Jerarquía de Memoria y Memoria Caché',
          materiaId: 'mat_1',
          fecha: '16 Sep 2026',
          contenido:
              'La jerarquía de memoria busca cerrar la brecha de velocidad entre la CPU y el almacenamiento principal mediante el principio de localidad: localidad temporal (un elemento accedido recientemente tiende a ser accedido de nuevo pronto) y localidad espacial (elementos cercanos en dirección tienden a ser accedidos pronto). Las memorias caché se organizan en mapeo directo, asociativas por conjuntos o totalmente asociativas. Los fallos de caché se clasifican en las 3C: Obligatorios (Compulsory o fríos), de Capacidad y de Conflicto.',
          ideasClave: [
            'Aprovecha los principios fundamentales de localidad temporal y localidad espacial.',
            'La memoria caché reduce los tiempos medios de acceso a memoria (AMAT).',
            'Organizaciones de caché: mapeo directo, asociativa por conjuntos y totalmente asociativa.',
            'Los fallos de caché se clasifican en las 3C: obligatorios (fríos), de capacidad y de conflicto.',
          ],
          resumenCorto:
              'La jerarquía de memoria utiliza cachés rápidas y los principios de localidad para minimizar la latencia de acceso a la RAM.',
          resumenMedio:
              'Fundamentada en localidad espacial y temporal, la jerarquía de memoria sitúa cachés ultrarrápidas entre los registros y la memoria RAM principal. La tasa de aciertos (hit rate) y la reducción de las 3C (fallos obligatorios, de capacidad y de conflicto) determinan el desempeño global del sistema.',
          resumenDetallado:
              'El tiempo medio de acceso a memoria (AMAT = Hit Time + Miss Rate × Miss Penalty) es la métrica clave. Las políticas de reemplazo como LRU (Least Recently Used) y las políticas de escritura (Write-Through vs Write-Back) optimizan el manejo de bloques. Las cachés multinivel (L1, L2, L3) equilibran velocidad extrema y suficiente capacidad.',
        ),
      ],
      preguntas: [
        const Pregunta(
          id: 'p1_1',
          enunciado: '¿Cuáles son las 5 etapas del pipeline clásico de MIPS?',
          opciones: [
            'IF, ID, EX, MEM, WB',
            'READ, WRITE, ALU, CACHE, HALT',
            'FETCH, LOAD, STORE, EXEC, RET',
            'START, PARSE, RUN, SAVE, END',
          ],
          indiceRespuestaCorrecta: 0,
          explicacionIa:
              'Las 5 etapas estándar en MIPS son: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM) y Write Back (WB).',
        ),
        const Pregunta(
          id: 'p1_2',
          enunciado:
              '¿Qué principio explica que si una variable se usa ahora, se volverá a usar pronto?',
          opciones: [
            'Localidad Espacial',
            'Localidad Temporal',
            'Asociatividad de Conjuntos',
            'Forwarding de Registros',
          ],
          indiceRespuestaCorrecta: 1,
          explicacionIa:
              'La localidad temporal indica la tendencia a reutilizar datos o instrucciones que han sido accedidos en un instante reciente (ej. variables en un bucle).',
        ),
        const Pregunta(
          id: 'p1_3',
          enunciado:
              '¿Cómo se denomina la técnica que reenvía datos desde la salida de la ALU a la entrada de la siguiente sin esperar a WB?',
          opciones: [
            'Branch Delay',
            'Pipeline Stall',
            'Forwarding (o Cortocircuito)',
            'Loop Unrolling',
          ],
          indiceRespuestaCorrecta: 2,
          explicacionIa:
              'El reenvío o forwarding toma el resultado generado en EX o MEM y lo pasa directamente a las entradas de la ALU de la siguiente instrucción para mitigar riesgos RAW.',
        ),
        const Pregunta(
          id: 'p1_4',
          enunciado:
              'Un fallo de caché que ocurre la primera vez absoluta que se accede a un bloque se denomina:',
          opciones: [
            'Fallo de Conflicto',
            'Fallo de Capacidad',
            'Fallo de Coherencia',
            'Fallo Obligatorio (Frío)',
          ],
          indiceRespuestaCorrecta: 3,
          explicacionIa:
              'Los fallos obligatorios o de arranque en frío son inevitables la primera vez que se referencia una dirección en memoria, ya que la caché empieza vacía.',
        ),
        const Pregunta(
          id: 'p1_5',
          enunciado:
              'En una política Write-Back, ¿cuándo se actualiza la memoria principal?',
          opciones: [
            'Inmediatamente en cada instrucción de escritura',
            'Solo cuando el bloque modificado en caché va a ser reemplazado',
            'Al inicio de cada ciclo de reloj',
            'Únicamente cuando se apaga el procesador',
          ],
          indiceRespuestaCorrecta: 1,
          explicacionIa:
              'En Write-Back, las escrituras solo modifican el bloque en caché (marcando un bit "dirty"). La memoria principal solo se actualiza cuando ese bloque es desalojado.',
        ),
      ],
      respuestasSimuladasIa: [
        '¡Hola! En Arquitectura de Computadores la clave del pipeline es entender cómo se solapan las instrucciones y cómo el hardware resuelve dependencias con forwarding.',
        'La fórmula del AMAT (Average Memory Access Time) es esencial para tus parciales: AMAT = Tiempo de Acierto + (Tasa de Fallos × Penalización por Fallo).',
        'Si tienes dudas sobre MIPS, recuerda que cada instrucción tiene exactamente 32 bits de longitud y se clasifica en tipos R, I o J.',
      ],
    ),

    // -------------------------------------------------------------
    // MATERIA 2: Bootcamp IA y Datos
    // -------------------------------------------------------------
    Materia(
      id: 'mat_2',
      esDemo: true,
      nombre: 'Bootcamp IA y Datos',
      subtitulo: 'Análisis de Datos • Resumen listo',
      descripcion:
          'Inmersión práctica en ciencia de datos, preprocesamiento con Pandas, algoritmos de Machine Learning supervisado y no supervisado, y redes neuronales.',
      progreso: 0.82,
      icono: Icons.smart_toy_rounded,
      colorInicio: AppColors.degradadoIaDatos[0],
      colorFin: AppColors.degradadoIaDatos[1],
      apuntes: [
        const Apunte(
          id: 'apunte_2_1',
          titulo: 'Modelos de Aprendizaje Supervisado y Clasificación',
          materiaId: 'mat_2',
          fecha: '17 Sep 2026',
          contenido:
              'El aprendizaje supervisado utiliza pares de datos etiquetados (X, y) para entrenar una función predictiva. Para problemas de clasificación se destacan la Regresión Logística, Árboles de Decisión, Random Forest y Máquinas de Vectores de Soporte (SVM). La evaluación del desempeño requiere métricas acordes al balance de clases: Precisión (Precision), Exhaustividad (Recall), F1-Score y el Área bajo la Curva ROC (AUC). El sobreajuste (overfitting) ocurre cuando el modelo memoriza el ruido del entrenamiento y se previene mediante validación cruzada (Cross-Validation) y regularización (L1 Lasso, L2 Ridge).',
          ideasClave: [
            'El aprendizaje supervisado aprende de datos históricos con etiquetas conocidas.',
            'Random Forest combina múltiples árboles de decisión mediante Bagging para reducir la varianza.',
            'Métricas clave de evaluación: Precisión, Recall, F1-Score y matriz de confusión.',
            'El sobreajuste (overfitting) se controla con validación cruzada y técnicas de regularización (L1/L2).',
          ],
          resumenCorto:
              'Los clasificadores supervisados aprenden patrones etiquetados y su rendimiento se evalúa mediante matrices de confusión, F1-score y técnicas de validación cruzada.',
          resumenMedio:
              'El aprendizaje supervisado clasifica instancias a partir de datos etiquetados. Modelos de ensamble como Random Forest mejoran la generalización. Para evitar el sobreajuste es fundamental separar conjuntos de entrenamiento/prueba, aplicar regularización y medir el balance entre Precisión y Recall.',
          resumenDetallado:
              'En problemas con clases desbalanceadas (como detección de fraude), la exactitud global (Accuracy) es engañosa; se debe priorizar el Recall o el F1-Score. Algoritmos como SVM buscan hiperplanos óptimos de separación maximizando el margen, mientras que algoritmos de ensamble como Gradient Boosting optimizan funciones de pérdida reduciendo el sesgo iterativamente.',
        ),
        const Apunte(
          id: 'apunte_2_2',
          titulo: 'Preprocesamiento y Limpieza de Datos Masivos',
          materiaId: 'mat_2',
          fecha: '14 Sep 2026',
          contenido:
              'El preprocesamiento representa hasta el 80% del tiempo de un proyecto de ciencia de datos. Implica la detección e imputación de valores faltantes (Missing Values), la identificación y tratamiento de valores atípicos (Outliers) mediante el rango intercuartílico (IQR) o Z-score, y la codificación de variables categóricas con One-Hot Encoding o Label Encoding. La normalización (MinMax) y estandarización (StandardScaler) aseguran que las magnitudes de diferentes variables no sesguen los algoritmos sensibles a distancias euclidianas como KNN o K-Means.',
          ideasClave: [
            'La limpieza incluye imputación de valores nulos (media, mediana, KNN imputer).',
            'Detección de outliers mediante IQR (rango intercuartílico) o puntuación Z.',
            'Codificación de variables cualitativas mediante One-Hot Encoding o Ordinal Encoding.',
            'Escalado de características (Estandarización y Normalización) crucial para algoritmos basados en distancia.',
          ],
          resumenCorto:
              'El preprocesamiento transforma datos crudos en datasets limpios mediante imputación, codificación categórica y escalado numérico.',
          resumenMedio:
              'La calidad de cualquier modelo de IA depende de la calidad de sus datos. Este proceso involucra limpiar nulos, tratar valores atípicos, codificar variables cualitativas y estandarizar variables continuas para garantizar convergencia estable en el entrenamiento.',
          resumenDetallado:
              'El data leakage (fuga de información) es el riesgo principal durante el preprocesamiento: todos los estimadores (como medias de imputación o escalas de estandarización) deben ajustarse únicamente sobre el conjunto de entrenamiento (train set) y aplicarse posteriormente sobre el conjunto de validación o prueba sin reajustar.',
        ),
      ],
      preguntas: [
        const Pregunta(
          id: 'p2_1',
          enunciado:
              '¿Qué métrica es más aconsejable cuando las clases están sumamente desbalanceadas?',
          opciones: [
            'F1-Score / PR-AUC',
            'Accuracy simple',
            'Mean Squared Error',
            'R-cuadrado',
          ],
          indiceRespuestaCorrecta: 0,
          explicacionIa:
              'Con clases desbalanceadas (ej. 99% negativos, 1% positivos), la exactitud simple (Accuracy) es engañosa. El F1-score equilibra Precisión y Recall efectivamente.',
        ),
        const Pregunta(
          id: 'p2_2',
          enunciado:
              '¿Cuál es la técnica de ensamble que utiliza el algoritmo Random Forest?',
          opciones: [
            'Boosting secuencial',
            'Bagging (Bootstrap Aggregating)',
            'Stacking heterogéneo',
            'Clustering jerárquico',
          ],
          indiceRespuestaCorrecta: 1,
          explicacionIa:
              'Random Forest entrena múltiples árboles en paralelo con muestras aleatorias tomadas con reemplazo (Bagging) y promedia sus predicciones para reducir la varianza.',
        ),
        const Pregunta(
          id: 'p2_3',
          enunciado:
              '¿Qué método de codificación crea una columna binaria (0/1) por cada categoría?',
          opciones: [
            'Label Encoding',
            'One-Hot Encoding',
            'Standard Scaling',
            'Frequency Encoding',
          ],
          indiceRespuestaCorrecta: 1,
          explicacionIa:
              'One-Hot Encoding genera una nueva columna por cada nivel categórico único, asignando 1 si está presente y 0 en caso contrario.',
        ),
        const Pregunta(
          id: 'p2_4',
          enunciado:
              '¿Por qué se debe escalar las variables antes de entrenar algoritmos como KNN o SVM?',
          opciones: [
            'Porque solo aceptan números entre 0 y 1',
            'Porque dependen del cálculo de distancias geométricas en el espacio vectorial',
            'Porque reduce a cero el sobreajuste de forma automática',
            'Porque elimina los valores nulos del DataFrame',
          ],
          indiceRespuestaCorrecta: 1,
          explicacionIa:
              'Algoritmos basados en distancias euclidianas pueden verse dominados por variables con rangos numéricos muy altos respecto a otras con rangos pequeños.',
        ),
        const Pregunta(
          id: 'p2_5',
          enunciado:
              '¿Qué técnica divide los datos en K bloques rotativos para evaluar la robustez del modelo?',
          opciones: [
            'K-Fold Cross-Validation',
            'K-Means Clustering',
            'Linear Discriminant Analysis',
            'Batch Normalization',
          ],
          indiceRespuestaCorrecta: 0,
          explicacionIa:
              'En K-Fold Cross-Validation, el dataset se divide en K partes: en cada iteración una parte sirve de prueba y las restantes K-1 de entrenamiento.',
        ),
      ],
      respuestasSimuladasIa: [
        '¡Hola! En Ciencia de Datos recuerda siempre la regla de oro: "Garbage In, Garbage Out". El preprocesamiento define el éxito de cualquier modelo.',
        'Para recordar la diferencia: la Regularización L1 (Lasso) promueve la dispersión (hace coeficientes cero), mientras que L2 (Ridge) encoge los coeficientes sin eliminarlos del todo.',
        'La matriz de confusión es tu mejor amiga para identificar si tu modelo tiene problemas de falsos positivos o falsos negativos.',
      ],
    ),

    // -------------------------------------------------------------
    // MATERIA 3: Desarrollo Móvil
    // -------------------------------------------------------------
    Materia(
      id: 'mat_3',
      esDemo: true,
      nombre: 'Desarrollo Móvil',
      subtitulo: 'Proyecto Flutter • En progreso',
      descripcion:
          'Diseño de aplicaciones móviles multiplataforma nativas con Flutter y Dart. Patrones de arquitectura, Material 3, ciclo de vida de widgets y gestión reactiva de estado.',
      progreso: 0.54,
      icono: Icons.phone_android_rounded,
      colorInicio: AppColors.degradadoDesarrolloMovil[0],
      colorFin: AppColors.degradadoDesarrolloMovil[1],
      apuntes: [
        const Apunte(
          id: 'apunte_3_1',
          titulo: 'Arquitectura de Widgets y Ciclo de Vida en Flutter',
          materiaId: 'mat_3',
          fecha: '19 Sep 2026',
          contenido:
              'En Flutter "todo es un widget". La arquitectura se apoya en tres árboles interconectados: el Árbol de Widgets (declarativo, inmutable y ligero), el Árbol de Elementos (instancias que gestionan el ciclo de vida y la reconciliación) y el Árbol de Render Objects (encargado del cálculo de tamaño, maquetación y pintado en pantalla). Un StatefulWidget posee un ciclo de vida bien definido: createState(), initState(), didChangeDependencies(), build(), didUpdateWidget() y dispose(). Comprender la correcta liberación de recursos como controllers y timers en dispose() previene fugas de memoria críticas.',
          ideasClave: [
            'Flutter utiliza tres árboles paralelos: Widgets, Elements y RenderObjects.',
            'Los Widgets son inmutables y declarativos; representan la configuración de la interfaz.',
            'Ciclo de vida principal del State: initState, didChangeDependencies, build y dispose.',
            'La cancelación obligatoria de Timers, Streams y Controllers debe realizarse en dispose().',
          ],
          resumenCorto:
              'Los widgets declaran la UI mientras los Elements gestionan el ciclo de vida y los RenderObjects dibujan en pantalla.',
          resumenMedio:
              'Flutter desacopla la configuración de UI (Widgets inmutables) de la lógica de renderizado mediante tres árboles. Los StatefulWidgets permiten reaccionar a cambios de estado mediante setState(), requiriendo inicializar variables en initState() y liberar recursos de hardware en dispose().',
          resumenDetallado:
              'Cuando setState() es invocado, Flutter marca el Element correspondiente como "sucio" (dirty), programándolo para ser reconstruido en el siguiente frame. La reconciliación inteligente compara el widget antiguo con el nuevo mediante su runtimeType y Key, actualizando solo el RenderObject si es estrictamente necesario, lo que confiere a Flutter su alto rendimiento de 60/120 FPS.',
        ),
        const Apunte(
          id: 'apunte_3_2',
          titulo: 'Gestión de Estado Reactivo y Asincronía en Dart',
          materiaId: 'mat_3',
          fecha: '15 Sep 2026',
          contenido:
              'La programación en Dart se ejecuta en un único hilo con un modelo de bucle de eventos (Event Loop) asistido por dos colas: la cola de Microtareas (Microtask Queue) y la cola de Eventos (Event Queue). La asincronía se maneja con Futures (valores únicos diferidos) y Streams (flujos continuos de datos a lo largo del tiempo). Para la gestión de estado, existen soluciones efímeras locales (setState, ValueNotifier) y soluciones de aplicación global como InheritedWidget, Provider, Bloc y Riverpod.',
          ideasClave: [
            'El Event Loop de Dart procesa dos colas de ejecución: Microtask Queue y Event Queue.',
            'Los Futures representan valores asíncronos únicos mediante async y await.',
            'Los Streams transmiten secuencias asíncronas de datos y se escuchan con StreamBuilder.',
            'La gestión de estado se divide en estado efímero (local al widget) y estado de aplicación (global).',
          ],
          resumenCorto:
              'Dart opera con un Event Loop no bloqueante usando Futures y Streams, complementado con gestores de estado efímeros o globales en Flutter.',
          resumenMedio:
              'Gracias al modelo asíncrono no bloqueante de Dart, las llamadas a red o base de datos no congelan la interfaz de usuario. En Flutter, widgets como FutureBuilder y StreamBuilder permiten renderizar vistas reactivas basadas en el estado de conexión de la tarea asíncrona.',
          resumenDetallado:
              'Al diseñar arquitecturas escalables en Flutter, separar la lógica de negocio de la capa de presentación es prioritario. Widgets puros de presentación reaccionan a notificadores como ValueNotifier o StateNotifier, minimizando reconstrucciones innecesarias del árbol de widgets y garantizando fluidez en las animaciones.',
        ),
      ],
      preguntas: [
        const Pregunta(
          id: 'p3_1',
          enunciado:
              '¿Cuál es el método del ciclo de vida donde SIEMPRE se deben cancelar Timers y Controllers?',
          opciones: [
            'initState()',
            'didUpdateWidget()',
            'dispose()',
            'deactivate()',
          ],
          indiceRespuestaCorrecta: 2,
          explicacionIa:
              'El método dispose() se ejecuta cuando el State es removido permanentemente del árbol de widgets. Es obligatorio cancelar Timers y listeners allí para evitar fugas de memoria.',
        ),
        const Pregunta(
          id: 'p3_2',
          enunciado:
              '¿Cuál de los tres árboles de Flutter se encarga directamente del cálculo de tamaño (layout) y pintado?',
          opciones: [
            'El árbol de Widgets',
            'El árbol de Render Objects',
            'El árbol de Elements',
            'El árbol de State Objects',
          ],
          indiceRespuestaCorrecta: 1,
          explicacionIa:
              'El árbol de RenderObjects maneja los protocolos de maquetación geométrica (constraints van hacia abajo, tamaños hacia arriba) y dibuja los píxeles en el canvas.',
        ),
        const Pregunta(
          id: 'p3_3',
          enunciado:
              'En la API moderna de Flutter, ¿qué método reemplaza a withOpacity para evitar pérdida de precisión de color?',
          opciones: [
            '.withValues(alpha: ...)',
            '.setOpacityFactor(...)',
            '.toTransparentColor(...)',
            '.withAlphaChannel(...)',
          ],
          indiceRespuestaCorrecta: 0,
          explicacionIa:
              'En Flutter moderno (3.27+), withOpacity está deprecado y la alternativa oficial recomendada es .withValues(alpha: factor) para mantener precisión cromática.',
        ),
        const Pregunta(
          id: 'p3_4',
          enunciado:
              '¿Qué widget se utiliza para escuchar un Stream y reconstruir la UI ante cada nuevo evento recibido?',
          opciones: [
            'FutureBuilder',
            'StreamBuilder',
            'AnimatedContainer',
            'StatefulConsumer',
          ],
          indiceRespuestaCorrecta: 1,
          explicacionIa:
              'StreamBuilder se suscribe automáticamente a un Stream y expone un AsyncSnapshot en su función constructora con los últimos datos emitidos.',
        ),
        const Pregunta(
          id: 'p3_5',
          enunciado:
              '¿Cuál es la función del widget Hero en transiciones entre pantallas?',
          opciones: [
            'Animar un widget compartido entre rutas volando de una pantalla a otra',
            'Guardar el estado de la sesión en almacenamiento local',
            'Aplicar desenfoque gaussiano sobre una imagen',
            'Controlar el brillo del modo oscuro en el dispositivo',
          ],
          indiceRespuestaCorrecta: 0,
          explicacionIa:
              'El widget Hero asocia un mismo tag en dos pantallas distintas y anima suavemente su posición y tamaño durante la navegación entre rutas.',
        ),
      ],
      respuestasSimuladasIa: [
        '¡Hola, Edwin! En Flutter recuerda siempre que los Widgets son inmutables: si necesitas cambiar algo, actualiza el estado y deja que Flutter reconstruya.',
        'Un gran consejo para animaciones suaves: utiliza siempre const en los constructores de widgets estáticos para evitar reconstrucciones innecesarias.',
        '¿Sabías que el widget IndexedStack mantiene vivas las pantallas del NavigationBar en memoria sin reiniciar su estado al cambiar de pestaña?',
      ],
    ),
  ];

  // -------------------------------------------------------------
  // DATOS PARA LA PANTALLA DE PLAN DE ESTUDIO
  // -------------------------------------------------------------
  /// Información del examen o parcial más próximo del estudiante.
  static const Map<String, dynamic> proximoParcial = {
    'materia': 'Arquitectura de Computadores',
    'evaluacion': 'Primer Examen Parcial Teórico-Práctico',
    'fecha': 'Jueves, 24 de Septiembre',
    'diasRestantes': 3,
    'temas': 'Pipeline MIPS de 5 etapas, Riesgos y Jerarquía Caché',
    'icono': Icons.alarm_rounded,
  };

  /// Lista interactiva de sesiones de estudio programadas para el día de hoy.
  static final List<SesionEstudio> sesionesDelDia = [
    SesionEstudio(
      id: 'ses_1',
      materia: 'Arquitectura de Computadores',
      tema: 'Repaso de riesgos en pipeline y ejercicios de forwarding',
      hora: '09:00 AM - 10:00 AM',
      duracionMinutos: 60,
      completada: true,
    ),
    SesionEstudio(
      id: 'ses_2',
      materia: 'Bootcamp IA y Datos',
      tema: 'Limpieza con Pandas e imputación de nulos',
      hora: '11:30 AM - 12:45 PM',
      duracionMinutos: 75,
      completada: true,
    ),
    SesionEstudio(
      id: 'ses_3',
      materia: 'Desarrollo Móvil',
      tema: 'Implementación de NavigationBar y SegmentedButton',
      hora: '04:00 PM - 05:30 PM',
      duracionMinutos: 90,
      completada: false,
    ),
    SesionEstudio(
      id: 'ses_4',
      materia: 'Arquitectura de Computadores',
      tema: 'Quiz de autoevaluación: Jerarquía de memoria y cachés',
      hora: '07:00 PM - 08:00 PM',
      duracionMinutos: 60,
      completada: false,
    ),
  ];

  // -------------------------------------------------------------
  // DATOS PARA LA PANTALLA DE ESTADÍSTICAS
  // -------------------------------------------------------------
  /// Métricas globales del perfil del estudiante.
  static const Map<String, String> metricasEstadisticas = {
    'horasEstudio': '14.5 h',
    'rachaDias': '7 días',
    'quizzesCompletados': '12',
  };

  /// Datos semanales de horas de estudio para la gráfica de barras artesanal (Lun a Dom).
  static const List<Map<String, dynamic>> horasSemanales = [
    {'dia': 'Lun', 'horas': 2.5},
    {'dia': 'Mar', 'horas': 3.0},
    {'dia': 'Mié', 'horas': 1.5},
    {'dia': 'Jue', 'horas': 4.0}, // Día pico
    {'dia': 'Vie', 'horas': 2.0},
    {'dia': 'Sáb', 'horas': 1.0},
    {'dia': 'Dom', 'horas': 0.5},
  ];

  /// Sugerencias rápidas de preguntas para el chat con el Tutor IA.
  static const List<String> sugerenciasChat = [
    '¿Me explicas el concepto principal?',
    'Dame un ejemplo práctico y cotidiano',
    '¿Cómo suelen evaluar esto en un parcial?',
    'Hazme una pregunta rápida de prueba',
  ];
}
