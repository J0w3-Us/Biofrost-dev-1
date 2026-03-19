# Kiosco de Proyectos — Product Design Document

> Documento de especificación técnica completo para una plataforma de evaluación de proyectos estudiantiles.
> Stack: Flutter (Dart) · C# .NET · PostgreSQL/Supabase
> Arquitectura: CQRS · Clean Architecture · BLoC/Riverpod

---

## Contexto General

**Propósito:** Plataforma tipo kiosco digital para que evaluadores (docentes y visitantes) exploren y califiquen proyectos estudiantiles mediante un sistema de estrellas (1–5) y retroalimentación textual.

**Roles:**
- `visitor` — Navega la galería, ve detalles, no puede evaluar
- `teacher` — Todo lo anterior + puede evaluar proyectos + tiene perfil con KPIs
- `admin` — Gestión completa (futuro)

---

## 1. User Journey Map

### Paso 1 — Splash Screen (App Launch)
- Duración máxima: 2 segundos
- Ejecuta verificación de sesión en background
- Lee token de `flutter_secure_storage`
- Verifica expiración del JWT
- **Si token válido:** redirige a `/showcase`
- **Si token inválido o ausente:** redirige a `/login`

### Paso 2 — Auth Guard (Middleware Global)
- Se ejecuta en cada navegación via `GoRouter` + callback `redirect`
- **Rutas públicas:** `/showcase`, `/ranking`, `/project/:id`
- **Rutas protegidas:** `/profile`, acciones de evaluación
- Lógica de refresh: `401 → POST /auth/refresh → retry automático`
- Error `403`: Toast "Sin permisos" + redirect a `/showcase`

### Paso 3 — Autenticación (`/login`)
- Un solo widget con modo dual: **Login** y **Registro**
- Transición animada entre modos (slide + fade)
- Validación reactiva campo a campo con BLoC + FormValidator
- **Error de validación de negocio:** texto rojo debajo del campo específico
- **Error de red:** SnackBar con botón "Reintentar"
- Flujo exitoso:
  1. `POST /auth/login` con email + contraseña
  2. Recibe `access_token` + `refresh_token`
  3. Guarda en `flutter_secure_storage`
  4. Redirige a `/showcase` con Hero transition
- **Guard:** Si ya está autenticado e intenta ir a `/login` → redirige a `/showcase`

### Paso 4 — Dashboard (`/showcase`)
- Vista principal: grid responsivo de `ProjectCard` widgets
- Búsqueda full-text con debounce de 300ms
- Filtros: categoría, año, estado
- **Caché:** Stale-While-Revalidate — carga desde caché local (Hive/SQLite) instantáneamente, revalida en background via `GET /projects`
- Skeleton loaders durante fetch inicial
- Infinite scroll con paginación cursor-based
- Pull-to-refresh fuerza revalidación del caché

### Paso 5 — Detalle de Proyecto (`/project/:id`)
- Hero animation desde `ProjectCard`
- Secciones: info general, equipo, stack tecnológico, Business Canvas (read-only), videos embebidos
- Botón de compartir via dynamic link
- `RatingBottomBar` visible para todos los usuarios (DraggableScrollableSheet)
- `EvaluationSection` visible **únicamente** para docentes autenticados (AuthGuard)

### Paso 6 — Evaluación (Flujo Command)
- Docente selecciona estrellas 1–5 con feedback háptico (`HapticFeedback.selectionClick()`)
- Escribe retroalimentación textual (opcional)
- **Modal de confirmación** antes de enviar (muestra resumen: puntuación + nombre del proyecto)
- **Optimistic Update:** UI actualiza inmediatamente
- Si backend retorna error → rollback automático + Toast de error
- Si éxito → Toast de éxito + ranking recalculado en tiempo real (WebSocket)

### Perfil del Docente (`/profile`)
- Accesible solo cuando autenticado
- Contiene: datos personales, KPIs, proyectos supervisados, historial de evaluaciones
- Opción de editar perfil y foto
- Botón de cerrar sesión → limpia token → redirige a `/login`
- Tap en proyecto supervisado → navega a `/project/:id`

