# Fase 2 · Parte 2: Pomodoro, quiz y estadísticas reales: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que las sesiones de Pomodoro y los intentos de quiz se guarden en el dispositivo y alimenten Stats e Inicio (racha) con datos reales.

**Architecture:** La base SQLite sube a la versión 2 (migración que conserva lo existente) con dos tablas nuevas. `MateriasRepository` gana cuatro métodos; un `EstadisticasProvider` aparte (recargado cuando cambian las materias) guarda y expone sesiones e intentos; los cálculos (racha, horas por día, totales) son funciones puras en `utils/`.

**Tech Stack:** Flutter, `provider`, `sqflite` (ya instalados). Sin dependencias nuevas.

**Spec:** `docs/superpowers/specs/2026-10-27-fase2-parte2-estadisticas-design.md`. Léelo antes de empezar.

## Global Constraints

- Español en textos de interfaz, nombres y comentarios `///`, como el resto del código.
- Plataforma de prueba: Android. Sin IA, sin red, sin claves (repo público).
- Plan y Stats-demo: la pestaña **Plan** no se toca. `lib/data/datos_demo.dart` no se modifica.
- La base pasa a **versión 2** con `onUpgrade` que **no borra** materias ni apuntes. Sin llaves foráneas en las tablas nuevas.
- Línea base: `flutter test` → 71 pruebas pasan; `flutter analyze` → sin problemas. Debe terminar igual de limpio.
- Cada commit termina con `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. No hacer `git push` en este plan.
- Los widgets que usen los proveedores se prueban con `RepositorioMemoria` (test/support); el SQL real con `sqflite_common_ffi`.

## Review Focus

1. Actualizar desde la versión 1 conserva materias y apuntes y habilita las tablas nuevas (Tarea 2).
2. Borrar una materia borra sus sesiones e intentos, y Stats se recalcula (Tareas 2 y 3).
3. Un bloque de enfoque que "termina" mientras la pantalla estaba bloqueada (un solo tick tardío) sigue guardándose una sola vez (Tarea 4).
4. Saltar, reiniciar o completar un *descanso* no guarda sesión; completar un enfoque guarda exactamente una (Tarea 4).
5. Racha: un día sin estudiar rompe la racha; dos sesiones el mismo día cuentan un día; ayer sin hoy sigue viva (Tarea 1).

## Mapa de archivos

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `lib/models/sesion_enfoque.dart`, `lib/models/intento_quiz.dart` | Crear | Modelos |
| `lib/utils/calculos_estadisticas.dart` | Crear | Racha, horas por día, totales, formato |
| `lib/data/materias_repository.dart`, `materias_repository_sqflite.dart` | Modificar | 4 métodos nuevos, esquema v2, migración |
| `lib/providers/estadisticas_provider.dart` | Crear | Estado de sesiones e intentos |
| `lib/main.dart` | Modificar | `MultiProvider` + sincronización con materias |
| `lib/screens/pomodoro_screen.dart` | Modificar | Reloj por hora de fin y guardado de sesión |
| `lib/screens/quiz_screen.dart` | Modificar | Guardar el intento al terminar |
| `lib/screens/estadisticas_screen.dart` | Reescribir | Datos reales |
| `lib/screens/inicio_screen.dart` | Modificar | Tarjeta de racha real |
| `test/support/repositorio_memoria.dart`, `test/support/reloj_falso.dart` | Modificar/Crear | Soporte de pruebas |
| `README.md` | Modificar | Estado del proyecto |

---

### Task 1: Modelos y cálculos de estadísticas

**Files:**
- Create: `lib/models/sesion_enfoque.dart`, `lib/models/intento_quiz.dart`, `lib/utils/calculos_estadisticas.dart`
- Test: `test/utils/calculos_estadisticas_test.dart`

**Interfaces:**
- Produces:
  - `class SesionEnfoque { final String id; final String? materiaId; final DateTime inicio; final int duracionSegundos; const SesionEnfoque({required id, this.materiaId, required inicio, required duracionSegundos}); }`
  - `class IntentoQuiz { final String id; final String materiaId; final int aciertos; final int total; final DateTime fecha; const IntentoQuiz({...todos required}); }`
  - `int calcularRacha(List<SesionEnfoque> sesiones, DateTime hoy)`: días consecutivos (fecha local) con sesión, terminando hoy o, si hoy no hay, ayer; 0 si no hay.
  - `List<double> horasPorDiaDeLaSemana(List<SesionEnfoque> sesiones, DateTime hoy)`: 7 valores (lunes a domingo) de la semana que contiene `hoy`, en horas.
  - `const List<String> nombresDiasCortos = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom']`
  - `int? indicePicoSemanal(List<double> horas)`: índice del mayor valor (el primero si hay empate); `null` si todo es 0.
  - `int segundosTotales(List<SesionEnfoque> sesiones, {String? materiaId})`
  - `String formatearDuracion(int segundos)` → `'0 min'`, `'45 min'`, `'1 h'`, `'2 h 30 min'` (minutos redondeados hacia abajo).
  - `String formatearHoras(double horas)` → `'0'`, `'2'`, `'2.5'` (un decimal, sin `.0`).
  - `IntentoQuiz? mejorIntento(List<IntentoQuiz> intentos, String materiaId)`: mayor `aciertos/total`; empate → el más reciente; `null` si no hay.

