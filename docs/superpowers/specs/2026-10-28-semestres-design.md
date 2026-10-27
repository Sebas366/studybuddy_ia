# Materias por semestre

Fecha: 2026-10-28 · Proyecto: StudyBuddy IA (Flutter, Android)

Edwin describió la idea en el chat y la aprobó ("Está perfecto, comienza de una"). Las decisiones que Claude
tomó sin que Edwin las pidiera llevan **[Decisión de Claude]**.

## Intención

Separar las materias por semestre para no ver materias viejas mezcladas con las del semestre en curso.

## Qué se construye

1. Cada materia tiene un **semestre**: texto libre con sugerencia `AAAA-N` (por ejemplo `2026-2`).
2. **Inicio** muestra un selector de semestre sobre la lista: cada semestre existente más "Todos".
   Arranca en el semestre de la materia más reciente (el semestre "actual" de uso).
3. El **formulario de materia** (crear y editar) tiene el campo semestre, ya relleno con el semestre que se está
   viendo, y botones de sugerencia con los semestres existentes y el semestre actual del calendario.
4. El **buscador** busca en **todos** los semestres, no solo en el seleccionado (decisión de Edwin).
5. Stats **no** se filtra por semestre (Edwin no pidió lo contrario): "Estudio por Materia" sigue mostrando todas.
6. Pomodoro, quiz, apuntes y Plan no cambian.

## Datos

- Base SQLite **versión 3**: columna `semestre TEXT NOT NULL` en `materias`.
- Migración: las materias existentes reciben el semestre derivado de su fecha de creación:
  enero–junio → `AAAA-1`, julio–diciembre → `AAAA-2`. Se conserva todo lo demás.

## Reglas

- **[Decisión de Claude]** Semestre actual del calendario: meses 1–6 → `AAAA-1`, meses 7–12 → `AAAA-2`.
- **[Decisión de Claude]** Orden de los semestres en el selector: por la materia más reciente de cada uno
  (no alfabético), así funciona también con nombres libres como "Verano". El semestre por defecto es el de la
  materia más reciente.
- **[Decisión de Claude]** Validación: el semestre es obligatorio, sin espacios sobrantes, máximo 20 caracteres.
- **[Decisión de Claude]** Si el semestre seleccionado se queda sin materias (se borró o movió la última), la vista
  vuelve al semestre más reciente. Por eso nunca hay un semestre vacío en el selector.
- **[Decisión de Claude]** Al crear una materia en otro semestre, la vista cambia a ese semestre para que se vea.
- **[Decisión de Claude]** La selección del semestre vive solo mientras la app está abierta (no se guarda).
- **[Decisión de Claude]** Con "Todos" o al buscar, cada tarjeta muestra su semestre junto al subtítulo.

## No metas

Tabla aparte de semestres, fechas de semestre, archivar semestres, filtrar Stats, y guardar la selección entre
sesiones.