### Barra de Navegación Inferior
| Rol | Tab 1 | Tab 2 | Tab 3 |
|-----|-------|-------|-------|
| Visitante | Inicio (`/showcase`) | Ranking (`/ranking`) | Entrar (`/login`) |
| Docente autenticado | Inicio (`/showcase`) | Ranking (`/ranking`) | Perfil (`/profile`) |

---

## 2. Lógica de Evaluación

### 2.1 Anti-Duplicados — UPSERT Strategy

La constraint `UNIQUE(evaluator_id, project_id)` en la tabla `evaluations` garantiza a nivel de base de datos que un evaluador solo puede tener **una evaluación por proyecto**.

El endpoint usa `ON CONFLICT DO UPDATE` para actualizar la calificación existente si ya existe (permite que el docente corrija su voto, no lo rechaza).

```sql
-- PostgreSQL UPSERT
INSERT INTO evaluations
  (evaluator_id, project_id, stars, feedback)
VALUES (@EvalId, @ProjId, @Stars, @Fb)
ON CONFLICT (evaluator_id, project_id)
DO UPDATE SET
  stars      = EXCLUDED.stars,
  feedback   = EXCLUDED.feedback,
  updated_at = NOW();
```

**Toast de advertencia** al detectar evaluación previa: *"Ya evaluaste este proyecto. Tu calificación anterior será reemplazada."*

### 2.2 Cálculo de Promedio — Vista Materializada

El promedio se calcula con una Vista Materializada que se refresca automáticamente tras cada INSERT/UPDATE en `evaluations` via trigger. El endpoint `GET /ranking` solo lee la vista (sin costo computacional en el request).

```sql
-- Vista materializada de ranking
CREATE MATERIALIZED VIEW project_ranking AS
SELECT
  p.id,
  p.title,
  p.category_id,
  ROUND(AVG(e.stars), 2)  AS avg_score,
  COUNT(e.id)             AS total_votes,
  RANK() OVER (
    ORDER BY AVG(e.stars) DESC,
             COUNT(e.id)  DESC  -- desempate por cantidad de votos
  ) AS rank_position
FROM projects p
LEFT JOIN evaluations e ON e.project_id = p.id
GROUP BY p.id;

-- Trigger para refrescar automáticamente
CREATE OR REPLACE FUNCTION refresh_ranking()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY project_ranking;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_refresh_ranking
AFTER INSERT OR UPDATE ON evaluations
FOR EACH ROW EXECUTE FUNCTION refresh_ranking();
```

**Regla de desempate:** igual `avg_score` → gana el de mayor `total_votes`. Esto incentiva que los proyectos busquen más evaluaciones, no solo puntajes altos.

### 2.3 Optimistic UI — Flutter / BLoC

```dart
on<SubmitEvaluationEvent>(
  (event, emit) async {
    // 1. Guarda estado previo
    final prev = state;

    // 2. Optimistic update inmediato
    emit(state.copyWith(
      stars: event.stars,
      status: EvalStatus.submitting,
    ));

    try {
      await _evalRepo.submit(event);
      emit(state.copyWith(status: EvalStatus.success));
    } catch (e) {
      // 3. Rollback automático
      emit(prev.copyWith(
        status: EvalStatus.error,
        errorMsg: e.message,
      ));
    }
  },
);
```

### 2.4 Tiempo Real — WebSocket (SignalR)

Cuando la vista materializada se refresca, el hub de SignalR notifica a todos los clientes conectados a `/ranking`. Flutter escucha el stream y actualiza la lista con animación de reordenamiento (`AnimatedList`).

```csharp
// C# / SignalR Hub
public class RankingHub : Hub {
  public async Task BroadcastUpdate(List<RankingDto> ranking) {
    await Clients.All.SendAsync("RankingUpdated", ranking);
  }
}
```