- [ ] **Step 1: Pruebas que fallan** (`calculos_estadisticas_test.dart`), con `hoy = DateTime(2026, 10, 28, 12)` (miércoles):
  - Racha: `[]`→0; sesión hoy→1; hoy+ayer→2; solo ayer→1; solo anteayer→0; hoy+ayer+anteayer→3; dos sesiones hoy→1; hoy y anteayer (falta ayer)→1.
  - Horas por día: sesión de 3600 s el lunes 26 y 5400 s el miércoles 28 → `[1.0, 0, 1.5, 0, 0, 0, 0]`; una sesión del domingo 25 (semana anterior) no cuenta; con `hoy` domingo 1 nov, una sesión del lunes 26 oct SÍ cuenta (misma semana lun-dom).
  - `indicePicoSemanal([0,0,0,0,0,0,0])` → null; `[1,0,1.5,0,0,0,0]` → 2; empate `[2,0,2,...]` → 0.
  - `segundosTotales` suma todo; con `materiaId: 'mat_a'` solo las de esa materia.
  - `formatearDuracion(0)`→`'0 min'`, `(59)`→`'0 min'`, `(2700)`→`'45 min'`, `(3600)`→`'1 h'`, `(9000)`→`'2 h 30 min'`. `formatearHoras(0)`→`'0'`, `(2)`→`'2'`, `(2.5)`→`'2.5'`, `(1.25)`→`'1.3'` (o `'1.2'` según redondeo de Dart; fijar el valor que dé `toStringAsFixed(1)`).
  - `mejorIntento`: `[3/5, 5/5, 4/5]` → el 5/5; empate 4/5 viejo vs 4/5 nuevo → el nuevo; otra materia no se mezcla; sin intentos → null.
- [ ] **Step 2:** `flutter test test/utils/calculos_estadisticas_test.dart` → FALLA.
- [ ] **Step 3:** Implementar modelos y funciones según Interfaces. Para comparar días usar `DateTime(y, m, d)` (sin hora).
- [ ] **Step 4:** misma orden → PASA; `flutter analyze` limpio.
- [ ] **Step 5: Commit** `feat: modelos y cálculos de estadísticas`

---

### Task 2: Repositorio, esquema v2 y migración

**Files:**
- Modify: `lib/data/materias_repository.dart`, `lib/data/materias_repository_sqflite.dart`, `test/support/repositorio_memoria.dart`
- Test: `test/data/materias_repository_sqflite_test.dart` (agregar casos)

**Interfaces:**
- Consumes: modelos de la Tarea 1.
- Produces (en `MateriasRepository`, implementados por SQLite y `RepositorioMemoria`):
  ```dart
  Future<SesionEnfoque> registrarSesionEnfoque({String? materiaId, required DateTime inicio, required int duracionSegundos});
  Future<List<SesionEnfoque>> obtenerSesionesEnfoque();   // más nueva primero
  Future<IntentoQuiz> registrarIntentoQuiz({required String materiaId, required int aciertos, required int total});
  Future<List<IntentoQuiz>> obtenerIntentosQuiz();        // más nuevo primero
  ```
  - Esquema v2: tablas `sesiones_enfoque` e `intentos_quiz` de la especificación; `openDatabase(version: 2, onCreate: crea todo, onUpgrade: si viejo < 2 crea las dos tablas)`.
  - `borrarMateria(id)` borra en una transacción la materia (con sus apuntes por cascada) y las filas de `sesiones_enfoque` e `intentos_quiz` con ese `materia_id`. `RepositorioMemoria` hace lo mismo.

