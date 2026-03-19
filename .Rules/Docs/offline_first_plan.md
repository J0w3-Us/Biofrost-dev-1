# 🏗️ Plan Arquitectónico — Biofrost Offline-First (Fase 1)
### *La Base de Datos Local como Única Fuente de la Verdad*

---

## 📊 Diagnóstico del Estado Actual

Antes de diseñar, es crítico entender **exactamente dónde estamos hoy**:

| Componente | Archivo actual | Estado |
|---|---|---|
| BD Local | [core/cache/cache_database.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_database.dart) | ✅ Ya existe (SQLite/sqflite) |
| Política de caché | [core/cache/cache_policy.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_policy.dart) | ✅ Ya existe (15 / 30 min TTL) |
| Caché en detalle | [project_detail_remote_datasource.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/data/datasources/project_detail_remote_datasource.dart) | ⚠️ Mezclado con lógica remota |
| Caché en showcase | [showcase_remote_datasource.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/showcase/data/datasources/showcase_remote_datasource.dart) | ❌ **NO implementado** — llama directo a API |
| Patrón Repositorio | `*/data/datasources/` | ⚠️ Solo existe el datasource *remoto* (no hay contrato abstracto) |
| Providers | [ProjectDetailNotifier](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/providers/project_detail_provider.dart#63-180), [ShowcaseNotifier](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/showcase/providers/showcase_provider.dart#96-186) | ⚠️ Hablan *directamente* con el datasource remoto |

> **Conclusión del diagnóstico:** La infraestructura de BD ya existe pero está subutilizada.
> El problema arquitectónico real es que **no existe una capa Repositorio** que actúe como
> mediador y que garantice que la UI *siempre* lea de SQLite. El Datasource remoto
> contiene lógica de caché mezclada con lógica de red — violando el Principio de
> Responsabilidad Única (SRP).

---

## 1. Estructura de Capas Target

### Diagrama de Dependencias

```
┌─────────────────────────────────────────────────────┐
│                      UI (Widgets)                    │
│             project_detail_page.dart, etc.           │
└──────────────────────┬──────────────────────────────┘
                       │ watch / read
                       ▼
┌─────────────────────────────────────────────────────┐
│               State Layer (Riverpod)                 │
│  ProjectDetailNotifier  │  ShowcaseNotifier          │
│  — Lee SOLO del Repositorio Local                    │
│  — Dispara sincronización en background              │
└──────────┬──────────────────────┬───────────────────┘
           │ lee                  │ llama
           ▼                      ▼
┌─────────────────────┐  ┌───────────────────────────┐
│  LOCAL REPOSITORY   │  │   REMOTE REPOSITORY       │
│  (Nueva capa)       │  │   (Nueva capa)             │
│                     │  │                            │
│  Lee / escribe      │  │  Fetch de API con Dio      │
│  exclusivamente en  │  │  Sin lógica de caché       │
│  SQLite             │  │  Solo lanza excepciones    │
│                     │  │  en caso de error          │
└──────────┬──────────┘  └──────────┬────────────────┘
           │                        │ escribe en SQLite
           └────────────┬───────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│              CacheDatabase (SQLite)                  │
│              core/cache/cache_database.dart          │
│     ✅ Ya existe — se amplía mínimamente             │
└─────────────────────────────────────────────────────┘
```

### Responsabilidades por Capa

#### `LocalRepository` (nueva capa — la más importante)
- **ÚNICA interfaz** con [CacheDatabase](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_database.dart#8-121)
- Operaciones: `watchDetail(id)`, `watchProjects()`, `saveDetail()`, `saveProjects()`, [clearAll()](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_database.dart#114-120)
- Devuelve `Stream<T>` para que el Notifier reaccione reactivamente
- **Nunca** toca Dio ni conoce la red

#### `RemoteRepository` (refactorización del Datasource actual)
- **ÚNICA interfaz** con [Dio](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/services/api_service.dart#44-73)
- Solo hace fetch y devuelve el `Map<String, dynamic>` crudo o el modelo deserializado
- **Nunca** escribe en SQLite directamente (delega al Notifier o a un SyncService)
- Contiene el **Patrón Adaptador** existente (serialización de evaluaciones) — se preserva íntegro

#### [ProjectDetailNotifier](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/providers/project_detail_provider.dart#63-180) / [ShowcaseNotifier](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/showcase/providers/showcase_provider.dart#96-186) (orquestadores)
- Observan el `LocalRepository` via `Stream`
- En el [build()](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/providers/project_detail_provider.dart#65-69) disparan una sincronización en background con el `RemoteRepository`
- En caso de error de red, la UI ya tiene datos del stream local — no se rompe nada

---

## 2. Estructura de Archivos a Crear/Modificar

```
lib/
├── core/
│   └── cache/
│       ├── cache_database.dart         ← AMPLIAR (agregar streams)
│       └── cache_policy.dart           ← Sin cambios
│
├── features/
│   ├── project_detail/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── project_detail_remote_datasource.dart  ← REFACTORIZAR
│   │   │   └── repositories/                              ← NUEVO DIRECTORIO
│   │   │       ├── project_detail_local_repository.dart   ← CREAR
│   │   │       └── project_detail_remote_repository.dart  ← CREAR
│   │   └── providers/
│   │       └── project_detail_provider.dart               ← REFACTORIZAR
│   │
│   └── showcase/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── showcase_remote_datasource.dart         ← REFACTORIZAR
│       │   └── repositories/                               ← NUEVO DIRECTORIO
│       │       ├── showcase_local_repository.dart          ← CREAR
│       │       └── showcase_remote_repository.dart         ← CREAR
│       └── providers/
│           └── showcase_provider.dart                      ← REFACTORIZAR
```

---

## 3. Flujo de Lectura — Pantalla [ProjectDetail](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/data/datasources/project_detail_remote_datasource.dart#16-92)

### Escenario A: Usuario CON internet

```
1. Navegación → GoRouter crea/reactiva ProjectDetailNotifier(projectId)

2. build() ejecuta sincrónicamente:
   a. state = ProjectDetailState(isLoading: true)
   b. Suscribe al Stream del LocalRepository:
      localRepo.watchDetail(projectId).listen(onLocalData)
   c. Dispara _syncFromRemote(projectId) en background (no awaited)
   
3. _syncFromRemote() en background:
   a. Llama a RemoteRepository.fetchDetail(projectId)
   b. Hace el fetch paralelo (proyectos + evaluaciones) — misma lógica actual
   c. Escribe el resultado en CacheDatabase (SQLite) vía LocalRepository.saveDetail()
   d. NO actualiza state directamente

4. SQLite emite cambio → el Stream del LocalRepository emite nuevo valor

5. onLocalData() recibe el nuevo modelo:
   a. state = state.copyWith(project: model, isLoading: false, fromCache: false)

6. UI reconstruye con datos frescos ✅
```

### Escenario B: Usuario SIN internet (datos en caché)

```
1-2. Igual que escenario A (isLoading: true, stream suscrito, sync disparado)

3. _syncFromRemote() falla con NetworkException
   a. state = state.copyWith(isLoading: false, fromCache: true)
   b. NO lanza el error (es un fallo de sincronización, no de lectura)

4. El Stream de SQLite YA emitió el dato cacheado en el paso 2b
   → onLocalData() ya procesó los datos cacheados

5. UI muestra datos del caché con banner "Sin conexión — datos del [fecha]" ✅
```

### Escenario C: Usuario SIN internet Y sin caché (primera vez offline)

```
1-4. Igual que escenario B

5. El Stream de SQLite emite null (no hay datos)
   → onLocalData(null) se ejecuta:
   a. state = state.copyWith(isLoading: false, error: kErrorNoDataOffline)

6. UI muestra EmptyState con icono offline y botón "Reintentar" ✅
```

> **Clave arquitectónica:** En los 3 escenarios, la lógica del Notifier es **idéntica**.
> La diferencia la hace el estado de SQLite y la red. El Notifier no necesita
> preguntar `_isOnline` para decidir qué mostrar — simplifica enormemente el código.

---

## 4. Flujo de Escritura — [submitEvaluation](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/data/datasources/project_detail_remote_datasource.dart#93-130)

La evaluación **requiere internet** (regla de negocio, no técnica). El flujo actual
ya lo gestiona correctamente. En la nueva arquitectura:

```
1. Notifier verifica isOnline — si offline, error inmediato (sin cambios)

2. Optimistic Update:
   a. Construye el modelo local provisional
   b. LocalRepository.saveDetail() → SQLite actualiza
   c. Stream emite → UI se actualiza instantáneamente con el dato optimista

3. RemoteRepository.submitEvaluation() — envía al backend

4a. Éxito → RemoteRepository.fetchDetail() → LocalRepository.saveDetail()
    → Stream actualiza UI con datos confirmados del servidor ✅

4b. Error → LocalRepository.saveDetail(prevSnapshot)
    → Stream emite el snapshot anterior (rollback)
    → state.evalError = mensaje de error ✅
```

---

## 5. Estrategia de Caché Inicial (First-Time Login)

Este es el escenario más crítico — la BD local está **completamente vacía**.

### Principio Rector
> La primera carga **siempre** va a la red. El objetivo es hacer esa primera
> experiencia lo más rápida posible y poblar la BD local de manera inteligente.

### Implementación: "Eager Pre-fetch"

```
┌─────────────────────────────────────────────────────┐
│             Login Exitoso (AuthNotifier)             │
│   auth.status == AuthAuthenticated                   │
└──────────────────────┬──────────────────────────────┘
                       │ dispara
                       ▼
┌─────────────────────────────────────────────────────┐
│         AppBootstrapService (nuevo servicio)         │
│                                                      │
│  1. Fetch showcase (primera página, 20 proyectos)    │
│     → Guarda en SQLite                               │
│  2. NO pre-carga detalles (demasiado pesado)         │
│     Los detalles se cachean on-demand (primera vez   │
│     que el usuario visita cada proyecto)             │
└─────────────────────────────────────────────────────┘
```

### Flujo Detallado del Primer Inicio de Sesión

```
T=0:  Usuario completa login → AuthNotifier.state = AuthAuthenticated
T=0:  AppBootstrapService.run() iniciado en background
T=0:  GoRouter navega a /home (Showcase)

T=1:  ShowcaseNotifier.build() ejecuta
      → SQLite vacío → Stream emite []
      → state = isLoading:true

T≈2:  AppBootstrapService completa fetch de showcase
      → Escribe 20 proyectos en SQLite

T≈2:  Stream de ShowcaseLocalRepository emite List<ProjectReadModel>
      → ShowcaseNotifier actualiza state (isLoading: false, projects: [...])
      → UI muestra lista de proyectos ✅

T=N:  Usuario toca un proyecto → ProjectDetailNotifier.build(id) ejecuta
      → SQLite vacío para ese id → Stream emite null → isLoading:true
      → _syncFromRemote() hace fetch del detalle
      → Escribe en SQLite → Stream emite → UI muestra detalle ✅
      → Segunda vez que visita ese proyecto: datos instantáneos del caché
```

### Regla de Invalidación de Caché (TTL — sin cambios)

El [cache_policy.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_policy.dart) ya define los TTL:
- **Showcase:** 15 minutos
- **Detalle:** 30 minutos

En la nueva arquitectura, el `LocalRepository` verificará el TTL **antes** de
disparar la sincronización background, no antes de servir datos:

```dart
// Pseudo-lógica en el Notifier
void _syncIfStale() {
  final fetchedAt = localRepo.getDetailFetchedAt(id);
  if (fetchedAt == null || isCacheStale(fetchedAt, kDetailCacheMaxAge)) {
    _syncFromRemote(); // Refresca en background
  }
  // Si hay datos frescos, NO se hace fetch → ahorro de datos y batería
}
```

---

## 6. Decisión Técnica: ¿Por qué SQLite y no Isar?

| Criterio | SQLite (sqflite) | Isar |
|---|---|---|
| Ya está en el proyecto | ✅ Sí | ❌ No |
| Curva de migración | Mínima | Alta (reescribir modelos con anotaciones) |
| Soporte web | ✅ Via `sqflite_ffi_web` | ⚠️ Limitado |
| Streams reactivos | ✅ Via patrón Stream manual | ✅ Nativo |
| Velocidad | Muy buena para este use case | Marginalmente mejor |

> **Recomendación:** Continuar con **SQLite (sqflite)** — ya es la herramienta instalada,
> los cambios son evolutivos (no destructivos) y la diferencia de rendimiento
> no es perceptible para el volumen de datos de Biofrost.

---

## 7. Patrón de Streams Reactivos en SQLite

SQLite no emite streams nativo. Implementaremos el patrón **"Repository Stream con StreamController"**:

```
LocalRepository mantiene internamente un:
  StreamController<ProjectDetailReadModel?> _detailController

Cuando LocalRepository.saveDetail() es llamado:
  1. Escribe en SQLite
  2. Lee el dato recién escrito
  3. _detailController.add(model)  ← emite al stream

El Notifier escucha:
  localRepo.watchDetail(id) → Stream<ProjectDetailReadModel?>

Ciclo de vida:
  - Se crea cuando el Notifier hace su primera suscripción
  - Se cierra en ref.onDispose() del Notifier
```

---

## 8. Impacto y Archivos Intocables

Los siguientes archivos **NO serán modificados** (son estables y correctos):

| Archivo | Razón |
|---|---|
| [core/cache/cache_database.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_database.dart) | Solo se amplían streams, no se rompe nada existente |
| [core/cache/cache_policy.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_policy.dart) | Mismas constantes, mismo uso |
| [core/services/api_service.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/services/api_service.dart) | El cliente Dio no cambia |
| [core/providers/connectivity_provider.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/providers/connectivity_provider.dart) | Sin cambios |
| `*/domain/models/*.dart` | Los modelos son el contrato — no cambian |
| `*/domain/commands/*.dart` | Los comandos son el contrato — no cambian |

---

## 9. Resumen de Archivos a Crear/Modificar

| Acción | Archivo | Cambio |
|---|---|---|
| 🆕 Crear | `project_detail/data/repositories/project_detail_local_repository.dart` | Nuevo |
| 🆕 Crear | `project_detail/data/repositories/project_detail_remote_repository.dart` | Extrae lógica de red del datasource actual |
| 🆕 Crear | `showcase/data/repositories/showcase_local_repository.dart` | Nuevo |
| 🆕 Crear | `showcase/data/repositories/showcase_remote_repository.dart` | Extrae lógica de red del datasource actual |
| 🆕 Crear | `core/services/app_bootstrap_service.dart` | Pre-fetch en login |
| ✏️ Modificar | [project_detail/providers/project_detail_provider.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/providers/project_detail_provider.dart) | Orquestra repos, usa streams |
| ✏️ Modificar | [showcase/providers/showcase_provider.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/showcase/providers/showcase_provider.dart) | Orquestra repos, usa streams |
| ✏️ Modificar | [core/cache/cache_database.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/core/cache/cache_database.dart) | Agrega `StreamController`s |
| 🗑️ Deprecar | [project_detail/data/datasources/project_detail_remote_datasource.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/project_detail/data/datasources/project_detail_remote_datasource.dart) | Su lógica migra a los dos repos |
| 🗑️ Deprecar | [showcase/data/datasources/showcase_remote_datasource.dart](file:///c:/Users/fitch/source/visual/Biofrost-dev-1/Biofrost_movil/lib/features/showcase/data/datasources/showcase_remote_datasource.dart) | Su lógica migra a los dos repos |

**Total:** 5 archivos nuevos, 3 modificados, 2 deprecados.
