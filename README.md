# StudyBuddy IA

App móvil de estudio asistido por IA, desarrollada en Flutter como proyecto final de **Desarrollo de Aplicaciones para Dispositivos Móviles** (Universidad de Nariño, 2026-2).

## Qué hace

- **Materias y apuntes.** Crea tus materias por semestre y escribe los apuntes de cada una. Todo se guarda en el dispositivo (SQLite) y sigue ahí al cerrar la app.
- **Resumen con IA.** Cada apunte se resume en tres niveles (corto, medio y detallado) con sus ideas clave. El resumen se guarda, así que después se abre al instante y sin conexión; si editas el texto del apunte, se descarta y se vuelve a generar.
- **Quiz con IA.** La IA escribe preguntas de opción múltiple a partir de los apuntes de la materia, con la explicación de cada respuesta. El quiz se guarda para repetirlo y cada intento cuenta para las estadísticas y el "% dominado" de la materia.
- **Tutor IA.** Un chat por materia que responde con tus apuntes como contexto. La respuesta aparece mientras se escribe y la conversación queda guardada.
- **Escanear apuntes.** Tomas una foto del cuaderno o del tablero (o la eliges de la galería), la IA la pasa a texto y la revisas antes de guardarla como apunte.
- **Plan de estudio.** Registras tus evaluaciones y sesiones de estudio; la app muestra la próxima evaluación con su cuenta regresiva y las sesiones de hoy, atrasadas y próximas. Con "Plan con IA" la IA propone las sesiones para llegar preparado a una evaluación.
- **Pomodoro global.** El temporizador sigue corriendo aunque salgas de su pantalla y avisa con una notificación al terminar cada bloque. El modo demostración (Perfil) usa bloques de segundos para mostrar la app.
- **Estadísticas.** Tiempo de estudio, racha de días, horas de la semana y estudio por materia, calculados con tus sesiones y quizzes reales.
- **Perfil.** Tu nombre y carrera, modo claro u oscuro, recordatorio diario de estudio a la hora que elijas y la conexión con la IA.

## Conectar la IA

La app no trae una clave propia. Las funciones de IA usan el servicio que elijas, con tu clave:

| Servicio | Costo | Dónde se crea la clave | Modelo |
|---|---|---|---|
| **Gemini** (Google) | Tiene nivel gratuito | aistudio.google.com → "Get API key" | `gemini-3.6-flash` |
| **Claude** (Anthropic) | De pago por uso; no lo cubre la suscripción de claude.ai | platform.claude.com → "API keys" | `claude-opus-5-5` |

1. Crea la clave en el servicio que prefieras.
2. En la app, ve a **Perfil → Inteligencia artificial → Conectar la IA**, elige el servicio y pega la clave. También te la pide la primera vez que uses una función de IA.
3. Con **Probar conexión** compruebas que la clave sirve (esa prueba no gasta saldo ni cuota).

La clave se guarda cifrada en el dispositivo (Keystore de Android) y solo se envía al servicio elegido. El texto de tus apuntes y las fotos que escaneas se envían a ese servicio cuando pides un resumen, un quiz, una respuesta del tutor, una transcripción o un plan. En el nivel gratuito de Gemini, Google puede usar lo que envías para mejorar sus productos. Sin clave, el resto de la app (materias, apuntes, plan, Pomodoro y estadísticas) funciona igual.

Los dos servicios comparten las instrucciones y las validaciones (`lib/services/servicio_ia_base.dart`); cada uno solo define cómo se habla con su API (`servicio_ia_gemini.dart` y `servicio_ia_claude.dart`).

## Pantallas