- [ ] **Step 1: Pruebas que fallan** (SQLite, `inMemoryDatabasePath` salvo la de migración):
  - `registra y devuelve sesiones del más nuevo al más viejo` (con `materiaId` nulo en una).
  - `registra y devuelve intentos de quiz` (aciertos, total, fecha, orden).
  - `borrar una materia borra sus sesiones e intentos pero no los de otras` (Review Focus 2): comprobar con `baseDatos.rawQuery('SELECT COUNT(*) ...')`.
  - `actualizar desde la versión 1 conserva materias y apuntes y habilita las tablas nuevas` (Review Focus 1): en un archivo temporal, abrir con `databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(version: 1, onCreate: ...))` creando las tablas **v1** (SQL de la Parte 1) e insertando 1 materia y 1 apunte; cerrar; `MateriasRepositorySqflite.abrir(ruta: ruta)`; esperar que la materia y el apunte sigan y que `registrarSesionEnfoque` funcione.
  - `los datos nuevos sobreviven a cerrar y reabrir`.
- [ ] **Step 2:** `flutter test test/data` → FALLA.
- [ ] **Step 3:** Implementar (`RepositorioMemoria` incluido; ids `ses_<n>` / `qz_<n>` / microsegundos en SQLite con el mismo mecanismo `_nuevoId`).
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: sesiones de enfoque e intentos de quiz en SQLite v2`

---

### Task 3: `EstadisticasProvider` y conexión en la app

**Files:**
- Create: `lib/providers/estadisticas_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/providers/estadisticas_provider_test.dart`, `test/estadisticas_integracion_test.dart`

**Interfaces:**
- Consumes: repositorio (Tarea 2), `MateriasProvider`.
- Produces:
  ```dart
  class EstadisticasProvider extends ChangeNotifier {
    EstadisticasProvider(MateriasRepository repositorio);
    List<SesionEnfoque> get sesiones;  List<IntentoQuiz> get intentos;
    bool get cargando;  String? get error;       // error: 'No se pudieron cargar tus estadísticas.'
    Future<void> cargar();                        // nunca lanza
    Future<bool> registrarSesionEnfoque({String? materiaId, required DateTime inicio, required int duracionSegundos}); // true si guardó; nunca lanza
    Future<bool> registrarIntentoQuiz({required String materiaId, required int aciertos, required int total});         // idem
    void sincronizarConMaterias(List<Materia> materias); // recarga si cambió el conjunto de ids (no en la primera llamada)
  }
  ```
  - `StudyBuddyApp` pasa a `MultiProvider`: `ChangeNotifierProvider<MateriasProvider>` y `ChangeNotifierProxyProvider<MateriasProvider, EstadisticasProvider>` (create: `EstadisticasProvider(repositorio)..cargar()`, update: `sincronizarConMaterias(materias.materias)`).

- [ ] **Step 1: Pruebas que fallan:**
  - Provider (con `RepositorioInestable` extendido para fallar escrituras si hace falta, o `RepositorioMemoria`): `cargar` deja listas vacías y `cargando == false`; `registrarSesionEnfoque` devuelve `true` y aparece en `sesiones`; con lectura fallando `cargar` no lanza y expone `error`; `registrarIntentoQuiz` guarda; si el repositorio lanza al escribir, devuelve `false` sin lanzar.
  - `sincronizarConMaterias`: primera llamada no recarga; con un id distinto sí recarga.
  - Integración (app completa con `RepositorioMemoria`, helper `abrirApp`): sembrar materia y sesión de esa materia; ir a Stats (sin asserts de contenido aún); borrar la materia desde Inicio (mantener pulsada → Borrar → confirmar) y verificar que `repositorio.obtenerSesionesEnfoque()` queda vacío (Review Focus 2).
- [ ] **Step 2:** `flutter test test/providers test/estadisticas_integracion_test.dart` → FALLA.
- [ ] **Step 3:** Implementar provider y `MultiProvider` en `main.dart`.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: EstadisticasProvider conectado a la app`

---

### Task 4: Pomodoro por hora de fin y guardado de sesiones

**Files:**
- Modify: `lib/screens/pomodoro_screen.dart`
- Create: `test/support/reloj_falso.dart`
- Test: `test/pomodoro_test.dart`

