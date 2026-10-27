# StudyBuddy IA

App móvil de estudio asistido por IA, desarrollada en Flutter como proyecto final de **Desarrollo de Aplicaciones para Dispositivos Móviles** (Universidad de Nariño, 2026-2).

> ## 🚧 Estado del proyecto
>
> - **Fase 1 (completa): mockups.** Interfaz completa y navegable con datos de demostración, sin lógica real ni IA.
> - **Fase 2, parte 1 (completa): materias y apuntes reales con persistencia local.** Puedes crear, editar y borrar tus propias materias y apuntes, y siguen ahí al cerrar y reabrir la app (base de datos SQLite en el dispositivo).
> - **Fase 2, parte 2 (completa): Pomodoro, quiz y estadísticas reales.** Cada bloque de enfoque que termina se guarda como sesión de estudio (el temporizador sigue la hora real), cada quiz terminado guarda su resultado, y **Stats** e **Inicio** (racha) muestran tus números reales. Cada sesión cuenta para el día en que **termina** el bloque.
> - **Materias por semestre:** cada materia tiene su semestre (ej. `2026-2`) y Inicio muestra uno a la vez, con un selector y la opción "Todos". El buscador revisa todos los semestres.
> - **Pomodoro global con aviso:** el temporizador vive en toda la app, así que sigue corriendo si sales de su pantalla (una pastilla en Inicio te lleva de vuelta). Al terminar cada bloque suena una **notificación con vibración repetida** aunque la app esté cerrada o la pantalla bloqueada, y el bloque en curso se guarda para retomarlo si Android cierra la app. El **modo demostración** (Perfil, activado por defecto) usa bloques de 15 s de enfoque, 5 s de descanso y 10 s de descanso largo; al apagarlo vuelven los 25 / 5 / 15 minutos.
> - **Todavía con datos de demostración:** la pestaña **Plan** (sesiones de hoy y próximo parcial) y las 3 materias de ejemplo.
> - **Todavía sin IA (Fase 3):** el resumen, las ideas clave, el quiz y el tutor muestran el aviso "Disponible en la Fase 3" en tus materias reales; por eso el quiz solo se puede jugar en las materias de ejemplo y el "% dominado" sigue oculto. No hay llamadas a ningún modelo de IA ni backend.
>
> Próxima parte: integración con IA (Fase 3).

## Pantallas incluidas

| Sección | Pantalla | Descripción |
|---|---|---|
| Navegación principal | `main_shell` | Barra inferior con 4 pestañas: Inicio, Plan, Stats y Perfil |
| Inicio | `inicio_screen` | Saludo, racha, estado vacío con botón para crear la primera materia, buscador, selector de semestre y lista de tus materias (mantén pulsada una tarjeta para editar o borrar) |
| Materia | `detalle_materia_screen` | Herramientas de estudio (Resumir, Quiz IA, Tutor IA, Pomodoro, Escanear), lista de apuntes y menú para editar o borrar la materia |
| Apuntes | `formulario_apunte_screen` / `apunte_screen` | Crear, editar y leer un apunte real; el espacio de la IA muestra el aviso de la Fase 3 |
| IA (demostración) | `resumen_ia_screen`, `quiz_screen`, `resultados_quiz_screen`, `chat_tutor_screen` | Pantallas simuladas que siguen disponibles en las materias de ejemplo |
| Productividad | `pomodoro_screen` | Vista del temporizador Pomodoro global (enfoque, descanso corto y largo) con aviso al terminar; guarda cada bloque de enfoque completado |
| Plan | `plan_estudio_screen` | Próximo parcial y sesiones de estudio del día (aún demostración) |
| Stats | `estadisticas_screen` | Tiempo total, racha, quizzes, horas de la semana y estudio por materia (datos reales) |
| Perfil | `perfil_screen` | Datos del usuario, modo claro/oscuro y modo demostración del Pomodoro |

## Tecnologías

- [Flutter](https://flutter.dev/) (Dart SDK `^3.13.2`) con Material 3
- [`provider`](https://pub.dev/packages/provider) para el estado
- [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) para avisar al terminar cada bloque de Pomodoro
- [`sqflite`](https://pub.dev/packages/sqflite) para guardar materias, apuntes, sesiones de enfoque e intentos de quiz en el dispositivo
- [`google_fonts`](https://pub.dev/packages/google_fonts) (tipografía Poppins)
- Tema claro y oscuro intercambiable en tiempo real

## Estructura del proyecto

```
lib/
├── main.dart          # Punto de entrada: abre la base de datos y monta la app
├── data/              # Repositorio SQLite (esquema v4), catálogo de colores/iconos y datos de demostración
├── models/            # Materia, Apunte, Pregunta, MensajeChat, SesionEstudio
├── providers/         # MateriasProvider y EstadisticasProvider
├── screens/           # Pantallas de la app
├── services/          # Notificador del Pomodoro (alarma del sistema)
├── theme/             # Colores y temas claro/oscuro
├── utils/             # Fechas, validaciones, semestres y cálculos de estadísticas (racha, horas por día)
└── widgets/           # Componentes reutilizables
test/                  # Pruebas de widgets, del provider y del repositorio SQLite
docs/superpowers/      # Diseño y plan de implementación (Fase 2 y materias por semestre)
```

## Cómo ejecutarlo

Requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado. La app está pensada y probada para **Android**.

```bash
git clone <url-del-repositorio>
cd studybuddy_ia
flutter pub get
flutter run          # elige el dispositivo/emulador disponible
flutter test         # pruebas
```

Las pruebas del repositorio SQLite se ejecutan en el computador con `sqflite_common_ffi`; en Linux necesitan la biblioteca del sistema `libsqlite3` (en Arch: `sudo pacman -S sqlite`).

## Aviso del Pomodoro en el celular

La notificación usa una alarma exacta del sistema y pide el permiso de notificaciones la primera vez que inicias un bloque. Algunos celulares (Vivo, Xiaomi y similares) retrasan o bloquean alarmas si la app tiene ahorro de batería: si el aviso no suena a tiempo, en los ajustes del celular marca StudyBuddy IA como "sin restricciones" de batería.

## Autor

Edwin Pupiales: Ingeniería, Universidad de Nariño.
