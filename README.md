# StudyBuddy IA

App móvil de estudio asistido por IA, desarrollada en Flutter como proyecto final de **Desarrollo de Aplicaciones para Dispositivos Móviles** (Universidad de Nariño, 2026-2).

> ## 🚧 Estado del proyecto
>
> - **Fase 1 (completa): mockups.** Interfaz completa y navegable con datos de demostración, sin lógica real ni IA.
> - **Fase 2, parte 1 (completa): materias y apuntes reales con persistencia local.** Puedes crear, editar y borrar tus propias materias y apuntes, y siguen ahí al cerrar y reabrir la app (base de datos SQLite en el dispositivo).
> - **Fase 2, parte 2 (completa): Pomodoro, quiz y estadísticas reales.** Cada bloque de enfoque que termina se guarda como sesión de estudio (el temporizador sigue la hora real: si la pantalla se apaga, el bloque se completa y se guarda al volver a la app; si Android cierra la app mientras tanto, ese bloque se pierde), cada quiz terminado guarda su resultado, y **Stats** e **Inicio** (racha) muestran tus números reales. Cada sesión cuenta para el día en que **termina** el bloque.
> - **Todavía con datos de demostración:** la pestaña **Plan** (sesiones de hoy y próximo parcial) y las 3 materias de ejemplo.
> - **Todavía sin IA (Fase 3):** el resumen, las ideas clave, el quiz y el tutor muestran el aviso "Disponible en la Fase 3" en tus materias reales; por eso el quiz solo se puede jugar en las materias de ejemplo y el "% dominado" sigue oculto. No hay llamadas a ningún modelo de IA ni backend.
>
> Próxima parte: integración con IA (Fase 3).

## Pantallas incluidas

| Sección | Pantalla | Descripción |
|---|---|---|
| Navegación principal | `main_shell` | Barra inferior con 4 pestañas: Inicio, Plan, Stats y Perfil |
| Inicio | `inicio_screen` | Saludo, estado vacío con botón para crear la primera materia, buscador y lista de tus materias (mantén pulsada una tarjeta para editar o borrar) |
| Materia | `detalle_materia_screen` | Herramientas de estudio (Resumir, Quiz IA, Tutor IA, Pomodoro, Escanear), lista de apuntes y menú para editar o borrar la materia |
| Apuntes | `formulario_apunte_screen` / `apunte_screen` | Crear, editar y leer un apunte real; el espacio de la IA muestra el aviso de la Fase 3 |
| IA (demostración) | `resumen_ia_screen`, `quiz_screen`, `resultados_quiz_screen`, `chat_tutor_screen` | Pantallas simuladas que siguen disponibles en las materias de ejemplo |
| Productividad | `pomodoro_screen` | Temporizador Pomodoro (enfoque, descanso corto y largo) por hora real; guarda cada bloque de enfoque completado |
| Plan | `plan_estudio_screen` | Próximo parcial y sesiones de estudio del día (aún demostración) |
| Stats | `estadisticas_screen` | Tiempo total, racha, quizzes, horas de la semana y estudio por materia (datos reales) |
| Perfil | `perfil_screen` | Datos del usuario y alternancia de modo claro/oscuro |

## Tecnologías

- [Flutter](https://flutter.dev/) (Dart SDK `^3.13.2`) con Material 3
- [`provider`](https://pub.dev/packages/provider) para el estado
- [`sqflite`](https://pub.dev/packages/sqflite) para guardar materias, apuntes, sesiones de enfoque e intentos de quiz en el dispositivo
- [`google_fonts`](https://pub.dev/packages/google_fonts) (tipografía Poppins)
- Tema claro y oscuro intercambiable en tiempo real

## Estructura del proyecto

```
lib/
├── main.dart          # Punto de entrada: abre la base de datos y monta la app
├── data/              # Repositorio SQLite (esquema v2), catálogo de colores/iconos y datos de demostración
├── models/            # Materia, Apunte, Pregunta, MensajeChat, SesionEstudio
├── providers/         # MateriasProvider y EstadisticasProvider
├── screens/           # Pantallas de la app
├── theme/             # Colores y temas claro/oscuro
├── utils/             # Fechas, validaciones y cálculos de estadísticas (racha, horas por día)
└── widgets/           # Componentes reutilizables
test/                  # Pruebas de widgets, del provider y del repositorio SQLite
docs/superpowers/      # Diseño y plan de implementación de la Fase 2 (partes 1 y 2)
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
