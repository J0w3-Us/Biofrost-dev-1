# Biofrost — Arquitectura y Funcionalidades

> **Versión:** 1.0.0+1 · **Flutter** 3.38.3 · **Dart** 3.10.1  
> **Backend:** IntegradorHub API (.NET) — `https://integradorhub.onrender.com`  
> **Plataformas objetivo:** Android (primario), Windows (secundario)

---

## 1. Propósito del Proyecto

Biofrost es la **aplicación móvil oficial de IntegradorHub** — plataforma académica de la Universidad Tecnológica de la Mixteca (UTM). Permite a **Docentes**, **Evaluadores** y **Visitantes** consultar, calificar y compartir proyectos integradores de los alumnos de la carrera de Desarrollo de Software Multiplataforma (DSM).

### Audiencia objetivo

| Rol | Descripción | Acceso |
|---|---|---|
| **Docente** | Maestro titular de grupo. Crea evaluaciones oficiales con calificación 0-100, gestiona visibilidad, ve proyectos de su grupo, actualiza su perfil. | Autenticado (Firebase Auth) |
| **Evaluador** | Juez externo invitado para eventos. Puede enviar evaluaciones de tipo `sugerencia`. | Autenticado |
| **Visitante (Invitado)** | Persona sin cuenta o con sesión de invitado. Puede navegar el showcase, ver detalle y enviar comentarios. | Anónimo / Sesión invitado |

---

## 2. Arquitectura General

```
biofrost/lib/
├── bootstrap.dart              ← VGV pattern: inicialización centralizada
├── main.dart                   ← Producción (FLAVOR=production)
├── main_development.dart       ← Desarrollo local (FLAVOR=development)
├── main_staging.dart           ← Staging/Render (FLAVOR=staging)
│
├── core/                       ← Infraestructura compartida
│   ├── config/                 ← AppConfig, AppEnvironment, ApiEndpoints
│   ├── router/                 ← GoRouter + guards de auth
│   ├── theme/                  ← AppTheme (colores, tipografía, radios)
│   ├── services/               ← ApiService (Dio), ConnectivityService, DatabaseService, AnalyticsService
│   ├── notifications/          ← NotificationService (FCM + local)
│   ├── deeplinks/              ← DeepLinkService (app_links)
│   ├── cache/                  ← CacheService (SharedPreferences)
│   ├── providers/              ← themeProvider
│   ├── errors/                 ← AppException sealed class hierarchy
│   ├── models/                 ← Modelos compartidos del core
│   ├── widgets/                ← ui_kit.dart, project_card.dart, offline_status_widget.dart
│   └── utils/                  ← sanitize.dart
│
└── features/
    ├── auth/                   ← Login, sesión, roles
    ├── showcase/               ← Galería de proyectos + filtros
    ├── project_detail/         ← Detalle de proyecto + votación
    ├── evaluations/            ← Formulario y panel de evaluaciones
    ├── ranking/                ← Tabla de ranking con podio
    ├── profile/                ← Perfil del Docente
    └── sharing/                ← QR, PDF, compartir link/imagen
```

### Patrón arquitectónico

La app implementa **Clean Architecture + CQRS** por feature:

```
feature/
├── data/
│   ├── datasources/     ← Remote (Dio/API) + Local (SQLite/SharedPrefs)
│   └── repository.dart  ← Caché 3 capas: memoria → disco → red
├── domain/
│   ├── models/          ← ReadModels (Equatable, CQRS Query)
│   └── commands/        ← Command objects (CQRS Write)
├── providers/           ← Riverpod Notifiers (estado UI)
├── pages/               ← Consumer/ConsumerStateful Widgets
└── widgets/             ← Componentes de UI específicos del feature
```

---

## 3. Entornos y Configuración

| Entorno | Archivo | FLAVOR | API URL |
|---|---|---|---|
| Desarrollo | `.env.development` | `development` | `http://10.0.2.2:5093` |
| Staging | `.env.staging` | `staging` | `https://integradorhub.onrender.com` |
| Producción | `.env.production` | `production` | `https://integradorhub.onrender.com` |

**`AppEnvironment`** (enum en `AppConfig`):
- `isDev` / `isStaging` / `isProd` — booleanos de entorno
- `showDebugBanner` — true solo en dev
- `appTitle` — incluye sufijo `[DEV]`/`[STAGING]` en entornos no productivos
- `_EnvBanner` — barra naranja (dev) o morada (staging) visible en la app

