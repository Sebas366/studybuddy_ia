# Fase 2 · Parte 1: materias y apuntes reales con persistencia: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que Edwin pueda crear, editar y borrar materias y apuntes reales en StudyBuddy IA, y que sigan ahí al cerrar y reabrir la app en Android.

**Architecture:** Una capa de repositorio (`MateriasRepository`) con una implementación SQLite (`sqflite`) y un `ChangeNotifier` (`MateriasProvider`, paquete `provider`) que recarga la lista tras cada cambio. Las pantallas leen del provider; las materias de `DatosDemo` se marcan con `esDemo: true` y conservan sus pantallas simuladas para Plan y Stats. Las pruebas de widgets usan un repositorio en memoria; el SQL real se prueba aparte con `sqflite_common_ffi`.

**Tech Stack:** Flutter (Dart `^3.13.2`), Material 3, `provider`, `sqflite`, `path`; dev: `sqflite_common_ffi`.

**Spec:** `docs/superpowers/specs/2026-10-27-fase2-parte1-persistencia-design.md` (aprobado por Edwin el 2026-10-27). Léelo antes de empezar.

## Global Constraints

- Idioma: textos de interfaz, nombres de clases/funciones/variables y comentarios en **español**; comentarios `///` en clases y miembros públicos, como en `lib/models/materia.dart`.
- Plataforma de prueba: **Android** (no escritorio Linux).
- Nada de IA, claves ni llamadas a red. El repo es público (https://github.com/Sebas366/studybuddy_ia).
- Modo claro y oscuro deben seguir funcionando; reutilizar el estilo de tarjetas/modales que ya existe en `inicio_screen.dart`.
- Límites: nombre de materia máx. **60** caracteres; título de apunte máx. **120** (decisión de este plan; el spec solo pide "razonable").
- Plan y Stats **no se modifican** (siguen leyendo `DatosDemo`). `resumen_ia_screen.dart` tampoco se modifica.
- La base de datos arranca en **versión 1**, sin columnas de IA.
- Línea base verificada antes de empezar: `flutter test` → 6 pruebas pasan; `flutter analyze` → "No issues found!". Debe terminar igual de limpio.
- Cada commit termina con la línea: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. No hacer `git push` en este plan; eso lo decide Edwin al final.

## Review Focus

Entradas/fallos que el spec implica pero no detalla, de más a menos probable. Cada uno tiene su prueba en la tarea indicada:

1. Nombre de materia vacío, solo espacios, o de 61 caracteres → no se guarda y se explica por qué (Tarea 1 y 6).
2. Doble toque rápido en "Guardar" → se crea **un** registro, no dos (Tareas 6 y 8).
3. Borrar una materia con apuntes borra también sus apuntes en la base (cascada real, `PRAGMA foreign_keys`) (Tarea 4).
4. Cerrar y reabrir la base conserva los datos (Tarea 4).
5. Borrar la materia desde su propia pantalla de detalle → vuelve a Inicio sin error (Tarea 8).

## Mapa de archivos

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `pubspec.yaml` | Modificar | Dependencias (`sqflite`, `path`, `provider`; dev `sqflite_common_ffi`) |
| `lib/utils/formato_fecha.dart` | Crear | `formatearFecha` ("27 Oct 2026") |
| `lib/utils/validadores.dart` | Crear | Validación de nombre, título y texto |
| `lib/data/catalogo_materia.dart` | Crear | Lista corta de degradados e iconos |
| `lib/models/materia.dart` | Modificar | `esDemo`, `colorIndice`, `iconoClave`, `subtituloPorConteo` |
| `lib/models/apunte.dart` | Modificar | Campos de IA opcionales |
| `lib/data/datos_demo.dart` | Modificar | Marcar las 3 materias con `esDemo: true` |
| `lib/data/materias_repository.dart` | Crear | Interfaz abstracta |
| `lib/data/materias_repository_sqflite.dart` | Crear | Implementación SQLite |
| `lib/providers/materias_provider.dart` | Crear | Estado + operaciones (recarga tras cada cambio) |
| `lib/main.dart` | Modificar | Abrir la base e inyectar el provider |
| `lib/widgets/formulario_materia.dart` | Crear | Hoja modal crear/editar materia |
| `lib/widgets/dialogo_confirmar_borrado.dart` | Crear | Confirmación de borrado |
| `lib/widgets/aviso_ia_fase3.dart` | Crear | Aviso "disponible en la Fase 3" |
| `lib/widgets/materia_card.dart` | Modificar | Ocultar progreso en reales; `onLongPress` |
| `lib/screens/inicio_screen.dart` | Modificar | Estado vacío, lista del provider, sin racha |
| `lib/screens/detalle_materia_screen.dart` | Modificar | Datos vivos, apuntes reales, menú |
| `lib/screens/formulario_apunte_screen.dart` | Crear | Pantalla crear/editar apunte |
| `lib/screens/apunte_screen.dart` | Crear | Ver un apunte real (texto + aviso de IA) |
| `test/support/repositorio_memoria.dart` | Crear | Repositorio falso para pruebas de widgets |
| `test/**` | Crear/Reescribir | Ver cada tarea |
| `README.md` | Modificar | Estado de la Fase 2 parte 1 (Tarea 10) |

---

### Task 1: Utilidades de fecha y validación

**Files:**
- Create: `lib/utils/formato_fecha.dart`, `lib/utils/validadores.dart`
- Test: `test/utils/formato_fecha_test.dart`, `test/utils/validadores_test.dart`

**Interfaces:**
- Produces:
  - `String formatearFecha(DateTime fecha)` → `'27 Oct 2026'` (día sin ceros a la izquierda; meses `Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic`).
  - `const int maxNombreMateria = 60;` `const int maxTituloApunte = 120;`
  - `String? validarNombreMateria(String? valor)`, `String? validarTituloApunte(String? valor)`, `String? validarTextoApunte(String? valor)`: devuelven `null` si es válido o el mensaje de error.

- [ ] **Step 1: Escribir pruebas que fallan**
  - `formato_fecha_test.dart`: `formatearFecha(DateTime(2026, 10, 27))` es `'27 Oct 2026'`; `formatearFecha(DateTime(2026, 1, 5))` es `'5 Ene 2026'`; `formatearFecha(DateTime(2026, 12, 31))` es `'31 Dic 2026'`.
  - `validadores_test.dart`: `validarNombreMateria(null)`, `('')` y `('   ')` devuelven `'Escribe el nombre de la materia.'`; `('A' * 60)` devuelve `null`; `('A' * 61)` devuelve `'El nombre no puede pasar de 60 caracteres.'`; `(' Redes ')` devuelve `null`. `validarTituloApunte('')` → `'Escribe el título del apunte.'`; `('T' * 121)` → `'El título no puede pasar de 120 caracteres.'`; `('DHCP')` → `null`. `validarTextoApunte('  ')` → `'Escribe el texto del apunte.'`; `('texto')` → `null`.
- [ ] **Step 2:** `flutter test test/utils` → FALLA (archivos no existen).
- [ ] **Step 3:** Implementar las funciones y constantes de Interfaces. El largo se mide sobre el texto con `trim()`.
- [ ] **Step 4:** `flutter test test/utils` → PASA.
- [ ] **Step 5: Commit** `git add lib/utils test/utils && git commit -m "feat: utilidades de fecha y validación"`

---

### Task 2: Catálogo de colores e iconos

**Files:**
- Create: `lib/data/catalogo_materia.dart`
- Test: `test/data/catalogo_materia_test.dart`

**Interfaces:**
- Produces: `class CatalogoMateria` (constructor privado) con
  - `static const List<List<Color>> degradados` → **6** degradados de 2 colores; los 3 primeros son `AppColors.degradadoArquitectura`, `degradadoIaDatos`, `degradadoDesarrolloMovil`; los otros 3 (rosa, violeta, verde) los eliges tú.
  - `static const Map<String, IconData> iconos` → **7** entradas, claves: `memoria`, `cerebro`, `movil`, `red`, `balanza`, `codigo`, `libro`.
  - `static const String iconoPorDefecto = 'libro'`
  - `static List<Color> degradadoPorIndice(int indice)`: si el índice está fuera de rango devuelve `degradados.first`.
  - `static IconData iconoPorClave(String clave)`: si la clave no existe devuelve el icono de `iconoPorDefecto`.

- [ ] **Step 1: Pruebas que fallan:** hay 6 degradados y cada uno tiene 2 colores; hay 7 iconos y existe la clave `'red'`; `degradadoPorIndice(99)` y `(-1)` son iguales a `degradados.first`; `iconoPorClave('no-existe')` es `iconos['libro']`.
- [ ] **Step 2:** `flutter test test/data/catalogo_materia_test.dart` → FALLA.
- [ ] **Step 3:** Implementar. Para los iconos usar constantes de `Icons` (mantiene el *tree-shaking* de fuentes).
- [ ] **Step 4:** misma orden → PASA.
- [ ] **Step 5: Commit** `feat: catálogo de colores e iconos para materias`

---

### Task 3: Modelos `Materia` y `Apunte`

**Files:**
- Modify: `lib/models/materia.dart`, `lib/models/apunte.dart`, `lib/data/datos_demo.dart` (las 3 `Materia(` en las líneas ~21, ~154 y ~288)
- Test: `test/models/modelos_test.dart`

**Interfaces:**
- Produces:
  - `Materia` gana campos `final bool esDemo` (por defecto `false`), `final int colorIndice` (por defecto `0`), `final String iconoClave` (por defecto `'libro'`), todos opcionales en el constructor `const`. Gana `static String subtituloPorConteo(int cantidad)` → `'Sin apuntes'` (0), `'1 apunte'`, `'N apuntes'`.
  - `Apunte`: `ideasClave` pasa a `= const []`, y `resumenCorto`, `resumenMedio`, `resumenDetallado` a `= ''` (ya no `required`). El resto no cambia (`fecha` sigue siendo el texto ya formateado).
  - Las 3 materias de `DatosDemo.materias` pasan `esDemo: true`.

- [ ] **Step 1: Pruebas que fallan:** `Materia.subtituloPorConteo(0)=='Sin apuntes'`, `(1)=='1 apunte'`, `(3)=='3 apuntes'`; `DatosDemo.materias` no está vacía y todas tienen `esDemo == true`; un `Apunte(id:'a', titulo:'t', materiaId:'m', fecha:'1 Ene 2026', contenido:'x')` se construye y tiene `ideasClave` vacío y `resumenCorto == ''`.
- [ ] **Step 2:** `flutter test test/models` → FALLA.
- [ ] **Step 3:** Hacer los cambios de Interfaces.
- [ ] **Step 4:** `flutter test` (todo) y `flutter analyze` → PASAN igual que la línea base (las 6 pruebas viejas siguen verdes porque Inicio aún lee `DatosDemo`).
- [ ] **Step 5: Commit** `feat: modelos preparados para materias y apuntes reales`

---

### Task 4: Repositorio SQLite

**Files:**
- Modify: `pubspec.yaml` (ejecutar `flutter pub add sqflite path` y `flutter pub add --dev sqflite_common_ffi`)
- Create: `lib/data/materias_repository.dart`, `lib/data/materias_repository_sqflite.dart`
- Test: `test/data/materias_repository_sqflite_test.dart`

**Interfaces:**
- Consumes: `CatalogoMateria` (Tarea 2), `Materia`/`Apunte` (Tarea 3), `formatearFecha` (Tarea 1).
- Produces:
  ```dart
  abstract class MateriasRepository {
    Future<List<Materia>> obtenerMaterias();
    Future<Materia> crearMateria({required String nombre, required String descripcion, required int colorIndice, required String iconoClave});
    Future<void> actualizarMateria({required String id, required String nombre, required String descripcion, required int colorIndice, required String iconoClave});
    Future<void> borrarMateria(String id);
    Future<Apunte> crearApunte({required String materiaId, required String titulo, required String contenido});
    Future<void> actualizarApunte({required String id, required String titulo, required String contenido});
    Future<void> borrarApunte(String id);
  }
  class MateriasRepositorySqflite implements MateriasRepository {
    static Future<MateriasRepositorySqflite> abrir({String? ruta}); // ruta por omisión: join(await getDatabasesPath(), 'studybuddy.db')
    Future<void> cerrar();
    @visibleForTesting Database get baseDatos;
  }
  ```
  - Reglas: `obtenerMaterias` devuelve la más nueva primero y, dentro de cada materia, los apuntes más nuevos primero (`ORDER BY creada DESC, rowid DESC`). Cada `Materia` devuelta trae `progreso: 0`, `subtitulo: Materia.subtituloPorConteo(n)`, `preguntas: const []`, `respuestasSimuladasIa: const []`, `esDemo: false`, `icono`/`colorInicio`/`colorFin` resueltos con el catálogo, y `apuntes` cargados. `Apunte.fecha` se calcula con `formatearFecha` sobre la fecha de **creación**; `actualizarApunte` solo cambia título, contenido y `modificada`.
  - Esquema v1: `materias(id TEXT PRIMARY KEY, nombre TEXT NOT NULL, descripcion TEXT NOT NULL, color_indice INTEGER NOT NULL, icono_clave TEXT NOT NULL, creada INTEGER NOT NULL)` y `apuntes(id TEXT PRIMARY KEY, materia_id TEXT NOT NULL REFERENCES materias(id) ON DELETE CASCADE, titulo TEXT NOT NULL, contenido TEXT NOT NULL, creada INTEGER NOT NULL, modificada INTEGER NOT NULL)`. Activar `PRAGMA foreign_keys = ON` en `onConfigure`. `creada`/`modificada` son milisegundos desde la época. Ids: `mat_<microsegundos>` y `apu_<microsegundos>`.

- [ ] **Step 1: Pruebas que fallan** (en `setUpAll`: `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;`; cada prueba abre con `ruta: inMemoryDatabasePath` salvo la de reabrir):
  - `crea una materia y la devuelve con 0 apuntes`: `subtitulo == 'Sin apuntes'`, `esDemo == false`, `progreso == 0`.
  - `devuelve materias y apuntes del más nuevo al más viejo` (crear A, B; apuntes x, y en A → `[B, A]` y `[y, x]`).
  - `actualiza nombre, descripción, color e icono` y `actualiza título y contenido de un apunte sin cambiar su fecha`.
  - `borrar una materia borra sus apuntes` (Review Focus 3): después de borrar, `baseDatos.rawQuery('SELECT COUNT(*) AS n FROM apuntes')` da `n == 0`.
  - `borrar un apunte no toca los demás`.
  - `los datos sobreviven a cerrar y reabrir` (Review Focus 4): usar un archivo en `Directory.systemTemp.createTempSync('studybuddy_test_')`, crear materia + apunte, `cerrar()`, `abrir(ruta: mismaRuta)`, comprobar que siguen; borrar el directorio en `tearDown`.
- [ ] **Step 2:** `flutter test test/data/materias_repository_sqflite_test.dart` → FALLA. (Si sale un error de `libsqlite3.so` no encontrada, instalar SQLite del sistema: `sudo pacman -S sqlite`.)
- [ ] **Step 3:** Implementar interfaz y clase según Interfaces.
- [ ] **Step 4:** misma orden → PASA; `flutter analyze` limpio.
- [ ] **Step 5: Commit** `feat: repositorio SQLite de materias y apuntes`

---

### Task 5: `MateriasProvider` y repositorio en memoria para pruebas

**Files:**
- Modify: `pubspec.yaml` (`flutter pub add provider`)
- Create: `lib/providers/materias_provider.dart`, `test/support/repositorio_memoria.dart`
- Test: `test/providers/materias_provider_test.dart`

**Interfaces:**
- Consumes: `MateriasRepository` (Tarea 4), validadores (Tarea 1).
- Produces:
  ```dart
  class RepositorioMemoria implements MateriasRepository { RepositorioMemoria(); } // mismas reglas de orden y subtítulo que el SQLite; guarda en listas
  class MateriasProvider extends ChangeNotifier {
    MateriasProvider(MateriasRepository repositorio);
    List<Materia> get materias;     // no modificable
    bool get cargando;              // true hasta que termina la primera cargar()
    Future<void> cargar();          // lee del repositorio y notifica
    Materia? porId(String id);
    Future<void> crearMateria({required String nombre, String descripcion = '', int colorIndice = 0, String iconoClave = CatalogoMateria.iconoPorDefecto});
    Future<void> actualizarMateria({required String id, required String nombre, String descripcion = '', int colorIndice = 0, String iconoClave = CatalogoMateria.iconoPorDefecto});
    Future<void> borrarMateria(String id);
    Future<void> crearApunte({required String materiaId, required String titulo, required String contenido});
    Future<void> actualizarApunte({required String id, required String titulo, required String contenido});
    Future<void> borrarApunte(String id);
  }
  ```
  - Cada operación recorta (`trim`) los textos, valida con los validadores (si hay mensaje lanza `ArgumentError(mensaje)` sin tocar el repositorio), llama al repositorio y luego `await cargar()`.

- [ ] **Step 1: Pruebas que fallan** (con `RepositorioMemoria`): antes de `cargar()` `cargando` es `true`, después `false` y `materias` vacía; `crearMateria(nombre: '  Redes  ')` deja una materia con nombre `'Redes'` y notifica a un listener; `crearMateria(nombre: '   ')` lanza `ArgumentError` y `materias` sigue vacía; `crearApunte` actualiza `materias.first.subtitulo` a `'1 apunte'`; `crearApunte` con título vacío lanza `ArgumentError`; `borrarMateria` la quita de `materias`; `porId('no-existe')` es `null`.
- [ ] **Step 2:** `flutter test test/providers` → FALLA.
- [ ] **Step 3:** Implementar `RepositorioMemoria` y `MateriasProvider`.
- [ ] **Step 4:** `flutter test test/providers` → PASA; `flutter test` completo sigue en verde.
- [ ] **Step 5: Commit** `feat: MateriasProvider y repositorio en memoria`

---

### Task 6: Inicio vacío, crear materia y persistencia conectada

**Files:**
- Create: `lib/widgets/formulario_materia.dart`
- Modify: `lib/main.dart`, `lib/screens/inicio_screen.dart`, `lib/widgets/materia_card.dart`
- Test (reescribir): `test/widget_test.dart`

**Interfaces:**
- Consumes: `MateriasProvider`, `RepositorioMemoria`, `CatalogoMateria`, validadores.
- Produces:
  - `Future<void> mostrarFormularioMateria(BuildContext context, {Materia? materia})` en `formulario_materia.dart`: hoja modal con título "Nueva materia" (o "Editar materia" si `materia != null`), campos nombre y descripción, 6 círculos de color, 7 iconos y un botón "Guardar materia" (en edición, "Guardar cambios"). Usa `Form` + los validadores. Mientras guarda, ignora toques repetidos (bandera `_guardando`). Al terminar cierra la hoja y muestra el SnackBar `¡Materia "X" creada!` (o `actualizada`). **Keys fijas:** `Key('campo-nombre')`, `Key('campo-descripcion')`, `Key('color-$i')` (i = índice), `Key('icono-$clave')`, `Key('guardar-materia')`.
  - `StudyBuddyApp({super.key, required MateriasRepository repositorio})`: envuelve el `MaterialApp` con `ChangeNotifierProvider<MateriasProvider>(create: (_) => MateriasProvider(repositorio)..cargar())`. `main()` pasa a `async`: `await MateriasRepositorySqflite.abrir()` y lo inyecta.
  - `MateriaCard`: la sección "Progreso general" (texto y barra) solo se muestra si `materia.esDemo`.
  - `InicioScreen` deja de usar `DatosDemo` y la lista local: lee `context.watch<MateriasProvider>()`. Cambios: se **elimina** la tarjeta "¡Racha de 7 días activa! 🔥"; se elimina el modal antiguo `_mostrarModalNuevaMateria` (se usa `mostrarFormularioMateria`); mientras `cargando`, muestra un `CircularProgressIndicator`; si no hay materias (sin filtro), debajo del encabezado muestra el estado vacío: ícono 📚, `Aún no tienes materias`, `Crea la primera para empezar a guardar tus apuntes.` y un botón `Crear mi primera materia` con `Key('crear-primera-materia')` (no se muestran buscador ni encabezado "Mis Materias"); si hay materias, buscador + "Mis Materias (N)" + botón "Nueva materia" como hoy. El filtro busca en nombre, descripción y títulos de apuntes. Nombres largos: la tarjeta ya usa `maxLines: 2` + elipsis; no debe haber desbordes.

- [ ] **Step 1: Reescribir `test/widget_test.dart`** con un helper `abrirApp(WidgetTester, RepositorioMemoria)` (mismo `configurarPantalla` de hoy + `pumpWidget(StudyBuddyApp(repositorio: repo))` + `pumpAndSettle`) y estas pruebas:
  - `Inicio arranca vacío con botón para crear la primera materia`: aparecen `'¡Hola, Edwin! 👋'`, `'Aún no tienes materias'` y `Key('crear-primera-materia')`; **no** aparecen `'¡Racha de 7 días activa! 🔥'` ni `'Arquitectura de Computadores'`.
  - `Crear la primera materia desde el estado vacío`: tocar el botón, escribir `'Servicios Telemáticos'` en `campo-nombre`, tocar `color-1` e `icono-red`, tocar `guardar-materia`; luego aparece `'Servicios Telemáticos'` y `'Sin apuntes'`, desaparece `'Aún no tienes materias'`, y `repo.obtenerMaterias()` devuelve 1 con `colorIndice == 1` e `iconoClave == 'red'`.
  - `No guarda un nombre vacío o de solo espacios` (Review Focus 1): escribir `'   '`, guardar → aparece `'Escribe el nombre de la materia.'` y el repositorio sigue con 0 materias.
  - `Rechaza un nombre de 61 caracteres y acepta uno de 60`: con `'A'*61` aparece `'El nombre no puede pasar de 60 caracteres.'`; con `'A'*60` se guarda y `tester.takeException()` es `null`.
  - `Doble toque en Guardar crea una sola materia` (Review Focus 2): dos `tester.tap` seguidos sobre `guardar-materia` sin `pump` entre ellos, luego `pumpAndSettle` → el repositorio tiene exactamente 1.
  - `Pestañas Plan, Stats y Perfil` (adaptar la existente, sin la afirmación de racha ni materias demo en Inicio).
  - `Buscador filtra materias reales`: sembrar `'Redes de Computadores'` y `'Cálculo'` con `repo.crearMateria(...)` antes de abrir; escribir `'redes'` → solo la primera visible; limpiar → ambas.
  - `Pomodoro se abre desde una materia real` (adaptar la existente: tocar la tarjeta sembrada, luego `'Pomodoro'`, comprobar `'25:00'`, `'Enfoque'`, cambiar a `'Descanso Corto'` → `'05:00'`).
  - `Alternancia de Modo Oscuro desde Perfil` (la existente, sin cambios de fondo).
- [ ] **Step 2:** `flutter test test/widget_test.dart` → FALLA (no compila: `StudyBuddyApp` aún no recibe `repositorio`).
- [ ] **Step 3:** Implementar los cambios de Interfaces (formulario, `main.dart`, `MateriaCard`, `InicioScreen`).
- [ ] **Step 4:** `flutter test` y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: Inicio vacío, crear materia y persistencia SQLite`

---

### Task 7: Editar y borrar materias desde Inicio

**Files:**
- Create: `lib/widgets/dialogo_confirmar_borrado.dart`
- Modify: `lib/widgets/materia_card.dart`, `lib/screens/inicio_screen.dart`
- Test: `test/gestion_materias_test.dart`

**Interfaces:**
- Produces:
  - `Future<bool> confirmarBorrado(BuildContext context, {required String titulo, required String mensaje})`: `AlertDialog` con botones `Cancelar` (devuelve `false`) y `Borrar` (devuelve `true`); cerrar tocando fuera devuelve `false`.
  - `MateriaCard` gana `final VoidCallback? onLongPress` (pasa a `InkWell.onLongPress`).
  - En Inicio, mantener pulsada una tarjeta abre una hoja inferior con `ListTile`s `Key('opcion-editar-materia')` ("Editar") y `Key('opcion-borrar-materia')` ("Borrar"). Editar → `mostrarFormularioMateria(context, materia: m)`. Borrar → `confirmarBorrado` con título `Borrar materia` y mensaje `Se borrará "NOMBRE" y sus N apunte(s). Esta acción no se puede deshacer.` (N con singular/plural correcto); si confirma → `provider.borrarMateria(m.id)`.

- [ ] **Step 1: Pruebas que fallan** (helper de siembra con `RepositorioMemoria`): `mantener pulsada una tarjeta ofrece editar y borrar`; `editar cambia el nombre y se refleja en Inicio` (el formulario abre con el nombre actual precargado); `cancelar el borrado conserva la materia`; `confirmar el borrado elimina la materia y sus apuntes` (sembrar materia con 2 apuntes; mensaje contiene `'2 apuntes'`; al terminar aparece `'Aún no tienes materias'` y el repositorio no tiene materias).
- [ ] **Step 2:** `flutter test test/gestion_materias_test.dart` → FALLA.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `flutter test` y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: editar y borrar materias`

---

### Task 8: Detalle de materia con apuntes reales

**Files:**
- Create: `lib/screens/formulario_apunte_screen.dart`
- Modify: `lib/screens/detalle_materia_screen.dart` (pasa a `StatefulWidget`)
- Test: `test/apuntes_test.dart`

**Interfaces:**
- Consumes: `MateriasProvider`, `confirmarBorrado`, `mostrarFormularioMateria`, `formatearFecha`.
- Produces:
  - `FormularioApunteScreen({super.key, required String materiaId, Apunte? apunte})`: pantalla completa; título de la barra `Nuevo apunte` / `Editar apunte`; campos `Key('campo-titulo-apunte')` y `Key('campo-texto-apunte')` (multilínea), botón `Key('guardar-apunte')` "Guardar apunte"; validadores de la Tarea 1; ignora toques repetidos; al guardar hace `Navigator.pop`.
  - `DetalleMateriaScreen` (misma firma pública: `materia`): si `materia.esDemo` se comporta **exactamente como hoy** (sin menú, sin "+ Nuevo", barra de progreso visible, sus apuntes llevan a `ResumenIaScreen`). Si es real: toma la materia viva con `context.watch<MateriasProvider>().porId(id)`; si ya no existe, hace `Navigator.pop` **una sola vez** (bandera) y no falla; oculta la barra y "X% dominado"; en la cabecera muestra un `PopupMenuButton` (`Key('menu-materia')`) con "Editar materia" y "Borrar materia" (borrar usa `confirmarBorrado` y **no** hace `pop` manual: el pop lo hace el punto anterior al desaparecer la materia); sobre la lista de apuntes un `TextButton` `Key('nuevo-apunte')` "+ Nuevo" que abre `FormularioApunteScreen`; el texto de ayuda pasa a "Mantén pulsado para editar o borrar"; texto vacío: `Aún no tienes apuntes. Toca "+ Nuevo" para crear el primero.`; cada apunte muestra solo la fecha en el subtítulo (sin "ideas clave"); mantener pulsado abre hoja con `Key('opcion-editar-apunte')` y `Key('opcion-borrar-apunte')` (borrar con `confirmarBorrado`, título `Borrar apunte`). Tocar un apunte real navega a `ApunteScreen` (Tarea 9); hasta entonces, déjalo sin acción.

- [ ] **Step 1: Pruebas que fallan** (helper: abrir la app con una materia real sembrada y tocar su tarjeta):
  - `una materia nueva muestra el mensaje de apuntes vacíos y no muestra progreso`: aparece el texto de vacío; no aparece `'dominado'`.
  - `crear un apunte lo agrega a la lista con la fecha de hoy`: `nuevo-apunte` → escribir título `'DHCP y proceso DORA'` y texto → `guardar-apunte` → aparecen el título y `formatearFecha(DateTime.now())`; la cabecera dice `'1 apunte'`.
  - `no guarda apuntes sin título o sin texto`: aparecen `'Escribe el título del apunte.'` y `'Escribe el texto del apunte.'`; el repositorio sigue sin apuntes.
  - `doble toque en Guardar crea un solo apunte` (Review Focus 2).
  - `editar un apunte cambia su título` y `borrar un apunte pide confirmación y lo elimina`.
  - `borrar la materia desde su detalle vuelve a Inicio` (Review Focus 5): `menu-materia` → "Borrar materia" → `Borrar`; aparece `'Aún no tienes materias'` y `tester.takeException()` es `null`.
  - `una materia de demostración no muestra menú ni "+ Nuevo"`: montar `DetalleMateriaScreen(materia: DatosDemo.materias.first)` dentro de `MaterialApp` + `ChangeNotifierProvider(create: (_) => MateriasProvider(RepositorioMemoria()))`; `menu-materia` y `nuevo-apunte` no existen; sí aparece `'dominado'`.
- [ ] **Step 2:** `flutter test test/apuntes_test.dart` → FALLA.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `flutter test` y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: apuntes reales en el detalle de materia`

---

### Task 9: Ver un apunte y avisos de IA

**Files:**
- Create: `lib/widgets/aviso_ia_fase3.dart`, `lib/screens/apunte_screen.dart`
- Modify: `lib/screens/detalle_materia_screen.dart`
- Test: `test/avisos_ia_test.dart`

**Interfaces:**
- Produces:
  - `AvisoIaFase3({super.key})`: tarjeta con borde punteado y dos textos fijos: `Resumen, ideas clave y quiz con IA` (negrita) y `Disponible en la Fase 3.`
  - `Future<void> mostrarAvisoIaFase3(BuildContext context)`: `AlertDialog` con título `Función con IA`, contenido `AvisoIaFase3` y botón `Entendido`.
  - `ApunteScreen({super.key, required Apunte apunte, required Materia materia})`: barra `Apunte`; cabecera igual a la de `ResumenIaScreen` (etiqueta de materia, fecha, título); tarjeta con `apunte.contenido` (con scroll, sin desbordes); luego `AvisoIaFase3`; botón "Copiar" que pone título + materia + contenido en el portapapeles.
  - En `DetalleMateriaScreen`, para materias **reales**: Resumir, Quiz IA y Tutor IA llaman `mostrarAvisoIaFase3` en lugar de navegar; el subtítulo de Quiz IA es `Próximamente` (no "0 preguntas"); tocar un apunte abre `ApunteScreen`. Pomodoro y Escanear no cambian. Las materias demo no cambian.
- Decisión del plan: se usa una pantalla nueva en vez de modificar `resumen_ia_screen.dart` para no tocar la pantalla simulada que siguen usando las materias demo.

- [ ] **Step 1: Pruebas que fallan:**
  - `Resumir, Quiz IA y Tutor IA muestran el aviso en una materia real`: por cada botón aparece `'Disponible en la Fase 3.'`; tocar `'Entendido'` lo cierra; no aparecen `'Resumen Inteligente'`, ni `'Quiz:'`, ni `'Tutor IA:'` (no se navegó).
  - `tocar un apunte real muestra su texto y el aviso`: aparecen título, fecha, texto y `'Disponible en la Fase 3.'`; no aparecen `'Ideas Clave'` ni `'Crear quiz'`.
  - `un apunte con texto muy largo no desborda`: contenido de 5000 caracteres → `tester.takeException()` es `null`.
  - `en una materia de demostración Resumir sigue abriendo el resumen simulado` (montaje como en la Tarea 8): aparece `'Resumen Inteligente'`.
- [ ] **Step 2:** `flutter test test/avisos_ia_test.dart` → FALLA.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `flutter test` y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: pantalla de apunte real y avisos de IA`

---

### Task 10: Verificación final, README y prueba en Android

**Files:**
- Modify: `README.md`

- [ ] **Step 1:** `flutter analyze` → `No issues found!`; `flutter test` → todas verdes (anotar el total).
- [ ] **Step 2:** `flutter build apk --debug` → compila sin errores.
- [ ] **Step 3: Prueba manual en Android** (emulador o celular con `flutter run`), verificar y anotar el resultado de cada punto: (a) primera apertura muestra Inicio vacío sin racha; (b) crear una materia con color e icono; (c) crear un apunte; (d) cerrar la app por completo desde recientes y reabrirla: la materia y el apunte siguen; (e) editar y borrar un apunte; (f) editar y borrar la materia; (g) Resumir/Quiz/Tutor muestran el aviso; (h) pestañas Plan y Stats se ven como antes (con sus materias de demostración); (i) modo oscuro. Si algo falla, corregirlo con su prueba antes de seguir.
- [ ] **Step 4:** Actualizar `README.md`: el aviso del inicio pasa a decir que la Fase 1 (mockups) está completa y que la **Fase 2 parte 1** agrega materias y apuntes reales con persistencia local (sin IA todavía; Plan, Stats y Pomodoro siguen con datos de demostración); actualizar la tabla de pantallas, la estructura de carpetas (`providers/`, `utils/`) y la lista de tecnologías (`provider`, `sqflite`).
- [ ] **Step 5: Commit** `docs: README de la Fase 2 parte 1`. **No hacer push**: avisar a Edwin que están listos los commits y preguntarle.