| Sección | Pantalla | Descripción |
|---|---|---|
| Navegación principal | `main_shell` | Barra inferior con 4 pestañas: Inicio, Plan, Stats y Perfil |
| Inicio | `inicio_screen` | Saludo, racha, buscador, selector de semestre y lista de materias (mantén pulsada una tarjeta para editar o borrar). Sin materias, ofrece crear la primera o cargar una de ejemplo |
| Materia | `detalle_materia_screen` | Herramientas de estudio (Resumir, Quiz IA, Tutor IA, Pomodoro), botón Escanear, lista de apuntes y menú para editar o borrar la materia |
| Apuntes | `formulario_apunte_screen` / `apunte_screen` | Crear, editar y leer un apunte, con acceso a su resumen |
| IA | `resumen_ia_screen`, `preparar_quiz_screen`, `quiz_screen`, `resultados_quiz_screen`, `chat_tutor_screen` | Resumen, generación y juego del quiz, y chat con el tutor |
| Productividad | `pomodoro_screen` | Vista del temporizador Pomodoro global (enfoque, descanso corto y largo) |
| Plan | `plan_estudio_screen` | Evaluaciones, sesiones de estudio y plan sugerido por la IA |
| Stats | `estadisticas_screen` | Tiempo total, racha, quizzes, horas de la semana y estudio por materia |
| Perfil | `perfil_screen` | Datos del usuario, tema, modo demostración, recordatorio diario y clave de la IA |

## Tecnologías

- [Flutter](https://flutter.dev/) (Dart SDK `^3.13.2`) con Material 3
- [`provider`](https://pub.dev/packages/provider) para el estado
- [`sqflite`](https://pub.dev/packages/sqflite) para guardar todo en el dispositivo
- [`http`](https://pub.dev/packages/http) para llamar a las APIs de Gemini y Claude
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) para guardar la clave de la API cifrada
- [`image_picker`](https://pub.dev/packages/image_picker) para la cámara y la galería al escanear
- [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) para el aviso del Pomodoro y el recordatorio diario
- [`google_fonts`](https://pub.dev/packages/google_fonts) (tipografía Poppins)

## Estructura del proyecto

```
lib/
├── main.dart          # Punto de entrada: abre la base de datos y monta la app con sus providers
├── data/              # Repositorio SQLite (esquema v5), catálogo de colores/iconos y materia de ejemplo
├── models/            # Materia, Apunte, Pregunta, MensajeChat, Evaluacion, SesionEstudio, resultados de la IA...
├── providers/         # Estado de la app: materias, estadísticas, plan, Pomodoro, ajustes e IA
├── screens/           # Pantallas de la app
├── services/          # Servicio de IA (Gemini y Claude), clave cifrada, cámara y notificaciones
├── theme/             # Colores y temas claro/oscuro
├── utils/             # Fechas, validaciones, semestres y cálculos de estadísticas y del plan
└── widgets/           # Componentes reutilizables y formularios
test/                  # Pruebas de widgets, providers, repositorio SQLite y servicio de IA
docs/superpowers/      # Diseño y plan de implementación de las fases anteriores
```

Las pantallas no hablan directamente con la base de datos ni con la API: pasan por los providers, y estos por interfaces (`MateriasRepository`, `ServicioIa`, `AlmacenClave`, `SelectorImagen`, notificadores). Por eso las pruebas cambian SQLite por un repositorio en memoria y la API por un servicio falso, sin tocar el resto del código.

## Lo que queda por fuera

- **Sincronización en la nube y cuentas de usuario.** Los datos viven solo en el dispositivo: si desinstalas la app, se borran.
- **Servidor propio para la IA.** Hoy cada usuario pone su clave. Para publicar la app haría falta un servidor que guarde la clave y hable con la API.

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

La notificación del Pomodoro usa una alarma de reloj del sistema (por eso Android muestra un ícono de alarma mientras corre un bloque) y pide el permiso de notificaciones la primera vez que abres el Pomodoro. Con ella, el aviso llega aunque el celular congele la app en segundo plano. Algunos celulares (Vivo, Xiaomi y similares) retrasan o bloquean alarmas si la app tiene ahorro de batería: si el aviso no suena a tiempo, en los ajustes del celular marca StudyBuddy IA como "sin restricciones" de batería.

## Autor

Edwin Pupiales: Ingeniería, Universidad de Nariño.