---

## 4. Autenticación y Roles

### Estados de sesión (`AuthState` — sealed class)

```dart
AuthStateLoading        // Verificando sesión inicial (splash)
AuthStateUnauthenticated // Sin sesión
AuthStateVisitor        // Sesión invitado (sin Firebase Auth)
AuthStateAuthenticated  // Docente/Evaluador/Admin autenticado
AuthStateError          // Error de autenticación
```

### Flujo de login

1. `LoginPage` → `AuthService.loginWithEmailAndPassword()`
2. Firebase Auth genera `idToken`
3. `ApiService` incluye el token en `Authorization: Bearer <token>` (interceptor automático)
4. `GET /api/users/{uid}/profile` → retorna `UserReadModel`
5. GoRouter redirige a `/showcase`

### Modelo de usuario (`UserReadModel`)

| Campo | Descripción | Disponible para |
|---|---|---|
| `userId` | Firebase UID | Todos |
| `email` | Correo registrado | Todos |
| `nombre` | Nombre de pila | Todos |
| `rol` | `Docente` / `Evaluador` / `Invitado` / `admin` / `SuperAdmin` | Todos |
| `nombreCompleto` | Computed: nombre + apellidos | Todos |
| `isDocente` | `rol == 'Docente'` | Guard de rutas |
| `isEvaluador` | `rol == 'Evaluador'` | Evaluaciones |
| `canEvaluate` | `isDocente \|\| isEvaluador \|\| isVisitante` | Panel evaluaciones |
| `grupoId` | ID del grupo asignado | Solo Alumno |
| `matricula` | Matrícula académica | Solo Alumno |
| `cedula` | Cédula profesional del docente | Solo Docente |
| `especialidadDocente` | Área de especialización | Solo Docente |
| `asignaciones` | Lista de `[{ carreraId, materiaId, gruposIds }]` | Solo Docente |
| `avatarUrl` | `fotoUrl` o generado por `ui-avatars.com` | Todos |

### Guards del Router

```
/showcase       → Público (todos)
/ranking        → Público (todos)
/project/:id    → Público (todos)
/login          → Redirige a /showcase si ya es Docente autenticado
/profile        → Solo AuthStateAuthenticated con isDocente == true
```

---

## 5. Features Implementadas

### 5.1 Showcase (Galería de Proyectos)

**Archivo principal:** `lib/features/showcase/pages/showcase_page.dart`

**Descripción:** Pantalla principal de la app. Muestra todos los proyectos públicos en una cuadrícula de 2 columnas.

**Capacidades:**
- Grid de proyectos con `SliverAppBar` + `NestedScrollView`
- Búsqueda en tiempo real con debounce de 300 ms
- Filtro por stack tecnológico (chips horizontales scrollables)
- Chip "Todos" para limpiar filtros
- Precarga de thumbnails con `precacheImage`
- Skeleton loading (6 tarjetas mientras carga)
- Banner offline (`OfflineBanner`) cuando no hay red
- Badge de caché con fecha de última actualización (`CacheAgeBadge`)
- Barra de navegación inferior contextual:
  - **Visitante:** Inicio / Ranking / `Entrar` (→ Login)
  - **Docente:** Inicio / Ranking / `Perfil` (→ /profile)

**Filtros disponibles:**
- Búsqueda libre por título, materia, stack, nombre del líder
- Filtro por stack tecnológico individual
- Ordenamiento implícito por `puntosTotales` (desc)

**Providers usados:**
- `showcaseProvider` (`ShowcaseNotifier`) — carga y filtra proyectos
- `authProvider` — determina opciones del nav bar

---

### 5.2 Detalle de Proyecto

**Archivo principal:** `lib/features/project_detail/pages/project_detail_page.dart`

**Descripción:** Vista completa de un proyecto: metadata, canvas (documento estructurado), equipo, video, evaluaciones y votación.

**Capacidades:**

#### Visualización
- Header con thumbnail, título, materia, ciclo, estado
- Stack tecnológico con chips de color
- Canvas estructurado (`_CanvasViewer`) con bloques:
  - `h1`, `h2`, `h3` — encabezados jerarquizados
  - `text` — párrafos con saltos de línea
  - `code` — bloque de código con fondo oscuro
  - `image` — imágenes con `CachedNetworkImage`
  - `table` — tabla con cabecera y filas
  - `video` — reproductor embebido (`_CanvasVideoCard`)
  - `link` — enlace abierto con `url_launcher`
