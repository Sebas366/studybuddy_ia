# StudyBuddy IA

App móvil de estudio asistido por IA, desarrollada en Flutter como proyecto final de **Desarrollo de Aplicaciones para Dispositivos Móviles** (Universidad de Nariño, 2026-2).

> ## 🚧 Fase 1: solo mockups
>
> Esta es la **primera fase del proyecto y contiene únicamente los mockups** de la app: la interfaz completa y navegable, pero **sin lógica real ni IA conectada**.
>
> - Todos los datos (materias, apuntes, preguntas, estadísticas) son **datos de demostración** definidos en [`lib/data/datos_demo.dart`](lib/data/datos_demo.dart).
> - El **Resumen IA**, el **Quiz IA** y el **Tutor IA** muestran contenido simulado; todavía no hay llamadas a ningún modelo de IA ni backend.
> - No hay persistencia: al cerrar la app se pierde cualquier cambio.
> - Funciones como *Escanear* apuntes están marcadas como "próximamente".
>
> Las siguientes fases agregarán la integración con IA, el almacenamiento de datos y la lógica real.

## Pantallas incluidas

| Sección | Pantalla | Descripción |
|---|---|---|
| Navegación principal | `main_shell` | Barra inferior con 4 pestañas: Inicio, Plan, Stats y Perfil |
| Inicio | `inicio_screen` | Saludo, racha de estudio, búsqueda y lista de materias |
| Materia | `detalle_materia_screen` | Herramientas de estudio: Resumir, Quiz IA, Tutor IA, Pomodoro y Escanear |
| IA | `resumen_ia_screen` | Mockup del resumen de apuntes generado por IA |
| IA | `quiz_screen` / `resultados_quiz_screen` | Quiz de preguntas y pantalla de resultados |
| IA | `chat_tutor_screen` | Chat con el tutor IA (burbujas e indicador "escribiendo") |
| Productividad | `pomodoro_screen` | Temporizador Pomodoro: enfoque, descanso corto y descanso largo |
| Plan | `plan_estudio_screen` | Próximo parcial y sesiones de estudio del día |
| Stats | `estadisticas_screen` | Horas de estudio semanales y progreso por materia |
| Perfil | `perfil_screen` | Datos del usuario y alternancia de modo claro/oscuro |

## Tecnologías

- [Flutter](https://flutter.dev/) (Dart SDK `^3.13.2`) con Material 3
- [`google_fonts`](https://pub.dev/packages/google_fonts) (tipografía Poppins)
- Tema claro y oscuro intercambiable en tiempo real

## Estructura del proyecto

```
lib/
├── main.dart          # Punto de entrada y MaterialApp
├── data/              # Datos de demostración
├── models/            # Materia, Apunte, Pregunta, MensajeChat, SesionEstudio
├── screens/           # Pantallas de la app
├── theme/             # Colores y temas claro/oscuro
└── widgets/           # Componentes reutilizables
test/
└── widget_test.dart   # Pruebas de widgets sobre los mockups
```

## Cómo ejecutarlo

Requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.

```bash
git clone <url-del-repositorio>
cd studybuddy_ia
flutter pub get
flutter run          # elige el dispositivo/emulador disponible
flutter test         # pruebas de widgets
```

## Autor

Edwin Pupiales: Ingeniería, Universidad de Nariño.
