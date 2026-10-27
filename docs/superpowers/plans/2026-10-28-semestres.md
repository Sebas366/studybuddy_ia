# Materias por semestre: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que cada materia tenga un semestre y que Inicio permita ver un semestre a la vez (o todos).

**Architecture:** Campo `semestre` en `Materia` y en SQLite (versión 3, migración que deriva el semestre de la fecha de creación). `MateriasProvider` expone los semestres existentes; el formulario de materia gana el campo; `InicioScreen` filtra por el semestre elegido.

**Tech Stack:** Flutter, `provider`, `sqflite` (ya instalados). Sin dependencias nuevas.

**Spec:** `docs/superpowers/specs/2026-10-28-semestres-design.md`.

## Global Constraints

- Español en textos, nombres y comentarios `///`. Android. Sin dependencias nuevas.
- Base de datos a **versión 3** sin perder nada: `onUpgrade` encadena `<2` (tablas de estadísticas) y `<3` (columna semestre).
- Línea base: `flutter test` → 131 pruebas pasan; `flutter analyze` limpio. Debe terminar igual.
- Cada commit termina con `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. No hacer `git push`.
- Pomodoro, quiz, apuntes, Plan y Stats no se modifican.

## Review Focus

1. La migración desde v1 y desde v2 asigna `AAAA-1`/`AAAA-2` por fecha de creación y conserva materias, apuntes y estadísticas (Tarea 2).
2. Crear una materia en un semestre distinto al que se ve no la "pierde": la vista cambia a ese semestre (Tarea 4).
3. Borrar o mover la última materia del semestre seleccionado no deja la pantalla vacía ni rota: vuelve al más reciente (Tarea 4).
4. El buscador encuentra materias de otros semestres (Tarea 4).
5. Semestre vacío o de más de 20 caracteres no se guarda y se explica (Tareas 1 y 3).

## Mapa de archivos

| Archivo | Acción |
|---|---|
| `lib/utils/semestres.dart` | Crear: `semestreActual`, `validarSemestre`, `maxSemestre` |
| `lib/models/materia.dart` | Modificar: campo `semestre` |
| `lib/data/materias_repository.dart`, `materias_repository_sqflite.dart` | Modificar: parámetro `semestre`, esquema v3 |
| `lib/providers/materias_provider.dart` | Modificar: `semestre` en crear/actualizar, getter `semestres` |
| `lib/widgets/formulario_materia.dart` | Modificar: campo y sugerencias; devuelve el semestre guardado |
| `lib/widgets/materia_card.dart`, `lib/screens/inicio_screen.dart` | Modificar: selector, filtro, etiqueta |
| `test/support/*`, pruebas existentes | Actualizar llamadas a `crearMateria`/`sembrarMateria` |

---

### Task 1: Utilidades de semestre

**Files:** Create `lib/utils/semestres.dart`; Test `test/utils/semestres_test.dart`

**Interfaces:**
- Produces: `const int maxSemestre = 20;` `String semestreActual(DateTime fecha)` → `'2026-1'` (meses 1–6) o `'2026-2'` (7–12); `String? validarSemestre(String? valor)` → `null` si es válido, `'Escribe el semestre.'` si está vacío o solo espacios, `'El semestre no puede pasar de 20 caracteres.'` si excede.

- [ ] **Step 1: Pruebas que fallan:** `semestreActual(DateTime(2026,1,1))`→`'2026-1'`, `(2026,6,30)`→`'2026-1'`, `(2026,7,1)`→`'2026-2'`, `(2026,12,31)`→`'2026-2'`, `(2027,2,10)`→`'2027-1'`; `validarSemestre(null)`, `('')`, `('   ')`→mensaje de vacío; `('2026-2')`→null; `('X'*20)`→null; `('X'*21)`→mensaje de largo; `(' 2026-2 ')`→null.
- [ ] **Step 2:** `flutter test test/utils/semestres_test.dart` → FALLA.
- [ ] **Step 3:** Implementar (el largo se mide con `trim()`).
- [ ] **Step 4:** misma orden → PASA.
- [ ] **Step 5: Commit** `feat: utilidades de semestre`

---

### Task 2: Modelo, repositorio v3 y provider

**Files:** Modify `lib/models/materia.dart`, `lib/data/materias_repository.dart`, `lib/data/materias_repository_sqflite.dart`, `lib/providers/materias_provider.dart`, `test/support/repositorio_memoria.dart`, `test/support/abrir_app.dart` y las pruebas que llamen a `crearMateria`; Test `test/data/materias_repository_sqflite_test.dart`, `test/providers/materias_provider_test.dart`

**Interfaces:**
- Consumes: `semestreActual`, `validarSemestre` (Tarea 1).
- Produces:
  - `Materia` gana `final String semestre` (opcional en el constructor `const`, por defecto `''` para las materias de demostración).
  - `MateriasRepository.crearMateria({required nombre, required descripcion, required colorIndice, required iconoClave, required String semestre})` y `actualizarMateria({required id, ..., required String semestre})`.
  - SQLite versión 3: `CREATE TABLE materias` incluye `semestre TEXT NOT NULL`; `onUpgrade`: `if (viejo < 2) crearTablasV2; if (viejo < 3) { ALTER TABLE materias ADD COLUMN semestre TEXT NOT NULL DEFAULT ''; UPDATE materias SET semestre = <año local de creada> || '-' || (CASE WHEN <mes local de creada> <= 6 THEN '1' ELSE '2' END) }` usando `strftime(..., creada / 1000, 'unixepoch', 'localtime')`.
  - `MateriasProvider.crearMateria({..., String? semestre})` y `actualizarMateria({..., String? semestre})`: `semestre` nulo → `semestreActual(DateTime.now())` al crear y se conserva el actual al actualizar; se valida con `validarSemestre` (lanza `ArgumentError`) y se recorta. Getter `List<String> get semestres`: semestres distintos en el orden en que aparecen en `materias` (la más reciente primero).
  - `RepositorioMemoria` y `sembrarMateria(repositorio, nombre, {colorIndice, iconoClave, String semestre = '2026-2'})` aceptan el semestre.

- [ ] **Step 1: Pruebas que fallan:**
  - SQLite: crear con `semestre: '2026-2'` y leerlo; actualizar el semestre; `migración desde v2` (archivo con esquema v2 sin la columna, dos materias con `creada` = `DateTime(2026,3,10,12)` y `DateTime(2026,10,10,12)` en ms) → tras abrir: `'2026-1'` y `'2026-2'`, y sus apuntes/sesiones siguen; la prueba existente de v1 se actualiza para usar un `creada` realista (`DateTime(2026,3,10,12)`) y comprobar `'2026-1'` (Review Focus 1).
  - Provider: sin `semestre` se usa `semestreActual(DateTime.now())`; con `'2025-1'` se guarda; `'   '` lanza `ArgumentError` y no guarda; `semestres` con materias de `2026-2`, `2026-1`, `2026-2` (creadas en ese orden de más vieja a más nueva) devuelve `['2026-2','2026-1']` según recencia; `actualizarMateria` sin `semestre` conserva el que tenía.
- [ ] **Step 2:** `flutter test test/data test/providers` → FALLA.
- [ ] **Step 3:** Implementar y arreglar las llamadas existentes a `crearMateria` en pruebas.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: semestre en materias (SQLite v3 con migración)`

---

### Task 3: Campo de semestre en el formulario

**Files:** Modify `lib/widgets/formulario_materia.dart`; Test `test/semestres_formulario_test.dart`

**Interfaces:**
- Consumes: `MateriasProvider.semestres`, `semestreActual`, `validarSemestre`.
- Produces: `Future<String?> mostrarFormularioMateria(BuildContext context, {Materia? materia, String? semestreInicial})` devuelve el semestre guardado o `null` si se cancela. Campo `Key('campo-semestre')` (etiqueta "Semestre", pista `Ej. 2026-2`), valor inicial `materia?.semestre ?? semestreInicial ?? semestreActual(ahora)`; sugerencias: `ActionChip` con `Key('sugerencia-semestre-<texto>')` para cada semestre existente más el actual del calendario (sin repetir); tocar uno rellena el campo. Se pasa `semestre` al provider al guardar.

- [ ] **Step 1: Pruebas que fallan** (app con `RepositorioMemoria`): el formulario abre con `semestreActual(DateTime.now())` si no hay semestre inicial; abre con el semestre de la materia al editar; tocar una sugerencia rellena el campo; semestre vacío → `'Escribe el semestre.'` y no se guarda (Review Focus 5); 21 caracteres → mensaje de largo; guardar con `'2025-1'` crea la materia con ese semestre.
- [ ] **Step 2:** `flutter test test/semestres_formulario_test.dart` → FALLA.
- [ ] **Step 3:** Implementar. El campo va después de la descripción.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: campo de semestre en el formulario de materia`

---

### Task 4: Selector de semestre en Inicio

**Files:** Modify `lib/screens/inicio_screen.dart`, `lib/widgets/materia_card.dart`; Test `test/semestres_test.dart`

**Interfaces:**
- Consumes: `MateriasProvider.semestres`, `mostrarFormularioMateria` (devuelve el semestre guardado).
- Comportamiento: `InicioScreen` guarda la elección en su estado (`null` = por defecto el más reciente; un valor especial para "Todos"). Semestre activo: la elección si sigue existiendo, "Todos" si se eligió, y si no el primero de `semestres` (Review Focus 3). Entre el buscador y "Mis Materias" aparece un botón-píldora `Key('selector-semestre')` con el semestre activo (o `Todos`) y una flecha; abre un menú con un elemento `Key('semestre-<texto>')` por semestre y `Key('semestre-todos')`. La lista se filtra por el semestre activo, **salvo** cuando hay texto de búsqueda: entonces se busca en todos (Review Focus 4). "Mis Materias (N)" cuenta lo mostrado. Con "Todos" o buscando, cada `MateriaCard` muestra el semestre (parámetro opcional `String? semestre` que se antepone al subtítulo: `2026-1 · 2 apuntes`). Al crear una materia con el botón "Nueva materia" o el de la primera materia, el formulario recibe `semestreInicial` = semestre activo (o el actual del calendario si es "Todos" o no hay) y, al volver con un semestre, la vista cambia a ese semestre (Review Focus 2).
- [ ] **Step 1: Pruebas que fallan** (sembrar materias con `sembrarMateria(..., semestre:)`; la más reciente es la última sembrada):
  - con 'Vieja' en `2026-1` y 'Nueva' en `2026-2` (sembrada después): al abrir se ve solo 'Nueva', el selector dice `2026-2`, y `Mis Materias (1)`.
  - elegir `2026-1` en el selector muestra solo 'Vieja'; elegir `Todos` muestra las dos con su semestre en la tarjeta (`2026-1 · Sin apuntes`).
  - buscar `vieja` estando en `2026-2` encuentra 'Vieja'; al limpiar vuelve a `2026-2`.
  - crear una materia con semestre `2025-2` (editando el campo del formulario) la deja visible: aparece su nombre y el selector dice `2025-2`.
  - borrar la última materia de `2026-2` (la vista pasa sola a `2026-1`, sin error ni pantalla vacía).
  - editar una materia de `2026-2` cambiándola a `2026-1` y quedándose sin materias en `2026-2`: la vista vuelve a un semestre con materias.
  - con una sola materia, el selector muestra su semestre.
  - las pruebas existentes de Inicio (vacío, crear, buscador, racha) siguen pasando.
- [ ] **Step 2:** `flutter test test/semestres_test.dart` → FALLA.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `flutter test` completo y `flutter analyze` → PASAN.
- [ ] **Step 5: Commit** `feat: selector de semestre en Inicio`

---

### Task 5: Documentación y verificación

**Files:** Modify `README.md`

- [ ] **Step 1:** `flutter analyze` limpio; `flutter test` todo verde (anotar el total).
- [ ] **Step 2:** `flutter build apk --debug` compila.
- [ ] **Step 3:** README: estado (materias por semestre), tabla de pantallas (Inicio con selector), tecnologías/estructura si cambió algo, y esquema v3.
- [ ] **Step 4: Commit** `docs: README de materias por semestre`. **No hacer push.**