- Lista de integrantes del equipo con badge `LÍDER`
- Video de presentación con reproductor Chewie + controles completos

#### Votación (Docente)
- Panel de votación con `StarRating` (1-5 estrellas)
- Confirmación antes de enviar (`_VoteConfirmSheet`)
- Advertencia si ya existe voto previo (reemplazo)
- Actualización optimistic del puntaje visible
- Solo disponible para usuarios `canEvaluate`

#### Evaluaciones
- Panel `EvaluationPanelWidget` con:
  - Lista de evaluaciones públicas ordenadas por fecha
  - Distinct visual entre `sugerencia` y evaluación `oficial` (con calificación)
  - Toggle de visibilidad (solo Docente propietario)
  - Botón `+ Nueva evaluación` (abre `EvaluationFormPage`)

#### Edición de video (Docente)
- `_VideoEditSection` en la parte inferior
- Dialog para actualizar URL del video
- `PATCH /api/projects/{id}/video-url`

---

### 5.3 Evaluaciones

**Archivos:**
- `lib/features/evaluations/pages/evaluation_form_page.dart`
- `lib/features/evaluations/data/evaluation_repository.dart`
- `lib/features/evaluations/providers/evaluation_provider.dart`

**Tipos de evaluación:**

| Tipo | Descripción | Quién puede crear | Calificación |
|---|---|---|---|
| `sugerencia` | Comentario/feedback público | Docente, Evaluador, Visitante | No |
| `oficial` | Evaluación formal con nota | Solo Docente titular o Admin | 0 – 100 |

**Formulario (`EvaluationFormPage`):**
- Selector de tipo: `sugerencia` / `oficial`
- Campo de texto para contenido (validación no vacío)
- Slider de calificación 0-100 (solo visible en tipo `oficial`)
- Soporte offline: guarda en SQLite si no hay red, sincroniza automáticamente al recuperar conexión
- Banner de estado de conexión (`OfflineStatusWidget`)

**`EvaluationPanelState` (Riverpod):**
- `evaluations` — lista ordenada por fecha desc
- `isLoading` / `isSubmitting` — estados de carga
- `currentGrade` — calificación oficial más reciente del proyecto
- `isFormValid` — validación reactiva del formulario

**Operaciones CQRS:**

| Operación | Endpoint | Método |
|---|---|---|
| Cargar evaluaciones | `GET /api/evaluations/project/{id}` | Query |
| Crear evaluación | `POST /api/evaluations` | Command |
| Toggle visibilidad | `PATCH /api/evaluations/{id}/visibility` | Command + Optimistic Update |

**Caché en memoria:** TTL por proyecto. Fallback a datos stale cuando hay error de red.

---

### 5.4 Ranking

**Archivo:** `lib/features/ranking/pages/ranking_page.dart`

**Descripción:** Tabla de mejores proyectos ordenados por `puntosTotales`.

**Capacidades:**
- Podio visual para los 3 primeros lugares (posiciones 1-3 con altura diferente)
- Tabla para posiciones 4-20
- Actualización pull-to-refresh
- Tapping en proyecto → navega a `/project/:id`
- Avatares de líderes con `BioAvatar`

**Provider:** `rankingProvider` (`RankingNotifier`) — llama `GET /api/projects/public` y ordena por puntos.

---

### 5.5 Perfil del Docente

**Archivo:** `lib/features/profile/pages/profile_page.dart`

**Ruta:** `/profile` — **solo accesible para Docentes autenticados**

**Capacidades:**
- Header con foto de perfil, nombre completo, email, rol
- Cambio de foto de perfil:
  - Selección de galería o cámara (`image_picker`)
  - Recorte circular (`image_cropper` con `CropStyle.circle`)
  - Upload a Firebase Storage / Supabase
- Cambio de tema claro/oscuro (`themeProvider`)
- Sección de proyectos asignados (`ProfileProjectsProvider`):
  - Lista de proyectos del grupo del docente
  - Navigation a detalle de cada uno
- Sección de evaluaciones previas del docente
- Cerrar sesión (limpia estado de auth + navega a login)
- Barra de navegación inferior (Inicio / Ranking / **Perfil** seleccionado)

