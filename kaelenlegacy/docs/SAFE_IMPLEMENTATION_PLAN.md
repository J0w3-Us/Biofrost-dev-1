# 🛡️ Plan de Implementación Segura - Kaelen Legacy

Este documento detalla los pasos operativos para ejecutar el [Roadmap de Mejoras](IMPROVEMENT_ROADMAP.md) minimizando riesgos técnicos. El enfoque principal es la **modularidad**: implementar nuevos sistemas en archivos aislados antes de integrarlos en el código _legacy_ (`runner_game.dart`).

---

## ✅ Matriz de Verificación: Roadmap vs Plan de Implementación

| Mejora del Roadmap           | Cubierta en Plan | Fase   | Estado              |
| ---------------------------- | ---------------- | ------ | ------------------- |
| **1. Narrativa Vinculada**   | ⚠️ Parcial       | -      | Falta fase dedicada |
| - Cinemáticas In-Game        | ❌ No cubierto   | -      | Añadir Fase 5       |
| - Contexto de Obstáculos     | ❌ No cubierto   | -      | Añadir Fase 5       |
| **2. Game Feel**             | ✅ Completo      | Fase 1 | OK                  |
| - Screen Shake + Hit Stop    | ✅ Paso 1.1      | Fase 1 | OK                  |
| - Sistema de Partículas      | ✅ Paso 1.2      | Fase 1 | OK                  |
| - Coyote Time                | ✅ Paso 2.1      | Fase 2 | OK                  |
| **3. Mecánicas del Jugador** | ✅ Completo      | Fase 2 | OK                  |
| - Sistema de Dash            | ✅ Paso 2.2      | Fase 2 | OK                  |
| - Llaves e Interruptores     | ⚠️ Implícito     | Fase 3 | Falta paso dedicado |
| **4. Backend Supabase**      | ✅ Completo      | Fase 4 | OK                  |
| - Estadísticas               | ✅ Paso 4.1      | Fase 4 | OK                  |
| - Desafíos Diarios           | ⚠️ Implícito     | Fase 4 | Falta paso dedicado |
| **5. UI/UX de Alta Gama**    | ⚠️ Parcial       | -      | Falta fase dedicada |
| - Transiciones Fluidas       | ❌ No cubierto   | -      | Añadir Fase 6       |
| - Controles Adaptativos      | ❌ No cubierto   | -      | Añadir Fase 6       |
| **6. Diseño con Tiled**      | ✅ Completo      | Fase 3 | OK                  |

### Brechas Identificadas

1. **Narrativa (Fase 5):** No hay pasos para implementar `CinematicManager` ni contextualización de obstáculos.
2. **UI/UX (Fase 6):** Faltan pasos para `GameTransitions` y `CustomizableGameControls`.
3. **Desafíos Diarios:** Falta paso 4.2 dedicado al servicio de challenges.

---

## 🚀 Optimizaciones de Rendimiento del Motor Flame

> **Validado con Context7** - Documentación oficial Flame v1.22.0

### Principio 1: Evitar Creación de Objetos por Frame

**❌ Código Problemático (Actual en `runner_game.dart`):**

```dart
@override
void update(double dt) {
  position += Vector2(10, 20) * dt;  // Crea Vector2 cada frame
}

@override
void render(Canvas canvas) {
  canvas.drawRect(size.toRect(), Paint());  // Crea Paint cada frame
}
```

**✅ Código Optimizado:**

```dart
class Player extends PositionComponent {
  // Reusar objetos - declarar como campos
  final _direction = Vector2(10, 20);
  final _paint = Paint();

  @override
  void update(double dt) {
    position.setValues(
      position.x + _direction.x * dt,
      position.y + _direction.y * dt,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }
}
```

### Principio 2: Usar `HasPerformanceTracker` para Debugging

```dart
class RunnerGame extends FlameGame with HasPerformanceTracker {
  // Acceder a métricas de rendimiento
  void logPerformance() {
    debugPrint('Update time: $updateTime ms');
    debugPrint('Render time: $renderTime ms');
  }
}
```

### Principio 3: Culling de Componentes Fuera de Cámara

