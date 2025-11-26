# hell_counter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Introducción: Más que un simple temporizador

¡Bienvenido! En esta guía, no solo vamos a construir un temporizador. Vamos a construir un modelo mental de cómo se diseñan y se crean las aplicaciones profesionales de Flutter. Piénsalo como aprender a cocinar un nuevo platillo. Tendrás una receta (esta guía), trabajarás en una cocina organizada profesionalmente (Arquitectura Limpia) y contarás con un sous-chef experto que puede responder cualquier pregunta que tengas (tu asistente de IA, Gemini).

Tu experiencia con otros lenguajes de programación proporciona una base fantástica. Conceptos como manejar eventos de usuario (como el clic de un botón) y actualizar la interfaz de usuario en respuesta son también centrales en el desarrollo móvil. Aquí, exploraremos cómo Flutter, usando el patrón BLoC (Business Logic Component), maneja estos desafíos de una manera altamente estructurada, escalable y predecible.

Un enfoque clave de este ejercicio es transformar la forma en que colaboras con los asistentes de codificación de IA. Muchos desarrolladores usan la IA de forma reactiva: pegan un error y piden una solución. Nosotros vamos a cultivar una mentalidad proactiva. Un desarrollador proactivo utiliza la IA como un socio para explorar ideas, automatizar tareas tediosas y profundizar su propio entendimiento. El objetivo es usar la IA para *acelerar el aprendizaje*, no para *evitarlo*. La siguiente tabla ilustra este cambio crucial.

**Tabla 1: Pasando de una mentalidad de IA reactiva a una proactiva**

| **Prompt Reactivo (Lo que queremos evitar)**            | **Prompt Proactivo (Lo que queremos fomentar)**                                                                                                           |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Mi app crasheó, aquí está el log de error, arréglalo." | "Explícame este log de error. ¿Cuáles son las causas comunes de un `LateInitializationError` en Flutter?"                                                 |
| "Escribe el código para un BLoC de temporizador."       | "Genera el código base para un `TimerBloc` con estados para Inicial, Corriendo, Pausado y Finalizado. Yo completaré la lógica."                           |
| "Este widget no se está actualizando."                  | "Explica el rol de `buildWhen` en `BlocBuilder`. ¿Cómo puedo usarlo para prevenir reconstrucciones innecesarias en mi widget de Acciones?"                |
| "¿Cómo centrar un botón?"                               | "Sugiérceme tres estrategias de layout diferentes en Flutter para crear un panel de acciones principal y explica las ventajas y desventajas de cada una." |

Al final de esta guía, tendrás una aplicación de temporizador funcional, un sólido entendimiento de BLoC y un nuevo y poderoso flujo de trabajo para colaborar con la IA y convertirte en un desarrollador más eficaz y conocedor. Comencemos.

![javerage.timer.gif](attachment:d375eba6-a093-4bcc-90c9-7967056f2e32:javerage.timer.gif)

