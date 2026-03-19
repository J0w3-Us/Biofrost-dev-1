# BIOFROST

**Sistema Integral de Gestión y Evaluación Competitiva de Proyectos Académicos**

**License:** MIT

Biofrost es la nueva versión de [Biofrost](../biofrost/README.md) — plataforma multi‑canal (web + móvil + backend) diseñada para conectar la entrega de proyectos académicos con su evaluación en campo, garantizando trazabilidad, auditoría y capacidad offline para escenarios presenciales (ferias, exposiciones, jurados).

**Resumen rápido**

- **Propósito:** Facilitar la evaluación y registro de proyectos integradores, optimizando el tiempo de docentes y preservando un historial completo de acciones.
- **Enfoque:** UX móvil para evaluadores in‑situ; integración con el portal web para publicación, edición y administración.
- **Versión anterior:** Biofrost — esta app es su evolución directa con arquitectura mejorada.

---

## Aplicación Móvil (este repositorio)

- **Stack:** Flutter (Dart) · Riverpod · GoRouter · Firebase (Auth + Firestore + FCM)
- **Objetivo:** Escaparate público de proyectos académicos con capacidades de evaluación in‑situ para docentes, accesible también a visitantes sin autenticación.
- **Backend:** IntegradorHub API (.NET 9 · CQRS + Event Sourcing) — `https://integradorhub.onrender.com`
- **Plataformas objetivo:** Android (primario), iOS (secundario)

### Pantallas principales

- **Showcase** — Galería de proyectos en grid 2 columnas con búsqueda full-text y filtros por tecnología.
- **Ranking** — Clasificación con podio visual (🥇🥈🥉) y tabla de posiciones.
- **Detalle de proyecto** — Thumbnail, descripción, stack tecnológico, equipo, canvas, video y enlaces externos.
- **Evaluación** — Panel para calificar con estrellas (1–5) y dejar retroalimentación (solo Docentes).
- **Perfil** — Datos personales, KPIs, proyectos supervisados, historial de evaluaciones y toggle de tema.

### Roles y acceso

| Rol           | Descripción                                                                                           | Acceso                      |
| ------------- | ----------------------------------------------------------------------------------------------------- | --------------------------- |
| **Docente**   | Maestro titular. Crea evaluaciones oficiales (0–100), gestiona visibilidad, ve proyectos de su grupo. | Autenticado (Firebase Auth) |
| **Evaluador** | Juez externo invitado para eventos. Puede enviar evaluaciones de tipo `sugerencia`.                   | Autenticado                 |
| **Visitante** | Persona sin cuenta. Puede navegar el showcase, ver detalle y dejar comentarios.                       | Anónimo / Invitado          |

### Características clave

- Modo visitante sin registro para exploración pública.
- Caché offline con indicador de antigüedad y banner de sin conexión.
- Notificaciones push y deep links para acceso directo a proyectos.
- Compartir proyectos por URL nativa del dispositivo.
- Registro de analíticas de visitas y proyectos vistos recientemente.
- Diseño dark/light con paleta purple-slate (Inter, Material 3).

---

## Arquitectura

```
lib/
├── core/           ← Infraestructura compartida (config, router, theme, services)
└── features/
    ├── auth/           ← Login, sesión, roles
    ├── showcase/       ← Galería de proyectos + filtros
    ├── project_detail/ ← Detalle de proyecto + votación
    ├── evaluations/    ← Formulario y panel de evaluaciones
    ├── ranking/        ← Tabla de ranking con podio
    ├── profile/        ← Perfil del Docente
    └── sharing/        ← QR, PDF, compartir link/imagen
```

Patrón: **Clean Architecture + CQRS** por feature con Riverpod como capa de estado.

---

## Quickstart

```powershell
cd Biofrost
flutter pub get
flutter run
```

## Configuración Firebase

- Registra las apps (Android/iOS) en Firebase y coloca `google-services.json` / `GoogleService-Info.plist` en los directorios nativos correspondientes.
- Configura el archivo `.env.development` con la URL del backend local.

## Contribuir

- Abre un issue describiendo el cambio o bug.
- Crea PRs pequeños y enfocados; sigue el patrón de commits del repo.
