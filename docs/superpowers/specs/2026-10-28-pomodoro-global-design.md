# Pomodoro global con aviso al terminar

Fecha: 2026-10-28 · Proyecto: StudyBuddy IA (Flutter, Android)

Edwin aprobó el planteamiento en el chat ("hazlo así con los tres") y pidió: vibración **constante** en el aviso
(no una sola vez) y tiempos **cortos para la demostración** (15 s de estudio, 5 s de descanso o similares).
Lo que decidió Claude sin que Edwin lo pidiera lleva **[Decisión de Claude]**.

## Problema

El temporizador vive dentro de la pantalla del Pomodoro: al salir de ella se cancela y el bloque se pierde. Además
no hay ningún aviso al terminar, y si Android cierra la app el bloque en curso se pierde.

## Qué se construye

1. **Temporizador global.** El estado del Pomodoro (modo, tiempo, si corre, ciclos, materia) vive en un
   `PomodoroProvider` a nivel de toda la app. La pantalla solo lo muestra. Salir y volver deja el tiempo corriendo.
2. **Aviso al terminar.** Al iniciar un bloque se programa una alarma del sistema para su hora de fin. A esa hora
   aparece una notificación con **sonido de alarma y vibración repetida** (FLAG_INSISTENT) hasta que se abra la app,
   se descarte, o pasen 60 s. Funciona con la app cerrada o la pantalla bloqueada. Avisa el fin del enfoque
   ("¡Bloque de enfoque terminado!") y el fin del descanso.
3. **Bloque en curso guardado.** El estado del bloque se guarda en SQLite. Al abrir la app (o volver a ella) se
   restaura: si la hora de fin ya pasó, se completa y se registra la sesión; si no, sigue corriendo.
4. **Modo demostración.** Interruptor en Perfil: enfoque **15 s**, descanso corto **5 s**, descanso largo **10 s**
   (normal: 25 min, 5 min, 15 min). Se guarda como ajuste.
5. **Pastilla "🍅 Pomodoro en curso · mm:ss"** en Inicio mientras hay un bloque activo (corriendo o en pausa a
   medias); al tocarla abre la pantalla del Pomodoro.

## Datos (SQLite versión 4, con migración)

- `pomodoro_en_curso(id INTEGER PRIMARY KEY CHECK(id = 1), modo TEXT, corriendo INTEGER, fin INTEGER NULL,
  segundos_restantes INTEGER, segundos_totales INTEGER, ciclos INTEGER, materia_id TEXT NULL, materia_nombre TEXT NULL)`
- `ajustes(clave TEXT PRIMARY KEY, valor TEXT NOT NULL)` (clave `modo_demo`: `1` o `0`).
- La migración desde v3 solo crea las dos tablas y conserva todo lo demás.

## Reglas

- **[Decisión de Claude]** Modo demostración **activado por defecto** (Edwin lo quiere para presentar hoy).
  Se apaga en Perfil. Cambiar el modo no altera un bloque ya iniciado; aplica al siguiente.
- **[Decisión de Claude]** Un solo Pomodoro a la vez. Si se abre el de otra materia con un bloque activo, se
  muestra el que está en curso con un aviso de que ya hay uno de otra materia.
- **[Decisión de Claude]** Solo cuentan para estadísticas los bloques de enfoque completados (igual que antes).
  Con el modo demostración, las sesiones de 15 s también cuentan; por eso las duraciones menores a un minuto se
  muestran en segundos ("15 s") en Stats.
- **[Decisión de Claude]** Al terminar un bloque el modo avanza solo (enfoque → descanso corto, cada 4 enfoques
  descanso largo) pero **no arranca solo**: hay que iniciarlo (como antes).
- **[Decisión de Claude]** Pausar a medias también se guarda; reiniciar, saltar o cambiar de modo borran el estado.
- **[Decisión de Claude]** Se pide el permiso de notificaciones (Android 13+) la primera vez que se inicia un
  bloque. Si se niega, el Pomodoro funciona igual, sin aviso.
- **[Decisión de Claude]** Alarma exacta con `USE_EXACT_ALARM` (sin pedir ajustes especiales); si el sistema la
  rechaza, se usa una alarma aproximada.
- **[Decisión de Claude]** Al volver a la app se descarta la notificación (para detener la vibración) y, si hay un
  bloque corriendo, se reprograma su alarma.

## No metas

Arranque automático del siguiente bloque, notificación persistente con cuenta regresiva, sonidos personalizados,
múltiples Pomodoros, y ajustar las duraciones a gusto.

## Limitaciones conocidas

Algunos celulares (Vivo, Xiaomi y similares) retrasan o bloquean alarmas si la app tiene ahorro de batería; hay que
dejarla "sin restricciones". Una sesión cuya materia se borra mientras corre se guarda con su `materia_id` (aparece
en los totales, sin tarjeta propia).