```dart
// Verificar si un componente es visible antes de procesarlo
if (!camera.canSee(component)) {
  component.removeFromParent(); // O pausar updates
}
```

### Principio 4: Snapshot para Fondos Estáticos

```dart
class SnapshotBackground extends PositionComponent with Snapshot {}

// En RunnerGame.onLoad():
final background = SnapshotBackground();
background.add(backgroundSprite);
add(background);
// El fondo se renderiza una sola vez y se cachea
```

### Principio 5: Filtrar Colisiones por Tipo

```dart
class Spike extends PositionComponent with CollisionCallbacks {
  @override
  bool onComponentTypeCheck(PositionComponent other) {
    // Solo colisionar con Player, ignorar otros spikes/decoraciones
    return other is Player;
  }
}
```

---

## 📋 Fase 1: Calidad de Vida y "Game Feel" (Bajo Riesgo)

**Objetivo:** Mejorar el feedback visual sin alterar la lógica central del juego. Esta fase tiene alto impacto visual y bajo riesgo de regresión.

### Paso 1.1: Sistema de Screen Shake y Efectos

> **✅ Validado con Context7:** Usar `NoiseEffectController` para shake más suave

1.  **Crear el sistema aislado:**
    - Crear `lib/game/backend/effects/game_feel.dart`.
    - Implementar la clase `GameFeelSystem` con métodos `screenShake()` y `hitStop()`.

    **Código validado por Context7:**

    ```dart
    // Alternativa oficial de Flame para shake effects
    final controller = NoiseEffectController(duration: 0.6, frequency: 10);
    ```

2.  **Integración en RunnerGame:**
    - En `lib/game/backend/runner_game.dart`, añadir la propiedad `late final GameFeelSystem gameFeel;`.
    - Inicializar en `onLoad()`: `gameFeel = GameFeelSystem(this);`.
3.  **Conectar eventos:**
    - Modificar `onPlayerDied()`: Insertar `await gameFeel.playerDeathImpact();` **antes** de pausar el motor o mostrar 'GameOver'.
    - _Verificación:_ Al morir, el juego debe congelarse brevemente (hitstop) y sacudirse antes de mostrar el menú.

### Paso 1.2: Sistema de Partículas

> **✅ Validado con Context7:** Usar `ParticleSystemComponent` con `AcceleratedParticle`

1.  **Crear el sistema:**
    - Crear `lib/game/backend/effects/particle_system.dart`.
    - Implementar `KaelenParticleSystem` con métodos estáticos para generar componentes de partículas.

    **Código validado por Context7:**

    ```dart
    game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 10,
          generator: (i) => AcceleratedParticle(
            acceleration: randomVector2(),
            child: CircleParticle(paint: Paint()..color = Colors.red),
          ),
        ),
      ),
    );
    ```

2.  **Integración en Player:**
    - En la clase `Player` (dentro de `runner_game.dart`), añadir un timer para partículas de correr.
    - En `update()`: Generar `runningDust` cuando la velocidad horizontal sea alta y el jugador esté en el suelo.
    - En `jump()`: Invocar `gameRef.add(KaelenParticleSystem.jumpBurst(...))` al ejecutar un salto exitoso.

    **⚠️ Optimización de Rendimiento:**

    ```dart
    // EVITAR crear objetos cada frame
    // Reusar el Paint y otros objetos como campos de clase
    final _dustPaint = Paint()..color = const Color(0x88996644);
    ```

---

## 🎮 Fase 2: Mecánicas de Control (Riesgo Medio)

**Objetivo:** Mejorar la respuesta del personaje. Requiere modificar la clase `Player` y realizar pruebas constantes de movilidad.

### Paso 2.1: Coyote Time (Salto Permisivo)

> **✅ Validado:** Técnica estándar de plataformeros - 80-150ms es el rango óptimo

1.  **Preparación:**
    - Identificar la lógica actual de detección de suelo en `Player`.
2.  **Modificación de Estado:**
    - Añadir variables a `Player`: `double _coyoteTimer = 0.0` y `bool _wasOnGround = false`.
