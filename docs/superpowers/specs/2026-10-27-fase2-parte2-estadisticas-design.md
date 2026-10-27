# Fase 2 · Parte 2: Pomodoro, quiz y estadísticas con datos reales

Fecha: 2026-10-27 · Proyecto: StudyBuddy IA (Flutter, Android)

Edwin pidió "hazlo directamente" (sin preguntas). **Todo lo que sigue es decisión de Claude** salvo lo que
viene del alcance que Edwin ya aprobó en la Parte 1 (Pomodoro, Stats y Quiz con datos reales). Se revisa
al final del trabajo, en la lista de decisiones.

## Intención

La Parte 1 dejó materias y apuntes reales. Esta parte hace que lo que Edwin *hace* en la app (estudiar con el
Pomodoro, resolver un quiz) quede guardado y se vea en Stats e Inicio, en vez de números de demostración.

## Qué se construye

1. **Sesiones de enfoque guardadas.** Cuando un bloque de *Enfoque* del Pomodoro **termina** (llega a 00:00), se
   guarda la sesión: materia (puede no haber), hora de inicio y duración (25 min = 1500 s). Saltar, reiniciar o
   salir antes de terminar **no** guarda nada.
2. **Pomodoro por hora de fin.** El temporizador calcula el tiempo restante contra una hora de fin, no contando
   ticks, y se recalcula al volver a la app. Así el bloque termina y se guarda aunque el celular bloquee la pantalla.
3. **Intentos de quiz guardados.** Al terminar un quiz (última pregunta) se guarda: materia, aciertos, total y fecha.
   Hoy solo las 3 materias de demostración tienen preguntas (las reales las genera la IA en la Fase 3).
4. **Stats real** (sustituye los datos de demostración):
   - Tarjetas: **Tiempo** (total de todas las sesiones, "2 h 30 min"), **Racha** (días) y **Quizzes** (intentos).
   - **Gráfica semanal:** horas por día de la semana actual (lunes a domingo), con "Total de X horas esta semana"
     y "Pico: Jue (2.5 h)" (el aviso de pico se oculta si no hay horas).
   - **Estudio por materia:** una tarjeta por cada materia **real** con su tiempo estudiado y, si hay, su mejor
     puntaje de quiz ("Mejor quiz: 4/5"). Sin materias reales, un mensaje que invita a crear una.
   - Con cero datos: tarjetas en 0 y un aviso "Completa un bloque de enfoque del Pomodoro para ver tus estadísticas".
5. **Racha real en Inicio.** Vuelve la tarjeta "¡Racha de N días activa! 🔥" (singular con 1 día), solo si la racha es ≥ 1.

## Definiciones

- **Racha:** días consecutivos (calendario local) con al menos una sesión de enfoque guardada. Si hoy todavía no
  hay sesión pero ayer sí, la racha sigue viva y cuenta hasta ayer. Los quizzes no cuentan para la racha.
- **Semana:** lunes a domingo, de la fecha de hoy.
- **Tiempo por materia:** suma de las sesiones con ese `materia_id`.

## Datos (SQLite versión 2, con migración)

La base pasa de la versión 1 a la 2 con `onUpgrade` **sin perder** materias ni apuntes ya guardados:
- `sesiones_enfoque(id TEXT PK, materia_id TEXT NULL, inicio INTEGER NOT NULL, duracion_segundos INTEGER NOT NULL)`
- `intentos_quiz(id TEXT PK, materia_id TEXT NOT NULL, aciertos INTEGER NOT NULL, total INTEGER NOT NULL, fecha INTEGER NOT NULL)`
- Sin llaves foráneas: las materias de demostración no existen en la tabla `materias`. Por eso `borrarMateria`
  borra también, en la misma transacción, las filas de ambas tablas con ese `materia_id`.
- Fechas en milisegundos desde la época.

## Metas, no metas, anti-metas

**Metas:** completar un bloque de enfoque deja un registro y Stats/Racha lo reflejan; los datos sobreviven a cerrar la
app; actualizar desde la versión 1 conserva las materias y apuntes.

**No metas:** el **Plan** (sesiones de hoy y próximo parcial) sigue con datos de demostración; no hay IA; no hay
notificaciones ni sonido al terminar; no se guarda tiempo de bloques incompletos; no hay historial detallado ni exportar.

**Anti-metas:** perder datos al migrar; que los números de Stats mezclen datos inventados con reales; que el
Pomodoro no guarde la sesión por bloquear la pantalla.

## Decisiones de Claude a revisar

- Solo cuentan los bloques de enfoque **completados** (más simple y honesto que repartir minutos parciales).
- **El "% dominado" no vuelve en esta parte:** necesita quizzes con preguntas reales, que llegan con la IA (Fase 3).
  La barra sigue oculta en las materias reales; Stats muestra tiempo estudiado en su lugar. (Cambia lo que dijo la
  Parte 1: "vuelve en la Parte 2".)
- Las sesiones/intentos de materias de demostración (por ejemplo, un Pomodoro abierto desde Plan) **sí cuentan** en los
  totales, pero **no** aparecen en "Estudio por materia" (solo se listan materias reales).
- Título de la sección de Stats: "Estudio por Materia" (antes "Progreso por Materia").
- Racha en Inicio oculta con 0 días (no se muestra una tarjeta que "regañe").

## Qué se deja al que construye

Nombres de tablas/columnas exactos, estructura de proveedores (se sugiere un `EstadisticasProvider` aparte, que se
recarga cuando cambian las materias), formato exacto de la duración, y cómo inyectar el reloj en el Pomodoro para
probarlo. Pruebas: actualizar las existentes que cambien de texto y agregar las de los nuevos flujos; el reloj del
Pomodoro debe poder simularse.
