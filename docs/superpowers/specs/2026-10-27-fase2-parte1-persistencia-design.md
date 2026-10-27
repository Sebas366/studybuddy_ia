# Fase 2 · Parte 1: materias y apuntes reales con persistencia local

Fecha: 2026-10-27 · Proyecto: StudyBuddy IA (Flutter, Android)

Convención de este documento: lo que dijo Edwin está escrito sin marca. Lo que
decidió Claude sin que Edwin lo pidiera lleva **[Decisión de Claude]**.

## Intención y por qué

La Fase 1 dejó la app como mockups: todo sale de `lib/data/datos_demo.dart` y se
pierde al cerrar. La Fase 2 convierte la app en algo que Edwin pueda usar en
clase con sus materias reales, **sin IA todavía**. Esta Parte 1 cubre solo
materias y apuntes. La Parte 2 (aparte, no se diseña aquí) conectará Pomodoro,
Stats y Quiz con datos reales. La Fase 3 conectará la IA real.

Se hace primero porque la IA necesita apuntes reales sobre los cuales trabajar.

## Qué se construye

1. **Primera vez:** Inicio abre vacío, sin materias. Muestra un estado vacío
   con el mensaje "Aún no tienes materias" y un botón "Crear mi primera materia".
   Va debajo del encabezado con el saludo "¡Hola, Edwin!", como en el mockup
   aprobado. La tarjeta "¡Racha de 7 días activa!" se oculta: es un dato de
   demostración y la racha real llega con la Parte 2.
2. **Crear materia:** formulario con nombre (obligatorio), descripción
   (opcional), color (4 a 6 degradados de una lista corta) e icono (5 a 8 de una
   lista corta). Hoy ya existe una hoja modal "Nueva Materia" en
   `inicio_screen.dart`; se transforma, no se duplica.
3. **Crear apunte** dentro de una materia: título y texto. La fecha se pone
   sola con el día de hoy.
4. **Editar y borrar** materias y apuntes. Antes de borrar sale una
   confirmación. Borrar una materia borra todos sus apuntes.
5. **Persistencia:** todo sobrevive al cerrar y reabrir la app.
6. **Buscador de Inicio:** filtra las materias reales.
7. **Campos de IA vacíos:** un apunte real no tiene ideas clave ni resúmenes.
   En esos lugares se ve un aviso del estilo "✨ Resumen, ideas clave y quiz con
   IA: disponible en la Fase 3".
8. **Resumir, Quiz IA y Tutor IA** en una materia real muestran ese mismo aviso
   (en vez de abrir su pantalla simulada).
9. **Plan y Stats** no se tocan: siguen con su contenido de demostración.

Mockups aprobados por Edwin (3 pantallas): Inicio vacío, Crear materia (nombre,
descripción, color, icono, botón Guardar) y Materia con un apunte real (lista de
apuntes, botón "+ Nuevo", aviso de IA, indicación de mantener pulsado para
editar o borrar).

## Metas, no metas, anti-metas

**Metas**
- Edwin crea una materia y un apunte, cierra la app, la abre, y siguen ahí.
- Ninguna pantalla se rompe con cero materias o con una materia sin apuntes.

**No metas (no hacer en esta parte)**
- Nada de IA, ni llamadas a APIs, ni claves.
- No persistir sesiones de Pomodoro, resultados de quiz ni estadísticas (Parte 2).
- No hay cuentas, sincronización en la nube, exportar ni respaldo.
- No se reescribe el diseño visual: se reutilizan las pantallas y widgets que ya
  existen.

**Anti-metas (fallaría aunque "funcione")**
- Que se pierdan datos del usuario al reiniciar.
- Que queden datos de demostración mezclados en Inicio como si fueran reales.
- Que el repo público termine con algo sensible (no hay claves en esta parte;
  mantenerlo así).

## Restricciones

- Flutter, probado en **Android** (Edwin no usará escritorio Linux).
- Textos de interfaz, nombres de clases y comentarios en **español**, con
  comentarios `///` como en el resto del código (ver `lib/models/materia.dart`).
- El repo es público en GitHub: https://github.com/Sebas366/studybuddy_ia
- Mantener el modo claro y oscuro funcionando.

## Decisiones técnicas

- **Estado: `Provider`.** Reemplaza las listas locales de las pantallas.
  Propuesto por Claude y aprobado por Edwin ("Todo bien").
- **Base de datos: `sqflite`.** Mismo origen: propuesto por Claude y aprobado
  por Edwin. Se probará solo en Android.