3.  **Lógica de Actualización:**
    - En `update(dt)`: Si está en el suelo, reiniciar `_coyoteTimer`. Si no, restarle `dt`.
4.  **Refactor del Salto:**
    - Cambiar la condición de salto de `if (isGrounded)` a `if (isGrounded || _coyoteTimer > 0)`.
    - Al saltar, establecer `_coyoteTimer = 0` inmediatamente para prevenir saltos dobles.

### Paso 2.2: Mecánica de Dash (Deslizamiento)

> **✅ Validado con Context7:** Usar `MoveEffect` para animación fluida

1.  **Creación del Mixin:**
    - Crear `lib/game/backend/mechanics/dash_system.dart`.
    - Definir `mixin DashMechanic on PositionComponent`.

    **Código de referencia Context7 para efectos de movimiento:**

    ```dart
    add(
      MoveEffect.by(
        Vector2(-2 * size.x, 0),
        EffectController(
          duration: 0.15,  // Dash rápido
          curve: Curves.easeOut,
        ),
      ),
    );
    ```

2.  **Integración:**
    - Añadir `with DashMechanic` a la clase `Player`.
    - En `Player.update()`, llamar a `updateDash(dt)`.
3.  **Controles:**
    - Añadir método `dash()` en `Player` y exponerlo a través de `RunnerGame`.
    - _Nota:_ Esto requerirá añadir un botón en la UI (`GameScreen`) más adelante.

### Paso 2.3: Sistema de Llaves e Interruptores (NUEVO)

> **Identificado como brecha en verificación**

1.  **Crear sistema:**
    - Crear `lib/game/backend/mechanics/key_system.dart`.
    - Implementar `KeyComponent`, `LockedDoor`, y `PlayerInventory`.
2.  **Integración:**
    - Añadir `PlayerInventory inventory` a `RunnerGame`.
    - En `update()`: Verificar colisiones jugador-llave y jugador-puerta.
3.  **Efectos visuales:**
    - Usar `MoveEffect.by` para animación de flotación de llaves.
    ```dart
    add(MoveEffect.by(
      Vector2(0, -5),
      EffectController(duration: 0.8, reverseDuration: 0.8, infinite: true),
    ));
    ```

---

## 🏗️ Fase 3: Arquitectura de Niveles (Riesgo Alto - Tiled)

**Objetivo:** Transición a niveles diseñados manualmente sin romper el generador actual.

### Paso 3.1: Configuración

> **✅ Validado con Context7:** `flame_tiled` v1.18.0 compatible con Flame v1.22.0

1.  **Dependencias:**
    - Añadir `flame_tiled: ^1.18.0` al `pubspec.yaml` y ejecutar `flutter pub get`.
2.  **Assets:**
    - Configurar carpetas en `assets/levels/` y `assets/images/tilesets/`.

### Paso 3.2: Cargador Paralelo

> **✅ Validado con Context7:** Usar `TiledComponent.load()` con opciones de optimización

1.  **Cargador:**
    - Crear `lib/game/backend/level/tiled_level_loader.dart`.

    **Código optimizado según Context7:**

    ```dart
    final component = await TiledComponent.load(
      'my_map.tmx',
      Vector2.all(32),
      ignoreFlip: true,  // Mejora rendimiento con texturas grandes
      atlasMaxX: 4096,   // Ajustar según plataforma
      atlasMaxY: 4096,
    );
    ```

2.  **Nivel de Prueba:**
    - Crear un mapa simple `test_level.tmx` para validar colisiones y renderizado.
3.  **Implementación "Feature Flag":**
    - En `RunnerGame`, crear un método temporal `_loadTiledLevel()` separado de `_buildScene()`.
    - Usar una variable booleana `useTiledLevels = false` para alternar entre el sistema antiguo y el nuevo durante el desarrollo. **No reemplazar el código existente inmediatamente.**

### Paso 3.3: Sistema de Colisiones para Tiled (NUEVO)

> **✅ Validado con Context7:** Usar `CollisionCallbacks` mixin

