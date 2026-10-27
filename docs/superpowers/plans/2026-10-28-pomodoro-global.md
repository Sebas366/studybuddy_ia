# Pomodoro global con aviso al terminar: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que el Pomodoro siga corriendo al salir de su pantalla, avise con una notificación de vibración repetida al terminar y sobreviva a que Android cierre la app; con un modo de duraciones cortas para la demostración.

**Architecture:** Un `PomodoroProvider` global posee el temporizador, calcula contra la hora de fin, guarda su estado en SQLite (v4) y programa/cancela una alarma mediante la interfaz `NotificadorPomodoro` (implementación real con `flutter_local_notifications`; falsa en pruebas). La pantalla del Pomodoro, una pastilla en Inicio y un interruptor en Perfil son solo vistas del provider.

**Tech Stack:** Flutter, `provider`, `sqflite`, `flutter_local_notifications` 22.3.3, `timezone` (ya agregados con `flutter pub add`).

**Spec:** `docs/superpowers/specs/2026-10-28-pomodoro-global-design.md`. Léelo antes de empezar.

## Global Constraints

- Español en textos, nombres y comentarios `///`. Android. Sin claves ni red.
- SQLite a **versión 4** encadenando `onUpgrade` (`<2`, `<3`, `<4`) sin perder nada.
- Duraciones: normal 25 min / 5 min / 15 min; demostración **15 s / 5 s / 10 s**. Modo demostración activado por defecto.
- Línea base: `flutter test` → 162 pruebas pasan; `flutter analyze` limpio. Debe terminar igual.
- Cada commit termina con `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. No hacer `git push`.
- No usar `dart format` sobre carpetas enteras: solo sobre los archivos que se tocan.
- Las pruebas de lógica con temporizador usan `testWidgets` + `tester.pump(Duration)` (reloj simulado) y `RelojFalso`.

## Review Focus

1. Salir de la pantalla y volver no reinicia el tiempo; un bloque que vence mientras la app estaba cerrada se completa **una sola vez** y registra su sesión (Tarea 4).
2. Pausar, reiniciar, saltar y cambiar de modo cancelan la alarma programada; iniciar la programa para la hora de fin exacta (Tarea 4).
3. El interruptor del modo demostración no altera un bloque ya iniciado, y se conserva al reiniciar la app (Tareas 2 y 4).
4. Abrir el Pomodoro de otra materia con un bloque activo no lo reemplaza ni lo reinicia (Tarea 5).
5. La migración v3→v4 conserva materias, apuntes, sesiones e intentos (Tarea 2).

## Mapa de archivos

| Archivo | Acción |
|---|---|
| `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` | Modificar: desugaring, permisos, receptores |
| `lib/models/modo_pomodoro.dart`, `lib/models/estado_pomodoro.dart` | Crear |
| `lib/utils/calculos_estadisticas.dart` | Modificar: `formatearDuracion` en segundos |
| `lib/data/materias_repository.dart`, `materias_repository_sqflite.dart` | Modificar: v4, estado en curso y ajustes |
| `lib/services/notificador_pomodoro.dart`, `lib/services/notificador_local.dart` | Crear |
| `lib/providers/pomodoro_provider.dart` | Crear |
| `lib/main.dart` | Modificar: inicializar notificador, `PomodoroProvider`, reanudar |
| `lib/screens/pomodoro_screen.dart` | Reescribir como vista del provider |
| `lib/screens/inicio_screen.dart`, `lib/screens/perfil_screen.dart` | Modificar: pastilla, interruptor |
| `test/support/*`, `test/pomodoro_test.dart` y pruebas afectadas | Actualizar/Crear |

---

### Task 1: Modos, estado y formato de duraciones

**Files:** Create `lib/models/modo_pomodoro.dart`, `lib/models/estado_pomodoro.dart`; Modify `lib/utils/calculos_estadisticas.dart`; Test `test/models/pomodoro_modelos_test.dart`, `test/utils/calculos_estadisticas_test.dart`

**Interfaces:**
- Produces:
  - `enum ModoPomodoro { enfoque, descansoCorto, descansoLargo }` con `String get etiqueta` (`'Enfoque'`, `'Descanso Corto'`, `'Descanso Largo'`), `IconData get icono` (`Icons.center_focus_strong_rounded`, `Icons.coffee_rounded`, `Icons.weekend_rounded`) y `int segundos({required bool demo})` → normal 1500/300/900; demo 15/5/10.
  - `class EstadoPomodoro { final ModoPomodoro modo; final bool corriendo; final DateTime? fin; final int segundosRestantes; final int segundosTotales; final int ciclos; final String? materiaId; final String? materiaNombre; const EstadoPomodoro({...todos required salvo fin, materiaId, materiaNombre}); }`.
  - `formatearDuracion(int segundos)`: `0` → `'0 min'`; `1..59` → `'N s'`; resto igual que hoy (minutos redondeados hacia abajo).

- [ ] **Step 1: Pruebas que fallan:** `ModoPomodoro.enfoque.segundos(demo: false)==1500`, `(demo: true)==15`; descansoCorto 300/5; descansoLargo 900/10; etiquetas; `formatearDuracion(0)=='0 min'`, `(15)=='15 s'`, `(59)=='59 s'`, `(60)=='1 min'`, `(2700)=='45 min'`, `(9000)=='2 h 30 min'` (actualizar la prueba existente que esperaba `'0 min'` para 59 s).
- [ ] **Step 2:** `flutter test test/models/pomodoro_modelos_test.dart test/utils/calculos_estadisticas_test.dart` → FALLA.
- [ ] **Step 3:** Implementar. `ModoPomodoro` sale de `pomodoro_screen.dart` (la pantalla se reescribe en la Tarea 5; mientras tanto déjala importando el nuevo enum o mantén su copia local hasta entonces sin romper la compilación).
- [ ] **Step 4:** `flutter test` y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: modos del Pomodoro, estado y duraciones cortas`

---

### Task 2: Repositorio v4 (estado en curso y ajustes)

**Files:** Modify `lib/data/materias_repository.dart`, `lib/data/materias_repository_sqflite.dart`, `test/support/repositorio_memoria.dart`; Test `test/data/materias_repository_sqflite_test.dart`

**Interfaces:**
- Consumes: `EstadoPomodoro`, `ModoPomodoro`.
- Produces (en `MateriasRepository`, SQLite y `RepositorioMemoria`):
  ```dart
  Future<EstadoPomodoro?> obtenerPomodoroEnCurso();
  Future<void> guardarPomodoroEnCurso(EstadoPomodoro estado);   // reemplaza el único registro
  Future<void> borrarPomodoroEnCurso();
  Future<String?> obtenerAjuste(String clave);
  Future<void> guardarAjuste(String clave, String valor);        // reemplaza si existe
  ```
  - Esquema v4 según el spec; `onCreate` crea todo; `onUpgrade`: `if (viejo < 4) crear las dos tablas`. `modo` se guarda como `ModoPomodoro.name`; `fin` en ms (nulo si no corre).

- [ ] **Step 1: Pruebas que fallan** (SQLite, `inMemoryDatabasePath` salvo la de migración): guardar y leer un estado corriendo (todos los campos, incluida `fin`); guardar otro lo reemplaza (un solo registro); estado pausado con `fin` nulo y materia nula; `borrarPomodoroEnCurso` → `null`; sin registro → `null`; `obtenerAjuste` desconocido → `null`; guardar y reemplazar un ajuste; sobreviven a cerrar y reabrir; migración desde una base v3 real (archivo temporal con el esquema v3: materias con `semestre`, apuntes, sesiones, intentos) conserva todo (Review Focus 5) y permite guardar estado y ajustes.
- [ ] **Step 2:** `flutter test test/data` → FALLA.
- [ ] **Step 3:** Implementar interfaz, SQLite y memoria.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: SQLite v4 con estado del Pomodoro en curso y ajustes`

---

### Task 3: Notificador y configuración de Android

**Files:** Create `lib/services/notificador_pomodoro.dart`, `lib/services/notificador_local.dart`, `test/support/notificador_falso.dart`; Modify `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`; Test `test/notificador_test.dart`

**Interfaces:**
- Produces:
  ```dart
  abstract class NotificadorPomodoro {
    Future<void> pedirPermisos();   // permiso de notificaciones (Android 13+); no lanza
    Future<void> programar({required DateTime fin, required String titulo, required String cuerpo});
    Future<void> cancelar();        // quita la programada y la mostrada (detiene la vibración)
  }
  class NotificadorNulo implements NotificadorPomodoro { const NotificadorNulo(); /* no hace nada */ }
  class NotificadorLocal implements NotificadorPomodoro {
    static Future<NotificadorLocal> crear();   // inicializa el plugin y crea el canal; lanza si falla
  }
  class NotificadorFalso implements NotificadorPomodoro { // en test/support
    int permisosPedidos; List<({DateTime fin, String titulo, String cuerpo})> programadas; int cancelaciones;
  }
  ```
  - `NotificadorLocal`: id de notificación fijo `1`; canal `pomodoro_fin` ("Fin de bloque Pomodoro", `Importance.max`); `AndroidNotificationDetails` con `priority: Priority.high`, `category: AndroidNotificationCategory.alarm`, `audioAttributesUsage: AudioAttributesUsage.alarm`, `playSound: true`, `enableVibration: true`, `vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400])`, `additionalFlags: Int32List.fromList([4])` (FLAG_INSISTENT: repite sonido y vibración), `timeoutAfter: 60000`, `autoCancel: true`, `visibility: NotificationVisibility.public`; `zonedSchedule(id:, scheduledDate: tz.TZDateTime.from(fin, tz.UTC), notificationDetails:, androidScheduleMode: exactAllowWhileIdle, title:, body:)` y, si lanza, reintento con `inexactAllowWhileIdle`; `cancelar` → `cancel(id: 1)`; `pedirPermisos` → `requestNotificationsPermission()` dentro de `try/catch`.
  - Android: `build.gradle.kts` con `isCoreLibraryDesugaringEnabled = true`, `multiDexEnabled = true` y `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`; manifiesto con permisos `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM` (`android:maxSdkVersion="32"`) y los receptores `ScheduledNotificationReceiver` y `ScheduledNotificationBootReceiver` (con sus `intent-filter`) dentro de `<application>`.

- [ ] **Step 1: Pruebas que fallan:** `NotificadorFalso` registra `programar`/`cancelar`/`pedirPermisos`; `NotificadorNulo` completa todos los métodos sin lanzar. (El comportamiento nativo de `NotificadorLocal` se verifica en el celular en la Tarea 6; aquí solo que el proyecto compila con la configuración nueva.)
- [ ] **Step 2:** `flutter test test/notificador_test.dart` → FALLA.
- [ ] **Step 3:** Implementar interfaz, nulo, local y falso; configurar Gradle y manifiesto.
- [ ] **Step 4:** `flutter test`, `flutter analyze` y `flutter build apk --debug` → PASAN/compila.
- [ ] **Step 5: Commit** `feat: notificador del Pomodoro con alarma y vibración repetida`

---

### Task 4: `PomodoroProvider`

**Files:** Create `lib/providers/pomodoro_provider.dart`; Modify `lib/main.dart`; Test `test/providers/pomodoro_provider_test.dart`

**Interfaces:**
- Consumes: `MateriasRepository`, `NotificadorPomodoro`, `ModoPomodoro`, `EstadoPomodoro`.
- Produces:
  ```dart
  typedef RegistrarSesion = Future<bool> Function({String? materiaId, required DateTime inicio, required int duracionSegundos});
  class PomodoroProvider extends ChangeNotifier {
    PomodoroProvider({required MateriasRepository repositorio, required NotificadorPomodoro notificador, required RegistrarSesion registrarSesion, DateTime Function() ahora = DateTime.now});
    ModoPomodoro get modo;  int get segundosRestantes;  int get segundosTotales;  bool get corriendo;
    int get ciclosCompletados;  String? get materiaId;  String? get materiaNombre;  bool get modoDemo;
    bool get hayBloqueActivo;                       // corriendo, o en pausa con tiempo ya consumido
    Future<void> restaurar();                       // lee ajuste y estado en curso; completa si ya venció
    Future<void> alReanudarApp();                   // actualizarTiempo + descartar aviso + reprogramar si corre
    void seleccionarMateria(String? id, String? nombre);   // ignorado si hayBloqueActivo
    Future<void> alternar();                        // iniciar / pausar
    Future<void> reiniciar();   Future<void> saltar();   Future<void> cambiarModo(ModoPomodoro modo);
    Future<void> alternarModoDemo(bool activado);
    void actualizarTiempo();                        // recalcula contra la hora de fin y completa si venció
  }
  ```
  - Por defecto: modo `enfoque`, `modoDemo = true` hasta que `restaurar` lea el ajuste `modo_demo`.
  - **Iniciar** (`alternar` sin correr): `pedirPermisos()` (solo la primera vez del proceso), fija `fin = ahora() + segundosRestantes`, arranca un `Timer.periodic(1 s)` que llama `actualizarTiempo`, programa el aviso (`titulo`/`cuerpo` por modo: enfoque → `'¡Bloque de enfoque terminado!'` / `'Buen trabajo${materiaNombre != null ? ' en $materiaNombre' : ''}. Toma un descanso.'`; descansos → `'Descanso terminado'` / `'A concentrarse de nuevo.'`) y guarda el estado en curso.
  - **Pausar:** primero `actualizarTiempo()`; si ya venció se completa; si no, cancela el temporizador y el aviso, `corriendo=false`, guarda el estado en pausa.
  - **Completar** (una sola vez; al vencer por tick, por `alReanudarApp` o en `restaurar`): usa como fin la hora de fin programada (aunque el tick llegue tarde); en `enfoque` llama `registrarSesion(materiaId, inicio: fin − segundosTotales, duracionSegundos: segundosTotales)` y `ciclos++`; pasa al siguiente modo (`ciclos % 4 == 0` → descanso largo, si no corto; tras un descanso → enfoque) detenido y con su duración completa; borra el estado en curso. No cancela el aviso del sistema (debe sonar aunque la app esté abierta).
  - **Reiniciar / saltar / cambiarModo:** cancelan temporizador y aviso, `corriendo=false`, restablecen el tiempo del modo resultante y borran el estado en curso. `saltar`: enfoque→descansoCorto, otro→enfoque. No guardan sesión.
  - **alternarModoDemo:** guarda el ajuste; si no hay bloque activo actualiza `segundosTotales/Restantes` al nuevo modo; si hay uno activo no lo toca.
  - **alReanudarApp:** `actualizarTiempo()`, luego `notificador.cancelar()` y, si sigue corriendo, reprograma el aviso a su `fin`.
  - **Restaurar:** estado corriendo con `fin` futuro → reanuda (temporizador + reprogramar); con `fin` pasado → completa; estado en pausa → restaura el tiempo restante detenido.
  - En `main.dart`: `MultiProvider` suma `ChangeNotifierProxyProvider<EstadisticasProvider, PomodoroProvider>` con `lazy: false`, `create` construye el provider con `registrarSesion: context.read<EstadisticasProvider>().registrarSesionEnfoque` y llama `restaurar()`; `StudyBuddyApp` recibe `notificador` (por defecto `NotificadorNulo`) y `_RefrescarAlReanudar` también llama `alReanudarApp()`. `main()` crea `NotificadorLocal.crear()` con `try/catch` (si falla usa `NotificadorNulo`).

- [ ] **Step 1: Pruebas que fallan** (`testWidgets` + `tester.pump(Duration)`, `RelojFalso`, `RepositorioMemoria`, `NotificadorFalso`, `registrarSesion` simulado que acumula llamadas):
  - estado inicial: modo enfoque, 15 s restantes (demo), no corre; con `alternarModoDemo(false)` pasa a 1500.
  - iniciar programa **un** aviso con `fin == ahora + 15 s` y título de enfoque; pedirPermisos se llamó.
  - el tiempo sigue la hora real (avanzar reloj 10 s + un tick → 5 s restantes) y un tick tardío (avanzar 60 s) completa **una** sola vez (Review Focus 1).
  - completar un enfoque: una sesión con `duracionSegundos == 15`, `inicio == fin − 15 s`, materia correcta; modo pasa a `descansoCorto` detenido con 5 s; el cuarto enfoque lleva a `descansoLargo`.
  - completar un descanso no registra sesión y vuelve a enfoque.
  - pausar cancela el aviso y conserva el tiempo; reanudar reprograma con la nueva `fin`; reiniciar, saltar y `cambiarModo` cancelan el aviso y no registran sesión (Review Focus 2).
  - persistencia: tras iniciar, `repositorio.obtenerPomodoroEnCurso()` tiene `corriendo`, `fin`, materia; tras pausar, `corriendo == false` y `fin == null`; tras reiniciar, `null`.
  - restaurar: un provider **nuevo** sobre el mismo repositorio y reloj con un estado corriendo y `fin` futuro reanuda con el tiempo restante correcto y reprograma; con `fin` pasado completa una vez y registra la sesión (Review Focus 1); un estado en pausa se restaura detenido.
  - `alReanudarApp`: llama `cancelar()` y, si corre, reprograma.
  - `seleccionarMateria` cambia materia solo si no hay bloque activo.
  - modo demostración: `alternarModoDemo(true)` con un bloque corriendo no cambia su tiempo; el ajuste se conserva en un provider nuevo (Review Focus 3).
- [ ] **Step 2:** `flutter test test/providers/pomodoro_provider_test.dart` → FALLA.
- [ ] **Step 3:** Implementar provider y cablear `main.dart`.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN (las pruebas antiguas de `pomodoro_test.dart` se reescriben en la Tarea 5; hasta entonces mantener la pantalla actual compilando).
- [ ] **Step 5: Commit** `feat: PomodoroProvider global con aviso y estado guardado`

---

### Task 5: Pantalla, pastilla en Inicio e interruptor en Perfil

**Files:** Rewrite `lib/screens/pomodoro_screen.dart`; Modify `lib/screens/inicio_screen.dart`, `lib/screens/perfil_screen.dart`, `lib/screens/detalle_materia_screen.dart` (si construye `PomodoroScreen`), `test/pomodoro_test.dart`, `test/widget_test.dart`; Test `test/pomodoro_pantalla_test.dart`

**Interfaces:**
- Consumes: `PomodoroProvider`.
- Produces:
  - `PomodoroScreen({super.key, this.materia})` (sin parámetro `ahora`): vista del provider. Al abrir, si recibe `materia` llama `seleccionarMateria(materia.id, materia.nombre)` (el provider lo ignora si hay bloque activo). Mismo diseño que hoy (selector de modos, círculo con `MM:SS`, ciclo X de 4, controles) con las `Key` `pomodoro-iniciar-pausar`, `pomodoro-reiniciar`, `pomodoro-saltar`. Título `Pomodoro: <materiaNombre>` o `Temporizador Pomodoro`. Si recibió una materia distinta a la del bloque activo, muestra el aviso `Ya hay un Pomodoro en curso de "<nombre>". Termínalo o reinícialo para cambiar de materia.`
  - Inicio: pastilla `Key('pastilla-pomodoro')` con `🍅 Pomodoro en curso · MM:SS` (o `🍅 Pomodoro en pausa · MM:SS`) cuando `hayBloqueActivo`; al tocarla abre `PomodoroScreen()`.
  - Perfil: `SwitchListTile` `Key('modo-demo')` con título `Modo demostración` y subtítulo `Bloques cortos: 15 s de enfoque, 5 s de descanso y 10 s de descanso largo, para mostrar la app.`; refleja y cambia `modoDemo`.
- [ ] **Step 1: Pruebas que fallan** (app completa con `RepositorioMemoria` y `NotificadorFalso`; helper `abrirApp` acepta el notificador y el reloj): la pantalla muestra `00:15` en modo demostración y `25:00` tras apagarlo en Perfil; salir de la pantalla y volver conserva el tiempo y sigue corriendo (Review Focus 1: iniciar, avanzar el reloj, salir, volver → `00:10` o el restante esperado); al terminar el bloque estando en Inicio se registra la sesión y Stats la refleja; la pastilla aparece en Inicio mientras corre, muestra el tiempo, desaparece al reiniciar y al tocarla abre la pantalla; abrir el Pomodoro de otra materia con un bloque activo no lo reemplaza y muestra el aviso (Review Focus 4); el interruptor de Perfil cambia el modo y respeta el estado actual del switch. Reescribir `test/pomodoro_test.dart` (las pruebas de lógica ya viven en el provider; aquí quedan las de pantalla) y actualizar `test/widget_test.dart` (`25:00` → `00:15` en la prueba de Pomodoro y su cambio a Descanso Corto `00:05`) y cualquier prueba que construya `PomodoroScreen(ahora: ...)`.
- [ ] **Step 2:** `flutter test test/pomodoro_pantalla_test.dart test/pomodoro_test.dart test/widget_test.dart` → FALLA.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: pantalla de Pomodoro sobre el provider, pastilla en Inicio y modo demostración en Perfil`

---

### Task 6: Documentación y verificación

**Files:** Modify `README.md`

- [ ] **Step 1:** `flutter analyze` limpio; `flutter test` todo verde (anotar el total); `flutter build apk --debug` compila.
- [ ] **Step 2:** README: estado (Pomodoro global con aviso, vibración repetida, modo demostración), tabla de pantallas (Pomodoro, Perfil, Inicio), esquema v4 y la nota de batería de Vivo/Xiaomi.
- [ ] **Step 3: Commit** `docs: README del Pomodoro global`. **No hacer push.** (La verificación en el celular real se hace después, fuera de este plan.)
