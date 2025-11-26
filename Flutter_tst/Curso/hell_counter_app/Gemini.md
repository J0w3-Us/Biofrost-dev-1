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