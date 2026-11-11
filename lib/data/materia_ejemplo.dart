/// Materia de ejemplo que el usuario puede cargar desde Inicio para probar la
/// app (resumen, quiz, tutor y plan) sin tener que escribir sus propios apuntes.
class MateriaEjemplo {
  MateriaEjemplo._();

  static const String nombre = 'Arquitectura de Computadores';

  static const String descripcion =
      'Organización interna del procesador, instrucciones MIPS, segmentación '
      '(pipeline) y jerarquía de memoria caché.';

  /// Índice del degradado y clave del icono en el catálogo de materias.
  static const int colorIndice = 0;
  static const String iconoClave = 'memoria';

  /// Apuntes de la materia, en el orden en que se muestran.
  static const List<({String titulo, String contenido})> apuntes = [
    (
      titulo: 'Segmentación de instrucciones (pipeline MIPS)',
      contenido:
          'La segmentación o pipeline en la arquitectura MIPS divide la '
          'ejecución de cada instrucción en cinco etapas consecutivas: IF '
          '(Instruction Fetch), ID (Instruction Decode), EX (Execute), MEM '
          '(Memory Access) y WB (Write Back). Esta técnica permite el '
          'solapamiento temporal de instrucciones, aumentando notablemente el '
          'throughput del procesador sin reducir la latencia de una '
          'instrucción individual.\n\n'
          'Sin embargo, introduce tres tipos de riesgos: estructurales '
          '(conflictos por recursos de hardware), de datos (dependencias entre '
          'lecturas y escrituras de registros) y de control (saltos '
          'condicionales e incondicionales que alteran el flujo del Program '
          'Counter).\n\n'
          'Los riesgos de datos se mitigan con adelantamiento (forwarding) y, '
          'cuando no alcanza, con burbujas (stalls). Los riesgos de control '
          'se reducen con predicción de saltos; si la predicción falla, se '
          'vacían las instrucciones que entraron al cauce por error.',
    ),
    (
      titulo: 'Jerarquía de memoria y memoria caché',
      contenido:
          'La jerarquía de memoria busca cerrar la brecha de velocidad entre '
          'la CPU y el almacenamiento principal mediante el principio de '
          'localidad: localidad temporal (un elemento accedido recientemente '
          'tiende a ser accedido de nuevo pronto) y localidad espacial '
          '(elementos cercanos en dirección tienden a ser accedidos pronto).\n\n'
          'Las memorias caché se organizan en mapeo directo, asociativas por '
          'conjuntos o totalmente asociativas. Los fallos de caché se '
          'clasifican en las 3C: obligatorios (compulsory o fríos), de '
          'capacidad y de conflicto.\n\n'
          'La métrica clave es el tiempo medio de acceso a memoria: AMAT = '
          'tiempo de acierto + tasa de fallos × penalización por fallo. Las '
          'políticas de reemplazo como LRU (Least Recently Used) y las de '
          'escritura (write-through y write-back) definen cómo se manejan los '
          'bloques. Las cachés multinivel (L1, L2, L3) equilibran velocidad y '
          'capacidad.',
    ),
  ];
}