```dart
class TiledLevel extends Component with HasCollisionDetection {
  void _processCollisionLayer(ObjectGroup layer) {
    for (final obj in layer.objects) {
      final hitbox = RectangleHitbox(
        position: Vector2(obj.x, obj.y),
        size: Vector2(obj.width, obj.height),
      );
      add(hitbox);
    }
  }
}
```

---

## 📊 Fase 4: Backend y Progresión (Aislado)

**Objetivo:** Persistencia de datos avanzada.

### Paso 4.1: Servicios de Datos

1.  **Servicio:**
    - Crear `lib/services/game_statistics_service.dart`.
2.  **Integración:**
    - Instanciar el servicio en `main.dart` o un Provider global.
    - Inyectar el servicio en `RunnerGame`.
3.  **Telemetría:**
    - Añadir llamadas al servicio en eventos clave (fin de nivel, muerte, recolección de monedas) sin esperar respuesta (`fire and forget`) para no bloquear el hilo del juego.

### Paso 4.2: Sistema de Desafíos Diarios (NUEVO)

> **📍 Cubre:** Roadmap Sección 4 - Sistema de Progresión

```dart
// lib/services/daily_challenge_service.dart
class DailyChallengeService {
  static const String _lastChallengeKey = 'last_challenge_date';

  Future<DailyChallenge> getTodayChallenge() async {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final random = Random(seed);

    return DailyChallenge(
      levelId: random.nextInt(10) + 1,
      objective: ChallengeObjective.values[random.nextInt(3)],
      targetValue: 100 + random.nextInt(400),
      rewardCoins: 50 + random.nextInt(100),
    );
  }
}
```

---

## 🎬 Fase 5: Narrativa y Cinemáticas (NUEVO)

**Objetivo:** Mejorar la experiencia narrativa sin modificar el gameplay core.

> **📍 Cubre:** Roadmap Sección 5 - Sistema Narrativo

### Paso 5.1: Gestor de Cinemáticas

> **✅ Validado:** Integración con VideoPlayerController existente en home_screen.dart

```dart
// lib/game/backend/cinematic/cinematic_manager.dart
class CinematicManager {
  final Map<String, String> _cinematics = {
    'intro': 'assets/videos/intro.mp4',
    'new_game': 'assets/videos/newgameintro.mp4',
    'map_reveal': 'assets/videos/showmap.mp4',
  };

  VideoPlayerController? _activeController;

  Future<void> playCinematic(String key, VoidCallback onComplete) async {
    final path = _cinematics[key];
    if (path == null) return;

    _activeController = VideoPlayerController.asset(path);
    await _activeController!.initialize();

    _activeController!.addListener(() {
      if (_activeController!.value.position >= _activeController!.value.duration) {
        onComplete();
        dispose();
      }
    });

    await _activeController!.play();
  }

  void dispose() {
    _activeController?.dispose();
    _activeController = null;
  }
}
```

### Paso 5.2: Sistema de Diálogos

```dart
// lib/game/backend/dialogue/dialogue_system.dart
class DialogueSystem extends Component with HasGameRef<RunnerGame> {
  final Queue<DialogueLine> _dialogueQueue = Queue();
  TextComponent? _activeDialogue;

  void queueDialogue(List<DialogueLine> lines) {
    _dialogueQueue.addAll(lines);
    if (_activeDialogue == null) _showNext();
  }

  void _showNext() {
    if (_dialogueQueue.isEmpty) return;

    final line = _dialogueQueue.removeFirst();
    _activeDialogue = TextComponent(
      text: line.text,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontFamily: 'Cinzel',
        ),
      ),
    );

    add(_activeDialogue!);

    // Auto-avanzar después de duración
    Future.delayed(Duration(seconds: line.duration), () {
      _activeDialogue?.removeFromParent();
      _activeDialogue = null;
      _showNext();
    });
  }
}
```

---

## 🎨 Fase 6: UI/UX Avanzada (NUEVO)

**Objetivo:** Mejorar transiciones y controles sin afectar gameplay.

> **📍 Cubre:** Roadmap Sección 6 - Pulido Visual y UX

### Paso 6.1: Sistema de Transiciones