---

### 5.6 Compartir Proyectos

**Archivos:** `lib/features/sharing/`

#### Link + texto (`SharingService.shareProjectLink`)
- Genera texto con título, materia, ciclo, stack preview
- Incluye deep link `biofrost://project/{id}` y URL web `https://biofrost.utm.mx/project/{id}`
- Usa `share_plus`

#### Tarjeta de imagen (`ProjectCardCapture`)
- Bottom sheet que renderiza una tarjeta visual del proyecto
- Captura con `screenshot` → `ScreenshotController`
- Acciones: compartir imagen o guardar en galería (`gal`)
- `_ShareableCard`: título, materia/ciclo, stack chips, avatares del equipo, URL de pie de página

#### Código QR (`QrModal`)
- Modal con `QrImageView` (200px, error correction H, logo embebido)
- Captura QR como imagen (pixelRatio: 3.0)
- Acciones: guardar en galería o compartir imagen

#### Exportar PDF (`ProjectPdfExporter`)
- `Printing.layoutPdf()` → PDF descargable/compartible
- Contenido: header con QR embebido, sección stack, sección equipo, docente responsable, pie de página
- Usa `pdf` + `printing` packages

---

## 6. Infraestructura Core

### 6.1 ApiService (Dio)

**Archivo:** `lib/core/services/api_service.dart`

- Base URL configurable por entorno (`AppConfig.apiBaseUrl`)
- Interceptor `_AuthInterceptor`: agrega `Authorization: Bearer <idToken>` en todas las peticiones (obtiene token fresco de Firebase Auth)
- Interceptor `_ErrorInterceptor`: mapea errores HTTP a `AppException` sealed classes:
  - `401` → `AuthException`
  - `403` → `ForbiddenException`
  - `404` → `NotFoundException`
  - `422` → `BusinessException`
  - `5xx` → `ServerException`
  - Sin red → `NetworkException`
- Timeout: 30s conexión / 30s recepción

### 6.2 Sistema de Caché (3 capas)

```
Prioridad: Memoria > Disco > Red

1. Memory cache  (_CacheEntry<T> con TTL en el Notifier/Repository)
2. Disk cache    (SharedPreferences via CacheService — TTL configurable)
3. Network       (Dio → backend)

Fallback offline: datos stale (disco) si falla la red
```

### 6.3 ConnectivityService

**Archivo:** `lib/core/services/connectivity_service.dart`

- Singleton que escucha cambios de red con `connectivity_plus`
- `isOnline` — getter sincrónico
- `RetryScheduler` — reintenta operaciones fallidas cuando vuelve la red (usado en `ShowcaseNotifier` para refrescar proyectos)
- `ConnectivityNotifier` — provider Riverpod que expone el estado bool

### 6.4 DatabaseService (SQLite offline)

**Archivo:** `lib/core/services/database_service.dart`

- Base de datos local con `sqflite`
- **Evaluaciones offline:**
  - `saveEvaluationOffline(command)` — guarda en tabla local cuando no hay red
  - `getPendingEvaluations(projectId)` — recupera evaluaciones no sincronizadas
  - `markEvaluationsSynced(ids)` — marca como sincronizadas
  - `deleteSyncedEvaluations()` — limpia evaluaciones ya enviadas

### 6.5 NotificationService (FCM)

**Archivo:** `lib/core/notifications/notification_service.dart`

- Firebase Cloud Messaging (FCM) para notificaciones push
- Canal Android: `biofrost_evaluations` — "Evaluaciones y actualizaciones de proyectos"
- Notificaciones locales con `flutter_local_notifications`
- Badge counter en iOS
- `NotificationNotifier` → `notificationProvider`: expone ruta de navegación pendiente al abrir notificación

### 6.6 DeepLinkService

**Archivo:** `lib/core/deeplinks/deep_link_service.dart`

- Esquema: `biofrost://project/{id}`
- `app_links` para capturar deep links entrantes
- `DeepLinkNotifier` → `deepLinkProvider`: `BiofrostApp` escucha y navega automáticamente al proyecto

### 6.7 AnalyticsService

**Archivo:** `lib/core/services/analytics_service.dart`

- Tracking de eventos de uso
- Incluye contador de evaluaciones enviadas por tipo (`sugerencia` / `oficial`)

---

## 7. Navegación (GoRouter)