- Los datos de `datos_demo.dart` se quedan en el archivo porque Plan, Stats y el
  chat los siguen usando en esta parte.

## Decisiones de Claude (a revisar por Edwin)

- **[Decisión de Claude] Subtítulo de materia.** El modal actual pide "Subtítulo
  o código"; el mockup aprobado no lo tiene. Se quita del formulario y el
  subtítulo que ven la tarjeta y la cabecera se calcula solo, por ejemplo
  "3 apuntes" (o "Sin apuntes").
- **[Decisión de Claude] Progreso.** No hay manera real de calcularlo hasta la
  Parte 2, así que en las materias reales se oculta la barra de progreso y el
  texto "X% dominado" (tarjeta de Inicio y cabecera del detalle). Una barra
  fija en 0 % parecería rota. Vuelve en la Parte 2.
- **[Decisión de Claude] Plan y Stats siguen leyendo `DatosDemo.materias`.** Eso
  significa que Stats ("Progreso por Materia") y Plan (parcial) mostrarán las 3
  materias de demostración aunque Inicio esté vacío. Es una inconsistencia
  temporal aceptada hasta la Parte 2; a cambio no se tocan esas pantallas.
- **[Decisión de Claude] Dónde se edita y borra una materia.** Mantener pulsada
  la tarjeta en Inicio, y un menú en la cabecera del detalle. Los apuntes, con
  mantener pulsado (como en el mockup).
- **[Decisión de Claude] Qué se ve al tocar un apunte real.** La pantalla de
  resumen (`resumen_ia_screen.dart`) muestra el título, la fecha y el texto del
  apunte, y el aviso de IA donde irían ideas clave y resúmenes.
- **[Decisión de Claude] El buscador** filtra por nombre, descripción y títulos
  de apuntes.
- **[Decisión de Claude] Pomodoro y Escanear** no cambian: Pomodoro sigue
  funcionando por materia (sin guardar nada) y Escanear sigue mostrando su
  SnackBar de "próximamente".
- **[Decisión de Claude] Materias de demostración vs. reales.** Plan (botón del
  "Próximo Parcial") y Stats todavía pueden abrir el detalle de una materia de
  `DatosDemo`. Esas materias se distinguen de las reales con una marca en el
  modelo (por ejemplo `esDemo`), conservan sus pantallas simuladas de Resumir,
  Quiz y Tutor, y no muestran menú de editar ni borrar (no existen en la base
  de datos). Pomodoro acepta los dos tipos. No se cambia Plan para esconder esto.
- **[Decisión de Claude] Fechas y orden de los apuntes.** Más nuevo primero. Se
  guarda la fecha de creación y también una de modificación; la lista muestra la
  de creación y no se puede editar a mano.
- **[Decisión de Claude] Validación.** Materia: nombre obligatorio (sin espacios
  sobrantes), se permiten nombres repetidos. Apunte: título y texto
  obligatorios. Sin límites de longitud más allá de lo razonable para que la
  interfaz no se rompa (por ejemplo, nombre de materia de hasta 60 caracteres).
- **[Decisión de Claude] Esquema.** La base arranca en la versión 1 con solo los
  campos de esta parte; no se agregan columnas "por si acaso" para la IA. Las
  partes siguientes suben la versión y migran con `onUpgrade`, así que no se
  pierden los datos que Edwin ya haya guardado en su celular.
- **[Decisión de Claude] Pruebas de la base de datos.** Se permite agregar
  `sqflite_common_ffi` como dependencia solo de desarrollo para probar el SQL
  real en la computadora; la app que va al celular no lo incluye.

## Qué se deja al que construye

- Esquema de tablas, migraciones y cómo se guardan color e icono (un
  `IconData` o un `Color` no se pueden guardar tal cual; hay que guardar una
  clave o un entero).
- Formato de guardado de la fecha y cómo se muestra (hoy el modelo usa un texto
  como "18 Sep 2026").
- Cómo adaptar los modelos `Materia` y `Apunte` (hoy son `const` con campos de IA
  obligatorios) sin romper las pantallas que quedan con datos de demostración.
- La lista concreta de colores e iconos.
- Estructura de carpetas para repositorio y proveedores.
- **Pruebas.** `test/widget_test.dart` asume las 3 materias de demostración en
  Inicio y, por tanto, fallará con el nuevo comportamiento; hay que actualizarlo
  y añadir pruebas del nuevo flujo. Cómo aislar la base de datos en las pruebas
  (por ejemplo, un repositorio en memoria) lo decide quien construye. No se
  ejecutaron las pruebas existentes antes de escribir esto.