```dart
// Flutter - escucha el stream
Stream<List<RankingItem>> watchRanking() => _hub
  .on<List>('RankingUpdated')
  .map(RankingItem.fromJsonList);
```

---

## 3. Arquitectura de Datos

### 3.1 Entidad-Relación

```
users ──────< projects (supervisor_id)
users ──────< evaluations (evaluator_id)
projects ───< evaluations (project_id)
categories ─< projects (category_id)
```

**Cardinalidades:**
- 1 categoría → N proyectos
- 1 docente → N proyectos supervisados
- 1 usuario → N evaluaciones
- 1 proyecto → N evaluaciones
- UNIQUE(evaluator_id, project_id) → 1 evaluación por usuario por proyecto

### 3.2 DDL Completo — PostgreSQL

```sql
-- ENUM types
CREATE TYPE user_role       AS ENUM ('visitor', 'teacher', 'admin');
CREATE TYPE project_status  AS ENUM ('draft', 'active', 'archived');

-- USERS
CREATE TABLE users (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  email         VARCHAR(255)  NOT NULL UNIQUE,
  password_hash TEXT          NOT NULL,
  full_name     VARCHAR(200)  NOT NULL,
  role          user_role     NOT NULL DEFAULT 'visitor',
  avatar_url    TEXT,
  department    VARCHAR(100),
  is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  last_login    TIMESTAMPTZ
);

-- CATEGORIES
CREATE TABLE categories (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(100) NOT NULL UNIQUE,
  slug        VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  color_hex   CHAR(7),
  icon_name   VARCHAR(50),
  is_visible  BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- PROJECTS
CREATE TABLE projects (
  id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     UUID           NOT NULL REFERENCES categories(id),
  supervisor_id   UUID           REFERENCES users(id) ON DELETE SET NULL,
  title           VARCHAR(300)   NOT NULL,
  description     TEXT,
  team_members    JSONB          NOT NULL DEFAULT '[]',
  tech_stack      TEXT[]         NOT NULL DEFAULT '{}',
  canvas_data     JSONB,
  video_urls      TEXT[]         NOT NULL DEFAULT '{}',
  cover_image_url TEXT,
  status          project_status NOT NULL DEFAULT 'active',
  year            SMALLINT       NOT NULL,
  created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- EVALUATIONS
CREATE TABLE evaluations (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluator_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  project_id   UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  stars        SMALLINT    NOT NULL CHECK (stars BETWEEN 1 AND 5),
  feedback     TEXT,
  is_published BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ,
  CONSTRAINT unique_eval UNIQUE (evaluator_id, project_id)
);

-- INDEXES
CREATE INDEX idx_projects_category ON projects(category_id);
CREATE INDEX idx_projects_year     ON projects(year);
CREATE INDEX idx_projects_status   ON projects(status);
CREATE INDEX idx_evals_project     ON evaluations(project_id);
CREATE INDEX idx_evals_evaluator   ON evaluations(evaluator_id);
```

### 3.3 Dart Models (Flutter) — Null Safety

```dart
// ProjectReadModel — optimizado para UI de lista
class ProjectReadModel {
  final String id;
  final String title;
  final String? coverImageUrl;
  final String categoryName;
  final String categoryColorHex;
  final double avgScore;
  final int totalVotes;
  final int year;
  final ProjectStatus status;

  const ProjectReadModel({
    required this.id,
    required this.title,
    this.coverImageUrl,
    required this.categoryName,
    required this.categoryColorHex,
    required this.avgScore,
    required this.totalVotes,
    required this.year,
    required this.status,
  });

  factory ProjectReadModel.fromJson(Map<String, dynamic> json) =>
    ProjectReadModel(
      id:               json['id'] as String,
      title:            json['title'] as String,
      coverImageUrl:    json['coverImageUrl'] as String?,
      categoryName:     json['categoryName'] as String,
      categoryColorHex: json['categoryColorHex'] as String,
      avgScore:         (json['avgScore'] as num).toDouble(),
      totalVotes:       json['totalVotes'] as int,
      year:             json['year'] as int,
      status:           ProjectStatus.fromString(json['status'] as String),
    );
}

// EvaluationCommand — para operaciones de escritura
class EvaluationCommand {
  final String projectId;
  final int stars;       // 1-5
  final String? feedback;

  const EvaluationCommand({
    required this.projectId,
    required this.stars,
    this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'stars':     stars,
    if (feedback != null) 'feedback': feedback,
  };
}
```