**Interfaces:**
- Consumes: `EstadisticasProvider.registrarSesionEnfoque`.
- Produces:
  - `class RelojFalso { DateTime actual; RelojFalso(this.actual); DateTime call() => actual; void avanzar(Duration d); }` (en `test/support`).
  - `PomodoroScreen({super.key, this.materia, DateTime Function() ahora = DateTime.now})`.
  - Keys en los controles: `Key('pomodoro-iniciar-pausar')`, `Key('pomodoro-reiniciar')`, `Key('pomodoro-saltar')`.
  - Comportamiento: al iniciar/reanudar se fija `_finEsperado = ahora() + restante`; cada tick (1 s) y al volver la app a primer plano (`WidgetsBindingObserver.didChangeAppLifecycleState` → `resumed`) se recalcula `_segundosRestantes = max(0, ceil((finEsperado − ahora())/1 s))`; al llegar a 0 se completa **una sola vez**. Al pausar se conserva el restante. Un bloque de **Enfoque** completado llama `context.read<EstadisticasProvider>().registrarSesionEnfoque(materiaId: widget.materia?.id, inicio: <hora en que empezó el bloque>, duracionSegundos: modo.segundosTotales)` sin esperar el resultado. Saltar, reiniciar, cambiar de modo y completar un descanso **no** guardan. Se conserva el resto del comportamiento actual (transición a descanso, ciclos, textos).

- [ ] **Step 1: Pruebas que fallan** (pantalla montada en `MaterialApp` + `MultiProvider` con `RepositorioMemoria`, reloj falso):
  - `al terminar un bloque de enfoque se guarda una sesión de 1500 s con su materia y hora de inicio`; luego la pantalla muestra `'05:00'` (Descanso Corto).
  - `un tick tardío tras bloquear la pantalla completa el bloque y lo guarda una sola vez` (Review Focus 3): iniciar, `reloj.avanzar(26 min)`, un solo `pump(1 s)` → exactamente 1 sesión.
  - `el tiempo restante sigue la hora real, no los ticks`: avanzar 10 min + un `pump(1 s)` → `'15:00'`.
  - `pausar conserva el tiempo y reanudar continúa` (pausa, avanzar 3 min, reanudar, avanzar 1 min → el restante baja solo 1 min respecto a la pausa).
  - `saltar, reiniciar y terminar un descanso no guardan sesiones` (Review Focus 4).
  - `una sesión sin materia se guarda con materiaId nulo`.
- [ ] **Step 2:** `flutter test test/pomodoro_test.dart` → FALLA.
- [ ] **Step 3:** Implementar los cambios de Interfaces (registrar/quitar el observer en `initState`/`dispose`; cancelar el `Timer` en `dispose`).
- [ ] **Step 4:** `flutter test` completo (incluye la prueba de Pomodoro de `widget_test.dart`) y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: Pomodoro por hora de fin y guardado de sesiones de enfoque`

---

### Task 5: Guardar intentos de quiz

**Files:**
- Modify: `lib/screens/quiz_screen.dart`
- Test: `test/quiz_test.dart`

**Interfaces:**
- Consumes: `EstadisticasProvider.registrarIntentoQuiz`.
- Comportamiento: al terminar la **última** pregunta, antes de ir a `ResultadosQuizScreen`, se guarda `registrarIntentoQuiz(materiaId: widget.materia.id, aciertos: _respuestasCorrectas, total: _preguntas.length)` una sola vez (bandera para evitar doble guardado por doble toque).

- [ ] **Step 1: Pruebas que fallan:** montar `QuizScreen(materia: DatosDemo.materias.first)` bajo `MultiProvider`; recorrer las 5 preguntas eligiendo la opción correcta en las 3 primeras y una incorrecta en las 2 últimas (leer los textos de `Pregunta.opciones` y los botones de comprobar/siguiente en `quiz_screen.dart`); al final, `repositorio.obtenerIntentosQuiz()` tiene **1** intento con `aciertos == 3`, `total == 5`, `materiaId == 'mat_1'`; y un segundo toque rápido en el botón final no crea un segundo intento.
- [ ] **Step 2:** `flutter test test/quiz_test.dart` → FALLA.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: guardar el resultado de cada quiz`

---

### Task 6: Stats con datos reales

**Files:**
- Rewrite: `lib/screens/estadisticas_screen.dart` (conservar el estilo visual de tarjetas y barras)
- Modify: `test/widget_test.dart` (textos que cambien)
- Test: `test/estadisticas_test.dart`