```
/                   → (initial) redirect según authState
/login              → LoginPage
  └─ redirect: si AuthStateAuthenticated → /showcase
/showcase           → ShowcasePage (público)
/ranking            → RankingPage (público)
/project/:id        → ProjectDetailPage (público, id = projectId)
/profile            → ProfilePage (🔒 solo Docente autenticado)
  └─ redirect: si !isDocente → /login
```

El guard reactivo `_AuthRouterNotifier extends ChangeNotifier` escucha `authProvider` y re-evalúa redirects en cada cambio de sesión.

---

## 8. Modelos de Dominio

### `ProjectReadModel`

```dart
id, titulo, materia, estado, stackTecnologico,
liderNombre, liderId, liderFotoUrl,
docenteId, docenteNombre,
ciclo, puntosTotales, conteoVotos,
votantes (Map<String, int>),     // uid → calificación
esPublico, videoUrl, videoFilePath,
createdAt, grupoId, thumbnailUrl, descripcion

// Computed:
stackPreview    → primeros 3 del stack
stackOverflow   → cantidad extra (si >3)
estadoColor     → Color según estado ('En progreso', 'Completado', etc.)
```

### `ProjectDetailReadModel`

Extiende `ProjectReadModel` con:
```dart
canvas          → List<CanvasBlock> (bloques estructurados del documento)
equipo          → List<TeamMember> (con nombre, matrícula, esLider, fotoUrl)
evaluaciones    → List<EvaluationReadModel>
```

### `EvaluationReadModel`

```dart
id, projectId, docenteId, docenteNombre,
tipo ('sugerencia' | 'oficial'),
contenido, esPublico,
calificacion (0-100, solo si tipo == 'oficial'),
createdAt

// Computed:
isOficial / isSugerencia
hasGrade
calificacionDisplay    → "85" o "85.5"
fechaFormateada        → "12/3/2026 14:30"
```

---

## 9. Endpoints API consumidos

| Endpoint | Método | Descripción | Auth |
|---|---|---|---|
| `/auth/login` | POST | Login Firebase UID | No |
| `/users/{uid}/profile` | GET | Perfil del usuario | Sí |
| `/projects/public` | GET | Todos los proyectos públicos | No |
| `/projects/group/{grupoId}` | GET | Proyectos del grupo | Sí |
| `/projects/teacher/{teacherId}` | GET | Proyectos supervisados | Sí |
| `/projects/{id}` | GET | Detalle de proyecto | No |
| `/projects/{id}/video-url` | PATCH | Actualizar URL de video | Sí (Docente) |
| `/projects/{id}/rate` | POST | Calificar proyecto (1-5) | Sí |
| `/evaluations/project/{id}` | GET | Evaluaciones de un proyecto | Sí |
| `/evaluations` | POST | Crear evaluación | Sí |
| `/evaluations/{id}/visibility` | PATCH | Toggle visibilidad | Sí (Docente) |
| `/teams/available-students` | GET | Alumnos disponibles | Sí |

---

## 10. Stack Tecnológico

### State Management
- **flutter_riverpod 2.6.1** — Notifiers, FutureProviders, StateNotifiers

### Navegación
- **go_router 14.3.0** — Rutas declarativas con guards reactivos

### Red
- **dio 5.7.0** — HTTP client con interceptores
- **connectivity_plus 6.1.0** — Detección de red

### Firebase
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`

### Almacenamiento local
- **shared_preferences 2.5.4** — Caché ligera (json strings)
- **flutter_secure_storage 9.2.2** — Tokens seguros
- **sqflite** — Base de datos local para evaluaciones offline

### Multimedia
- **video_player 2.11.0** + **chewie 1.13.0** — Reproductor de video
- **image_picker 1.2.1** — Cámara / galería
- **image_cropper 9.1.0** — Recorte de imágenes (circular para perfil)
- **cached_network_image 3.4.1** — Imágenes en red con caché

### Compartir y exportar
- **share_plus 12.0.1** — Compartir texto, archivos, imágenes
- **screenshot 3.0.0** — Captura de widgets como imagen
- **gal 2.3.2** — Guardar en galería del dispositivo
- **qr_flutter 4.1.0** — Generación de QR
- **pdf 3.11.3** + **printing 5.14.2** — Exportación a PDF

### UI
- **shimmer 3.0.0** — Skeleton loaders
- **equatable 2.0.7** — Modelos comparables
- **intl 0.19.0** — Formateo de fechas/números
- **supabase_flutter 2.9.0** — Almacenamiento alternativo de media

### Deep Links y URLs
- **app_links 6.4.1** — Scheme `biofrost://`
- **url_launcher 6.3.1** — Abrir URLs externas

