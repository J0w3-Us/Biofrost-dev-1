# Contexto del Proyecto — Kaelen Legacy

Este documento sintetiza el estado actual del repositorio (tal como está ahora) y lista las mejoras pendientes. Sirve como contexto rápido para nuevos integrantes y para coordinación de tareas.

---

## Resumen del estado actual

- Motor: Flame (versión usada en el proyecto). El plan y las validaciones de rendimiento en SAFE_IMPLEMENTATION_PLAN.md referencian prácticas compatibles con Flame.
- Backend: Supabase integrado (configuración presente en `lib/` / `main.dart` para entornos de prueba).
- Persistencia local: `SharedPreferences` para progreso y bindings.
- Reproductor de vídeo: usado en `home_screen.dart` para cinemáticas y menú.
- Gestión de estado: `Provider` (ej. `GameProgressProvider`, `AuthProvider`).
- Colisiones: Implementación de colisión pixel-perfect en `lib/game/backend/collision_utils.dart`.

### Archivos y componentes clave

- `lib/runner_game.dart` — Núcleo del juego y bucle principal; escena, player, transiciones de puerta.
- `lib/game/spikes.dart` — Obstáculos (pinchos, homing spikes) con máscaras alfa para colisión.
- `lib/game/backend/collision_utils.dart` — Utilidades de colisión pixel-perfect.
- `lib/screens/home_screen.dart` — Menú principal con video-based UI.
- `lib/providers/game_progress_provider.dart` — Persistencia de desbloqueos y progreso.
- `pubspec.yaml` — Dependencias y assets (videos, fuentes, tilesets).

### Estado operativo

- El juego corre localmente desde el workspace (estructura de plataformas Android/iOS/Web/Windows presente).
- Hay trabajo en progreso documentado en `docs/SAFE_IMPLEMENTATION_PLAN.md` y `docs/IMPROVEMENT_ROADMAP.md`.
- Se han añadido validaciones de uso de APIs de Flame (Context7) en el plan seguro.

---

## Mejoras planteadas por hacer

A continuación se resumen las mejoras identificadas en el roadmap y que aún requieren implementación o pulido:

- 1. Game Feel
  - Screen shake natural con `NoiseEffectController`.
  - Sistema de partículas con `AcceleratedParticle` para impacto y muerte.
  - Implementar y afinar Coyote Time y Hit Stop.

- 2. Mecánicas de Jugador
  - Dash y Wall Jump (ajustes y testeo de feedback).
  - Sistema de llaves e interruptores con animaciones y persistencia.

- 3. Arquitectura de Niveles (Tiled)
  - Migración a `TiledComponent` con `TiledComponent.load()` y feature-flag para conmutar sistemas.
  - Mapeo de capas de colisión a `RectangleHitbox` y pruebas de rendimiento.

- 4. Backend y Progresión
  - Servicio de estadísticas y telemetría (`lib/services/game_statistics_service.dart`).
  - Servicio de Desafíos Diarios (`lib/services/daily_challenge_service.dart`).

- 5. Narrativa y Cinemáticas
  - `CinematicManager` para reproducir cinemáticas y hooks de flujo.
  - `DialogueSystem` para colas de diálogos y subtítulos.

- 6. UI / UX Avanzada
  - Sistema de transiciones (`fadeToBlack`, overlays) y mejoras en el menú.
  - Controles personalizables con almacenamiento en `SharedPreferences`.

---

## Instrucción siguiente

Leer el siguiente documento: #imp+

(Nota: `#imp+` refiere al documento de roadmap/improvements principal — por ejemplo `docs/IMPROVEMENT_ROADMAP.md` — abrir ese documento para detalles y tareas desglosadas.)

---

Si quieres, puedo:

- Añadir esta referencia al índice `README.md`.
- Crear issues/epics por cada mejora y asignarlos al equipo.
- Hacer commits con scaffolding de los servicios mencionados.

Indícame qué prefieres como siguiente paso.