### 3.4 C# DTOs (.NET Backend)

```csharp
// ProjectListItemDto — respuesta para GET /projects
public record ProjectListItemDto(
    Guid    Id,
    string  Title,
    string? CoverImageUrl,
    string  CategoryName,
    string  CategoryColorHex,
    double  AvgScore,
    int     TotalVotes,
    int     Year,
    string  Status
);

// EvaluationRequestDto — body para POST /evaluations
public record EvaluationRequestDto(
    Guid    ProjectId,
    [Range(1, 5)] int Stars,
    string? Feedback
);

// EvaluationResponseDto
public record EvaluationResponseDto(
    Guid        Id,
    Guid        ProjectId,
    int         Stars,
    string?     Feedback,
    bool        IsUpdate,      // true si reemplazó evaluación previa
    DateTime    CreatedAt,
    DateTime?   UpdatedAt
);
```

---

## 4. Componentes UI

### 4.1 Skeleton Loader
- **Widget Flutter:** `Shimmer` package sobre `ListView.builder` con items ficticios
- **Comportamiento:** Shimmer animation con gradiente izquierda → derecha
- **Reemplazo:** Automático cuando el `Future` resuelve (BLoC emite estado `loaded`)
- **Accesibilidad:** Envolver en `ExcludeSemantics` para que screen readers lo ignoren

### 4.2 RatingBottomBar
- **Widget Flutter:** `DraggableScrollableSheet` con `GestureDetector` en cada estrella
- **Estado:** Local `ValueNotifier<int>` (no necesita BLoC global)
- **Feedback:** `HapticFeedback.selectionClick()` solo al cambiar de valor
- **Label contextual:** Malo / Regular / Bueno / Muy bueno / Excelente
- **Accesibilidad:** `Semantics(label: '4 estrellas de 5')` en cada estrella
- **Incluye:** Campo de texto para retroalimentación + botón "Enviar evaluación"

### 4.3 Bottom Navigation Bar
- **Widget Flutter:** `NavigationBar` (Material 3)
- **Estado:** Stream del `AuthBloc`
- **Transición de rol:** `AnimatedSwitcher` entre "Entrar" y "Perfil"
- **Preservación de estado:** `IndexedStack` para que cada tab recuerde su posición de scroll
- **Accesibilidad:** `tooltip` con descripción del tab

### 4.4 Toast / Snackbar System

| Tipo | Trigger | Color borde | Acción |
|------|---------|-------------|--------|
| Éxito | Evaluación enviada | Verde | Auto-dismiss 4s |
| Error de red | Timeout / sin conexión | Rojo | Botón "Reintentar" |
| Advertencia | Evaluación duplicada | Dorado | Auto-dismiss 5s |
| Info | Ranking actualizado | Azul | Auto-dismiss 3s |

- **Widget Flutter:** `OverlayEntry` custom (no `ScaffoldMessenger` para más control)
- **Package recomendado:** `overlay_support`
- **Entrada:** Slide desde abajo con spring animation
- **Stack máximo:** 3 toasts simultáneos; el 4to desplaza al primero
- **Accesibilidad:** `Semantics(liveRegion: true)` para anuncio en screen readers

### 4.5 Modal de Confirmación
- **Widget Flutter:** `showDialog` + `BackdropFilter` con blur
- **Contenido:** Icono de estrella + nombre del proyecto + puntuación seleccionada
- **Acciones:** Cancelar (secundario) + Confirmar (primario con estrellas visuales)
- **Desestimable:** Tap fuera del modal o botón X
- **Accesibilidad:** `autofocus` en el botón primario al abrir