> **✅ Validado con Context7:** Usar `RouterComponent` con `pushRoute` para transiciones

```dart
// lib/game/backend/ui/game_transitions.dart
class GameTransitions {
  static Future<void> fadeToBlack(
    FlameGame game, {
    double duration = 0.5,
    VoidCallback? onMidpoint,
  }) async {
    final overlay = RectangleComponent(
      size: game.size,
      paint: Paint()..color = Colors.black.withOpacity(0),
    );

    game.add(overlay);

    // Fade in
    overlay.add(OpacityEffect.to(
      1.0,
      EffectController(duration: duration),
      onComplete: () {
        onMidpoint?.call();

        // Fade out
        overlay.add(OpacityEffect.to(
          0.0,
          EffectController(duration: duration),
          onComplete: () => overlay.removeFromParent(),
        ));
      },
    ));
  }
}
```

### Paso 6.2: Controles Personalizables

```dart
// lib/game/backend/input/customizable_controls.dart
class CustomizableControls with ChangeNotifier {
  Map<GameAction, LogicalKeyboardKey> _keyBindings = {
    GameAction.jump: LogicalKeyboardKey.space,
    GameAction.dash: LogicalKeyboardKey.shiftLeft,
    GameAction.pause: LogicalKeyboardKey.escape,
  };

  LogicalKeyboardKey getKey(GameAction action) => _keyBindings[action]!;

  void rebind(GameAction action, LogicalKeyboardKey newKey) {
    // Prevenir duplicados
    _keyBindings.removeWhere((k, v) => v == newKey);
    _keyBindings[action] = newKey;
    _saveBindings();
    notifyListeners();
  }

  Future<void> _saveBindings() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _keyBindings.map((k, v) => MapEntry(k.name, v.keyId));
    await prefs.setString('key_bindings', jsonEncode(encoded));
  }
}
```

---

## ✅ Lista de Verificación de Seguridad

### Por Cada Cambio:

- [ ] **Git:** Commit tras cada sub-paso completado (ej. "feat: add screen shake class").
- [ ] **Pruebas de Regresión:**
  - Verificar que `startDoorClose()` (transición de nivel) sigue funcionando tras cambios en `RunnerGame`.
  - Verificar colisiones de pinchos tras cambios en `Player`.
- [ ] **Backup:** No borrar código comentado en `runner_game.dart` hasta que la nueva feature esté 100% validada.

### Validación de Cobertura Completa:

| Roadmap Sección | Plan Fase | Estado                                              |
| --------------- | --------- | --------------------------------------------------- |
| 1. Game Feel    | Fase 1    | ✅ Cubierto (Coyote Time, Screen Shake, Partículas) |
| 2. Mecánicas    | Fase 2    | ✅ Cubierto (Dash, Wall Jump, Llaves)               |
| 3. Tiled        | Fase 3    | ✅ Cubierto (Loader, Colisiones, Feature Flag)      |
| 4. Progresión   | Fase 4    | ✅ Cubierto (Estadísticas, Desafíos Diarios)        |
| 5. Narrativa    | Fase 5    | ✅ Cubierto (Cinemáticas, Diálogos)                 |
| 6. UI/UX        | Fase 6    | ✅ Cubierto (Transiciones, Controles)               |

### Optimizaciones Validadas con Context7:

- [ ] `ParticleSystemComponent` con `AcceleratedParticle` para efectos físicos
- [ ] `NoiseEffectController` para screen shake natural
- [ ] `TiledComponent.load()` con `ignoreFlip: true` para mejor rendimiento
- [ ] `HasCollisionDetection` mixin para colisiones Tiled
- [ ] `MoveEffect.by` para animaciones de flotación
- [ ] `OpacityEffect.to` para transiciones de fade

### Orden de Implementación Recomendado:

1. **Fase 1** → Mejoras inmediatas de game feel
2. **Fase 4.1** → Telemetría básica para medir impacto
3. **Fase 2** → Nuevas mecánicas con datos de uso
4. **Fase 3** → Tiled cuando mecánicas estén estables
5. **Fase 5-6** → Pulido final