---

## 11. UI Kit Compartido (`lib/core/widgets/ui_kit.dart`)

| Widget | Descripción |
|---|---|
| `BioButton` | Botón con variantes `primary`, `secondary`, `ghost`; soporta estado de carga |
| `BioInput` | Campo de texto con label flotante, prefixIcon, validación |
| `BioAvatar` | Avatar circular con fallback a iniciales (`_InitialsFallback`) |
| `UserAvatar` | Avatar que puede mostrar foto de perfil o generado |
| `BioChip` | Chip de filtro/categoría, estado activo/inactivo |
| `StatusBadge` | Badge con color según estado del proyecto |
| `BioCard` | Contenedor con borde y radio estándar |
| `BioSkeleton` | Animación shimmer para skeleton loading |
| `ProjectCardSkeleton` | Skeleton específico para tarjeta de proyecto |
| `BioErrorView` | Vista de error con mensaje y botón de reintentar |
| `BioEmptyView` | Vista de estado vacío con ícono y mensaje |
| `BioDivider` | Divisor con padding estándar |
| `OfflineBanner` | Barra amarilla "Sin conexión" con ícono |
| `CacheAgeBadge` | Pequeño badge con hora de última actualización del caché |

---

## 12. Manejo de Errores

```dart
sealed class AppException
├── NetworkException     // Sin red / timeout
├── AuthException        // 401 — token inválido o expirado
├── ForbiddenException   // 403 — sin permisos
├── NotFoundException    // 404 — recurso no encontrado
├── BusinessException    // 422 — validación de negocio (con campo opcional)
├── ServerException      // 5xx — error interno del servidor
└── CancelledException   // Petición cancelada (dispose)
```

Los Notifiers y Repositories capturan `AppException` y lo exponen en el estado como `error: AppException?`. Los widgets muestran `BioErrorView` con mensaje amigable y botón de reintento.

---

## 13. Environments y DevOps

### Comandos de lanzamiento (VS Code)

| Config | Descripción |
|---|---|
| 🚀 Biofrost Production | `--dart-define-from-file=.env.production --no-pub` |
| 🔬 Biofrost Staging | `--dart-define-from-file=.env.staging --no-pub` |
| 🛠 Development (Emulador) | `--dart-define-from-file=.env.development --no-pub` |
| 🛠 Development (Localhost) | `--dart-define FLAVOR=development API_BASE_URL=... --no-pub` |

### Android
- **Gradle:** 8.9
- **AGP:** 8.7.0
- **Kotlin:** 2.0.21
- **minSdk:** 23 (Android 6.0)
- **targetSdk:** 34 (Android 14)

### Nota SSL
En redes corporativas con proxy HTTPS, `flutter pub get` puede fallar por certificado autofirmado. Solución: `--no-pub` en todos los configs de launch para omitir el paso de pub en tiempo de run.

---

## 14. Funcionalidades Pendientes / En Progreso

| Funcionalidad | Estado | Notas |
|---|---|---|
| Login en dispositivo real | ⏳ No probado | Configuración completada, pendiente de primera ejecución exitosa |
| Video playback en dispositivo | ⏳ No probado | API compatible (`chewie 1.13.0` + `video_player 2.11.0`) |
| Image picker/cropper en Android | ⏳ No probado | API `AndroidUiSettings`/`IOSUiSettings` confirmada en `profile_page.dart` |
| Sincronización offline de evaluaciones | ✅ Implementado | `DatabaseService` + `RetryScheduler` |
| Notificaciones push | ✅ Implementado | FCM configurado, canal `biofrost_evaluations` |
| Deep links | ✅ Implementado | Esquema `biofrost://project/{id}` |
| Exportar PDF | ✅ Implementado | `ProjectPdfExporter` con QR embebido |
| Registro de nuevos Docentes | 🔲 No iniciado | Endpoint `POST /auth/register` existe en `ApiEndpoints` |
| Panel Admin en app | 🔲 No iniciado | Solo en IntegradorHub web |