### 4.6 Ranking List
- **Widget Flutter:** `AnimatedList` para reordenamientos suaves
- **Actualización:** Stream WebSocket (SignalR) → BLoC → diff algorithm → solo anima los ítems que cambiaron
- **Medallones:** Top 3 con íconos 🥇🥈🥉
- **Barra de progreso:** Proporcional al líder (líder = 100%)
- **Accesibilidad:** Posición en ranking anunciada en screen reader

---

## 5. Endpoints API — Referencia

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/auth/login` | No | Login con email/password |
| POST | `/auth/register` | No | Registro nuevo usuario |
| POST | `/auth/refresh` | Refresh token | Renovar access token |
| GET | `/projects` | No | Lista paginada con filtros |
| GET | `/projects/:id` | No | Detalle de proyecto |
| GET | `/ranking` | No | Lee vista materializada |
| POST | `/evaluations` | Teacher | UPSERT evaluación |
| GET | `/profile` | Teacher | Datos + KPIs del docente |
| PATCH | `/profile` | Teacher | Editar datos / foto |

**Parámetros query para GET /projects:**
```
?q=texto          # búsqueda full-text
&category=slug    # filtro por categoría
&year=2025        # filtro por año
&page=cursor      # paginación cursor-based
&limit=20         # items por página
```

---

## 6. Decisiones Arquitectónicas CQRS

| Pantalla | Tipo | ReadModel / Command |
|----------|------|---------------------|
| `/showcase` | Query | `ProjectReadModel` |
| `/ranking` | Query | `RankingReadModel` |
| `/project/:id` | Query | `ProjectDetailReadModel` |
| `EvaluationSection` | Command | `EvaluationCommand` |
| `RatingBottomBar` | Command | `RatingCommand` |
| `/profile` (leer) | Query | `TeacherProfileReadModel` |
| `/profile` (editar) | Command | `UpdateProfileCommand` |

**Principio clave:** Nunca usar el mismo modelo de datos para una vista de lectura que para una operación de escritura. Los `ReadModels` están optimizados para la UI (desnormalizados, con campos calculados). Los `Command` son mínimos y representan la intención del usuario.

---

## 7. Manejo de Errores — Matriz UX

| Error | Origen | UX Response | Componente Flutter |
|-------|--------|-------------|-------------------|
| 400 — Validación | Backend | Texto rojo bajo el campo | `FormField` + error text |
| 401 — No autenticado | Guard | Redirect silencioso a `/login` | `GoRouter.redirect` |
| 403 — Sin permisos | Guard | Toast "Sin permisos" | Toast warning |
| 409 — Conflicto (duplicado) | Evaluaciones | Toast advertencia + modal "¿Reemplazar?" | Toast + Dialog |
| 422 — Datos inválidos | Negocio | Texto rojo + descripción | Inline error |
| 500 — Server error | Servidor | SnackBar "Error del servidor. Intenta más tarde." | SnackBar |
| Timeout / Red | Red | SnackBar "Sin conexión" + botón Reintentar | SnackBar + action |
| Token expirado | Auth | Refresh automático invisible | Interceptor HTTP |

---

## 8. Notas de Escalabilidad

- **Caché:** Vista materializada de ranking desacopla el costo computacional. Para >10k proyectos, evaluar Redis para caché de lista.
- **Paginación:** Cursor-based (no offset) para listas grandes sin degradación de performance.
- **WebSocket:** SignalR con fallback a long-polling para redes restrictivas.
- **Imágenes:** Almacenar en Supabase Storage o S3; usar CDN para cover images.
- **Search:** Para >1k proyectos considerar `pg_trgm` o migrar a Elasticsearch.
- **Multi-tenancy futuro:** El campo `year` en proyectos permite filtrar por edición. `categories` permite expandir a múltiples tipos de kiosco.