**Interfaces:**
- Consumes: `EstadisticasProvider`, `MateriasProvider`, funciones de la Tarea 1.
- Contenido: título `Estadísticas y Rendimiento`; tarjetas `Tiempo` (`formatearDuracion(segundosTotales)`), `Racha` (`'N día'/'N días'`, `0 días` si no hay) y `Quizzes` (cantidad de intentos); gráfica con título `Horas de Estudio Semanal`, subtítulo `Total de X horas esta semana` (`formatearHoras`), badge `Pico: Jue (2.5 h)` solo si `indicePicoSemanal != null`, barras lun–dom (`nombresDiasCortos`); sección `Estudio por Materia` con una tarjeta por materia **real** (nombre, icono/color, `formatearDuracion` de sus sesiones y, si existe, `Mejor quiz: 4/5`); si no hay materias reales, el texto `Crea una materia para ver tu estudio por materia.`; si no hay sesiones ni intentos, un aviso `Completa un bloque de enfoque del Pomodoro para ver tus estadísticas.`. Mientras `cargando`, un indicador de progreso; si `error != null`, el mensaje y un botón `Reintentar` (`Key('reintentar-estadisticas')`). Ya no se usa `DatosDemo`.

- [ ] **Step 1: Pruebas que fallan** (app completa con `RepositorioMemoria`, sembrando datos con el repositorio, abrir la pestaña Stats):
  - `sin datos: tarjetas en cero y aviso`: `'0 min'`, `'0 días'`, texto del aviso, `'Total de 0 horas esta semana'`, no hay `'Pico:'`.
  - `con sesiones de lunes y miércoles de esta semana muestra total, pico y tiempo`: sesiones de 3600 s (lunes) y 5400 s (miércoles) de la semana actual → `'2 h 30 min'`, `'Total de 2.5 horas esta semana'`, `'Pico: Mié (1.5 h)'`.
  - `estudio por materia muestra tiempo y mejor quiz solo de materias reales`: materia 'Redes' con una sesión de 5400 s y un intento 4/5 → `'1 h 30 min'` y `'Mejor quiz: 4/5'`; una sesión de materia `'mat_1'` (demo) cuenta en `Tiempo` pero no genera tarjeta.
  - `sin materias reales muestra la invitación a crear una`.
  - `racha y quizzes`: sesiones hoy y ayer → `'2 días'`; 3 intentos → `'3'` en Quizzes.
  - `si falla la carga muestra el error y permite reintentar` (con `RepositorioInestable`).
  - Actualizar en `widget_test.dart` los textos de Stats que cambien (`Progreso por Materia` → `Estudio por Materia`).
- [ ] **Step 2:** `flutter test test/estadisticas_test.dart test/widget_test.dart` → FALLA.
- [ ] **Step 3:** Reescribir la pantalla.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN. Respetar la barra de navegación (el cuerpo ya está dentro del `Scaffold`; añadir `SafeArea(top: false)`).
- [ ] **Step 5: Commit** `feat: Stats con datos reales`

---

### Task 7: Racha real en Inicio

**Files:**
- Modify: `lib/screens/inicio_screen.dart`
- Test: `test/racha_inicio_test.dart`

**Interfaces:**
- Consumes: `EstadisticasProvider`, `calcularRacha`.
- Comportamiento: sobre el buscador (cuando hay materias, o también en el estado vacío si hay racha) se muestra la tarjeta con degradado `AppColors.degradadoRacha`, icono de fuego y el texto `¡Racha de N días activa! 🔥` (`¡Racha de 1 día activa! 🔥` en singular) **solo si `calcularRacha(...) >= 1`**; con 0, no se muestra. Subtítulo fijo: `Tu constancia te acerca a dominar todos tus parciales.`

- [ ] **Step 1: Pruebas que fallan:** sin sesiones no aparece `'¡Racha de'`; con una sesión de hoy aparece `'¡Racha de 1 día activa! 🔥'`; con sesiones de hoy y ayer `'¡Racha de 2 días activa! 🔥'`; con una sesión de hace 3 días no aparece.
- [ ] **Step 2:** `flutter test test/racha_inicio_test.dart` → FALLA.
- [ ] **Step 3:** Implementar (reutilizar el diseño de la tarjeta de racha de la Fase 1, ver `git show a9feb3d:lib/screens/inicio_screen.dart`).
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: racha real en Inicio`

---

### Task 8: Verificación y README

**Files:** Modify: `README.md`

- [ ] **Step 1:** `flutter analyze` limpio y `flutter test` todo verde (anotar el total).
- [ ] **Step 2:** `flutter build apk --debug` compila.
- [ ] **Step 3:** Actualizar `README.md`: estado (Parte 2 completa: sesiones de enfoque, quiz y Stats reales; Plan sigue demo; IA en la Fase 3), tabla de pantallas (Stats real, Pomodoro guarda sesiones), estructura (`utils/` con cálculos) y el esquema de la base.
- [ ] **Step 4: Commit** `docs: README de la Fase 2 parte 2`. **No hacer push.**
