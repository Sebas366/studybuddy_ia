# StudyBuddy IA

App móvil de estudio asistido por IA, desarrollada en Flutter como proyecto final de **Desarrollo de Aplicaciones para Dispositivos Móviles** (Universidad de Nariño, 2026-2).

> ## 🚧 Estado del proyecto
>
> - **Fase 1 (completa): mockups.** Interfaz completa y navegable con datos de demostración, sin lógica real ni IA.
> - **Fase 2, parte 1 (completa): materias y apuntes reales con persistencia local.** Puedes crear, editar y borrar tus propias materias y apuntes, y siguen ahí al cerrar y reabrir la app (base de datos SQLite en el dispositivo).
> - **Todavía con datos de demostración:** las pestañas **Plan** y **Stats** y las 3 materias de ejemplo que usan. El **Pomodoro** funciona pero no guarda sesiones.
> - **Todavía sin IA (Fase 3):** el resumen, las ideas clave, el quiz y el tutor muestran el aviso "Disponible en la Fase 3" en tus materias reales. No hay llamadas a ningún modelo de IA ni backend.
>
> Próximas partes: Pomodoro, estadísticas y quiz con datos reales (Fase 2, parte 2) y la integración con IA (Fase 3).

## Pantallas incluidas

| Sección | Pantalla | Descripción |
|---|---|---|
| Navegación principal | `main_shell` | Barra inferior con 4 pestañas: Inicio, Plan, Stats y Perfil |
| Inicio | `inicio_screen` | Saludo, estado vacío con botón para crear la primera materia, buscador y lista de tus materias (mantén pulsada una tarjeta para editar o borrar) |
| Materia | `detalle_materia_screen` | Herramientas de estudio (Resumir, Quiz IA, Tutor IA, Pomodoro, Escanear), lista de apuntes y menú para editar o borrar la materia |
| Apuntes | `formulario_apunte_screen` / `apunte_screen` | Crear, editar y leer un apunte real; el espacio de la IA muestra el aviso de la Fase 3 |
| IA (demostración) | `resumen_ia_screen`, `quiz_screen`, `resultados_quiz_screen`, `chat_tutor_screen` | Pantallas simuladas que siguen disponibles en las materias de ejemplo |
| Productividad | `pomodoro_screen` | Temporizador Pomodoro: enfoque, descanso corto y descanso largo |
| Plan | `plan_estudio_screen` | Próximo parcial y sesiones de estudio del día (demostración) |
| Stats | `estadisticas_screen` | Horas de estudio semanales y progreso por materia (demostración) |
| Perfil | `perfil_screen` | Datos del usuario y alternancia de modo claro/oscuro |

## Tecnologías

- [Flutter](https://flutter.dev/) (Dart SDK `^3.13.2`) con Material 3
- [`provider`](https://pub.dev/packages/provider) para el estado
- [`sqflite`](https://pub.dev/packages/sqflite) para guardar materias y apuntes en el dispositivo
- [`google_fonts`](https://pub.dev/packages/google_fonts) (tipografía Poppins)
- Tema claro y oscuro intercambiable en tiempo real

## Estructura del proyecto

```
lib/
├── main.dart          # Punto de entrada: abre la base de datos y monta la app
├── data/              # Repositorio SQLite, catálogo de colores/iconos y datos de demostración
├── models/            # Materia, Apunte, Pregunta, MensajeChat, SesionEstudio
├── providers/         # MateriasProvider (estado de materias y apuntes)
├── screens/           # Pantallas de la app
├── theme/             # Colores y temas claro/oscuro
├── utils/             # Formato de fechas y validaciones
└── widgets/           # Componentes reutilizables
test/                  # Pruebas de widgets, del provider y del repositorio SQLite
docs/superpowers/      # Diseño y plan de implementación de la Fase 2, parte 1
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

## Autor

Edwin Pupiales: Ingeniería, Universidad de Nariño.