[Javerage Timer](https://github.com/javerage/javerage_timer.git)

---

## Parte 1: Sentando una Base Profesional

Antes de escribir una sola línea de código, debemos construir el taller. Una estructura de proyecto bien organizada es la diferencia entre un proyecto divertido y mantenible y uno frustrante y caótico. Aquí es donde entra en juego la Arquitectura Limpia.

### 1. Creación del Proyecto

Comenzaremos creando un nuevo proyecto de Flutter, especificando que será para Android e iOS. Usar parámetros como `--org` le da a tu proyecto una identidad profesional desde el principio.

```bash
flutter create --org [com.organization] --platforms android,ios --project-name [project_name] [folder_output]
```

Luego, navega al directorio del proyecto:

```bash
cd [folder_output]
```

### 2. Inicialización del Repositorio

El control de versiones es una necesidad en el desarrollo de software. Inicialicemos un repositorio de Git desde el primer momento para rastrear todos nuestros cambios. Asegurate de que te encuentras en la carpeta de tu proyecto, inicializa una terminal y ejecuta los siguientes comandos:

```bash
git init -b main
git add .
git commit -m "Initial commit: Create Flutter project"
```

### 3. Configuración del Asistente de IA

Para que nuestra colaboración con Gemini sea efectiva, debemos darle contexto. Crearemos un archivo `gemini.md` que le indique las "reglas del juego" de nuestro proyecto.

Primero, inicializa la CLI de Gemini en la terminal del proyecto y ejecuta el siguiente comando:

```bash
/init
```

Ahora, reemplaza el contenido del archivo `gemini.md` que se creó en la raíz de tu proyecto con lo siguiente:

```markdown
# Gemini Code Understanding

## Project Overview

### Project Goal

Build a timer application in Flutter to teach state management using the BLOC pattern and Clean Architecture principles.

### Key Technologies & Patterns

- **State Management:** Use the `flutter_bloc` package. All state logic must be handled by a TimerBloc.
- **Architecture:** Follow Clean Architecture principles with a feature-first structure. The main directories under `lib/`should be `core/` and `features/`. Each feature should be self-contained with `application`, `data`, `domain`, and `presentation` layers.
- **Code Style:** Adhere to Dart's official style guide. Use sealed classes for BLoC states and events.
- **Dependencies:** Key dependencies are `flutter_bloc`, `bloc`, `equatable`, and `wave`.

### Role of AI

The AI should act as a teaching assistant and expert pair programmer. When asked for code, prioritize generating boilerplate or specific, well-defined functions. When asked for explanations, provide clear, concise answers with analogies relevant to a student audience. Encourage proactive prompting.

## Building and Running

### Prerequisites

- Flutter SDK
- A configured emulator or a physical device

### Key Commands

- **Get dependencies:** `flutter pub get`
- **Run the app:** `flutter run --debug`
- **Run tests:** `flutter test`
```

### 4. El Plano: Estructura de Arquitectura Limpia

Con la configuración inicial lista, es hora de definir la estructura de carpetas. Usaremos una arquitectura limpia por capas, que separa las responsabilidades del código y lo hace más mantenible y escalable.

- `domain`: Contiene la lógica de negocio más pura y las "reglas" de la aplicación (entidades y contratos/interfaces). No depende de ninguna otra capa.
- `data`: Implementa los contratos definidos en el dominio. Se encarga de obtener los datos, ya sea de una API, una base de datos o, como en nuestro caso, de una fuente de tiempo.
- `application`: Orquesta el flujo de datos entre la presentación y las capas de datos/dominio. Aquí es donde vive nuestro BLoC.
- `presentation`: Es la capa de la interfaz de usuario (UI). Contiene los widgets que el usuario ve e interactúa.

Usa el siguiente comando para crear la estructura de carpetas necesaria para nuestra característica `timer`:

Bash

```bash
gcloud alpha gemini chat "Generate a bash command to create the following directory structure inside the 'lib' folder: core/app, core/theme, features/timer/application, features/timer/data/repositories, features/timer/domain/entities, features/timer/domain/repositories, features/timer/presentation/screens, features/timer/presentation/widgets"
```

Ejecuta el comando que Gemini te proporcione. Tu estructura de carpetas ahora reflejará un estándar profesional.

### 5. Configuración de Dependencias

Finalmente, agreguemos los paquetes que necesitaremos. Ejecuta los siguientes comandos en tu terminal:

```bash
flutter pub add bloc flutter_bloc equatable wave
flutter pub add dev:bloc_test mocktail
```

- `flutter_bloc`: La herramienta principal para conectar BLoC con Flutter.
- `equatable`: Ayuda a optimizar el rendimiento al evitar reconstrucciones innecesarias de la UI.
- `wave`: Un paquete para crear el efecto de olas animadas en el fondo.

---

## Parte 2: El Corazón de la App - Capas de Dominio y Datos

Comenzaremos desde el núcleo de la aplicación hacia afuera. La capa de dominio define las reglas y la lógica de negocio pura, mientras que la capa de datos implementa cómo se conectan esas reglas con el mundo exterior.

### La Capa de Dominio: Lógica Pura y Contratos

El dominio es la capa más interna y no depende de ninguna otra. Contiene nuestras "joyas de la corona": la lógica de negocio y las definiciones abstractas (contratos).

1. La Entidad de Negocio: Ticker

Nuestra lógica de negocio principal es la capacidad de generar una cuenta regresiva. La clase Ticker encapsula esta responsabilidad. La consideramos una "entidad" porque es un objeto fundamental en el dominio de nuestra aplicación.

Crea el archivo `lib/features/timer/domain/entities/ticker.dart`:

```dart
/// The `Ticker` class in Dart provides a stream of integers that emit a value every second.
class Ticker {
	const Ticker();

	Stream<int> tick() {
		return Stream.periodic(const Duration(seconds: 1), (x) => x);
	}
}

```

Esta clase es completamente independiente. No sabe nada sobre BLoC, Flutter o de dónde vendrán los datos. Su única misión es generar un `Stream` de enteros que represente un periodo de tiempo.

2. El Contrato del Repositorio: TimerRepository

A continuación, definimos un "contrato" abstracto. Este contrato establece que cualquier parte de la aplicación que quiera interactuar con la lógica del temporizador debe hacerlo a través de una interfaz que tenga un método ticker. Esto desacopla la capa de aplicación de los detalles de implementación.

Crea el archivo `lib/features/timer/domain/repositories/timer_repository.dart`:

```dart
/// The `TimerRepository` class in Dart provides a stream of integer values representing time ticks.
abstract class TimerRepository {
	Stream<int> ticker();
}

```

### La Capa de Datos: La Implementación Concreta

La capa de datos es responsable de implementar los contratos definidos en el dominio. Actúa como un puente entre la lógica de negocio pura y el resto de la aplicación.

Implementando el Repositorio: `TimerRepositoryImpl`

Esta clase concreta cumple con el contrato `TimerRepository`. Su trabajo es tomar la entidad `Ticker` del dominio y usarla para proporcionar el flujo de datos requerido.

Crea el archivo `lib/features/timer/data/repositories/timer_repository_impl.dart`:

Dart

```dart
import 'package:javerage_timer/features/timer/domain/repositories/timer_repository.dart';
import 'package:javerage_timer/features/timer/domain/entities/ticker.dart';

/// The `TimerRepositoryImpl` class implements the `TimerRepository` interface and provides a stream of
/// ticks using a `Ticker` instance.
class TimerRepositoryImpl implements TimerRepository {
	TimerRepositoryImpl(this._ticker);

	final Ticker _ticker;

	@override
	Stream<int> ticker() => _ticker.tick();
}

```

Observa el patrón de **Inyección de Dependencias**: `TimerRepositoryImpl` no crea su propia instancia de `Ticker`, sino que la recibe en su constructor. Esto hace que nuestro código sea modular y fácil de probar, ya que podríamos "inyectar" un `Ticker` falso durante las pruebas.

---

## Parte 3: El Cerebro de la Operación - La Capa de Aplicación (BLoC)

Con las capas de datos y dominio listas, es hora de construir el cerebro: el `TimerBloc`. Este componente orquestará la lógica, escuchará eventos de la UI y producirá estados que la UI pueda mostrar.

### Una Conversación con tu App: Eventos y Estados

- **Eventos**: Mensajes de la UI al BLoC (ej. "el usuario presionó start").
- **Estados**: Mensajes del BLoC a la UI (ej. "el temporizador está corriendo en 34 segundos").

1. Definiendo los Eventos

Crea el archivo `lib/features/timer/application/timer_event.dart`:

```dart
part of 'timer_bloc.dart';

/// The `sealed class TimerEvent extends Equatable` declaration in Dart is creating a base class called
/// `TimerEvent` that is marked as `sealed`. In Dart, a sealed class restricts its subclasses to be
/// defined in the same file. This helps in ensuring that all possible subclasses of `TimerEvent` are
/// known and handled within the same file.
sealed class TimerEvent extends Equatable {
	const TimerEvent();

	@override
	List<Object> get props => [];
}

/// The `TimerStarted` class in Dart represents an event indicating the start of a timer with a
/// specified duration.
class TimerStarted extends TimerEvent {
	const TimerStarted({required this.duration});
	final int duration;
}

/// The `TimerTicked` class represents an event that occurs when a timer ticks with a specified
/// duration.
class TimerTicked extends TimerEvent {
	const TimerTicked({required this.duration});
	final int duration;

	@override
	List<Object> get props => [duration];
}

/// The `TimerPaused` class is a Dart class that represents an event where a timer is paused.
class TimerPaused extends TimerEvent {
	const TimerPaused();
}

/// The `TimerReset` class is a subclass of `TimerEvent` in Dart that represents an event to reset the
/// timer.
class TimerReset extends TimerEvent {
	const TimerReset();
}

```

2. Definiendo los Estados

Crea el archivo `lib/features/timer/application/timer_state.dart`:

```dart
part of 'timer_bloc.dart';

/// The `sealed class TimerState extends Equatable` in Dart is defining a base class `TimerState` that
/// is marked as `sealed`. In Dart, a sealed class restricts its subclasses to be defined in the same
/// file. This helps in ensuring that all possible subclasses of `TimerState` are known and handled
/// within the same file.
sealed class TimerState extends Equatable {
	const TimerState(this.duration);
	final int duration;

	@override
	List<Object> get props => [duration];
}

/// The `TimerInitial` class represents the initial state of a timer with a specified duration in Dart.
class TimerInitial extends TimerState {
	const TimerInitial(super.duration);

	@override
	String toString() => 'TimerInitial { duration: $duration }';
}

/// The `TimerTicking` class represents the state of a timer that is currently ticking with a specific
/// duration.
class TimerTicking extends TimerState {
	const TimerTicking(super.duration);

	@override
	String toString() => 'TimerTicking { duration: $duration }';
}

/// The `TimerFinished` class represents a state where the timer has finished.
class TimerFinished extends TimerState {
	const TimerFinished() : super(0);
}

```

### 3. Implementando el TimerBloc

Ahora, unimos todo. El BLoC es una máquina de estados que transita de un estado a otro en respuesta a los eventos.

Crea el archivo `lib/features/timer/application/timer_bloc.dart`:

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:javerage_timer/features/timer/domain/repositories/timer_repository.dart';

part 'timer_event.dart';
part 'timer_state.dart';

/// The TimerBloc class in Dart is responsible for managing timer events and states, utilizing a
/// TimerRepository for functionality like starting, ticking, pausing, and resetting timers.
class TimerBloc extends Bloc<TimerEvent, TimerState> {
	TimerBloc({required TimerRepository timerRepository})
			: _timerRepository = timerRepository,
				super(const TimerInitial(_duration)) {
		on<TimerStarted>(_onStarted);
		on<TimerTicked>(_onTicked);
		on<TimerPaused>(_onPaused);
		on<TimerReset>(_onReset);
	}

	final TimerRepository _timerRepository;
	static const int _duration = 60;

	StreamSubscription<int>? _tickerSubscription;

	@override
	Future<void> close() {
		_tickerSubscription?.cancel();
		return super.close();
	}

	void _onStarted(TimerStarted event, Emitter<TimerState> emit) {
		emit(TimerTicking(event.duration));
		_tickerSubscription?.cancel();
		_tickerSubscription = _timerRepository
				.ticker()
				.listen((ticks) => add(TimerTicked(duration: event.duration - ticks)));
	}

	void _onTicked(TimerTicked event, Emitter<TimerState> emit) {
		emit(
			event.duration > 0
					? TimerTicking(event.duration)
					: const TimerFinished(),
		);
	}

	void _onPaused(TimerPaused event, Emitter<TimerState> emit) {
		if (state is TimerTicking) {
			_tickerSubscription?.pause();
			emit(TimerInitial(state.duration));
		}
	}

	void _onReset(TimerReset event, Emitter<TimerState> emit) {
		_tickerSubscription?.cancel();
		emit(const TimerInitial(_duration));
	}
}
```

---

## Parte 4: Dándole Vida - La Capa de Presentación

Con toda la lógica lista, es hora de construir la interfaz de usuario. Seguiremos un enfoque "de adentro hacia afuera", creando primero los widgets más pequeños.

1. El Fondo Animado: `custom_waves.dart`

Este widget utiliza el paquete wave para crear un fondo animado.

Crea el archivo `lib/features/timer/presentation/widgets/custom_waves.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

/// The `CustomWaves` class creates a widget with custom wave configurations for a visually appealing
/// design.
class CustomWaves extends StatelessWidget {
	const CustomWaves({super.key});

	@override
	Widget build(BuildContext context) {
		return WaveWidget(
			config: CustomConfig(
				gradients: [
					[
						const Color.fromRGBO(72, 136, 199, 1),
						const Color.fromRGBO(72, 136, 199, 1),
					],
					[
						const Color.fromRGBO(72, 136, 199, 0.8),
						const Color.fromRGBO(72, 136, 199, 0.8),
					],
					[
						const Color.fromRGBO(72, 136, 199, 0.6),
						const Color.fromRGBO(72, 136, 199, 0.6),
					],
					[
						const Color.fromRGBO(72, 136, 199, 0.4),
						const Color.fromRGBO(72, 136, 199, 0.4),
					],
				],
				durations: [30000, 21000, 18000, 50000],

				heightPercentages: [0.30, 0.28, 0.30, 0.26],
				blur: const MaskFilter.blur(BlurStyle.solid, 10),
				gradientBegin: Alignment.bottomLeft,
				gradientEnd: Alignment.topRight,
			),
			waveAmplitude: 35,
			size: const Size(double.infinity, double.infinity),
		);
	}
}
```

2. El Contenedor del Fondo: `background.dart`

Un widget simple que solo muestra nuestras olas, puedes cambiar el fondo a cualquier otra animación.

Crea el archivo `lib/features/timer/presentation/widgets/background.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:javerage_timer/features/timer/presentation/widgets/custom_waves.dart';

/// The `Background` class is a StatelessWidget that returns a `CustomWaves` widget in its build method.
class Background extends StatelessWidget {
	const Background({super.key});

	@override
	Widget build(BuildContext context) {
		return const CustomWaves();
	}
}
```

3. El Texto del Temporizador: `timer_text.dart`

Este widget se suscribe a los cambios de duration en el BLoC y muestra el tiempo formateado.

Crea el archivo `lib/features/timer/presentation/widgets/timer_text.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:javerage_timer/features/timer/application/timer_bloc.dart';

/// The TimerText class is a StatelessWidget in Dart that displays a timer in minutes and seconds
/// format.
class TimerText extends StatelessWidget {
	const TimerText({super.key});

	@override
	Widget build(BuildContext context) {
		final duration = context.select((TimerBloc bloc) => bloc.state.duration);
		final minutesStr = ((duration / 60) % 60).floor().toString().padLeft(
			2,
			'0',
		);
		final secondsStr = (duration % 60).floor().toString().padLeft(2, '0');
		return Text(
			'$minutesStr:$secondsStr',
			style: Theme.of(context).textTheme.headlineLarge,
		);
	}
}
```

... (content continues with the rest of the user's provided guide)
