# Kiosko Byfrost: Transformación del Talento en DSM

**Documento de Análisis de Requerimientos y Estrategia Académica**

## 1. Planteamiento de la Problemática: El "Cementerio de Código"
En la carrera de Desarrollo de Software Multiplataforma (DSM), el Proyecto Integrador es el activo intelectual más valioso del alumno. Sin embargo, enfrentamos tres barreras críticas:

*   **Fugacidad del Capital Intelectual:** Una vez calificado, el software queda archivado en repositorios privados o discos duros. El conocimiento generado (errores resueltos, arquitecturas probadas) no sirve de base para futuras generaciones.
*   **Invisibilidad Técnica:** Los sistemas actuales (Teams/Moodle) son gestores de tareas, no vitrinas de talento. Un reclutador o un docente de otra área no tiene forma de visualizar el "stack" tecnológico o el "pitch" de un proyecto de forma inmediata.
*   **Ruido en la Identidad y el Feedback:** La falta de un registro centralizado que reconozca automáticamente quién es alumno y quién es docente mediante el correo institucional genera confusión en la asignación de responsabilidades y en la validez del feedback técnico.

## 2. Justificación: Del "Entregable" al "Activo Profesional"
Este sistema no es una simple base de datos; es una estrategia para revalorizar el trabajo del estudiante:

*   **Impacto Académico:** El error de hoy se convierte en el caso de estudio de mañana. Al documentar las "Lecciones Aprendidas", elevamos el nivel técnico de toda la carrera.
*   **Impacto Profesional:** Cada miembro del Squad obtiene una URL profesional verificable que demuestra su rol real (Backend, Frontend, UI/UX) y las validaciones de sus docentes.

## 3. Definición de Actores y Roles (El Modelo 3+1)
Para esta fase de DSM, hemos centralizado la autoridad en tres niveles operativos y un nivel de control maestro:

### 3.1. Miembro del Squad (Alumno)
*   **Identidad:** Reconocido por el prefijo numérico en su correo (Matrícula).
*   **Responsabilidad:** Generador de contenido. Opera como Líder (con permisos de creación y gestión de equipo) o Colaborador (no puede eliminar el proyecto).
*   **Restricción de Contexto:** Su capacidad de acción está limitada a su Grupo (ej. 5B). No puede agregar miembros de otros grupos para mantener la integridad de la evaluación de integradora.

### 3.2. Evaluador Contextual (Docente)
*   **Identidad:** Reconocido por el prefijo alfabético en su correo institucional.
*   **Responsabilidad:** Garante de calidad técnica. Su autoridad es relativa: solo puede evaluar proyectos que pertenezcan a los grupos que tiene asignados en el cuatrimestre.
*   **Feedback:** Capacidad de emitir retroalimentación técnica que el equipo puede elegir hacer pública como "Insignia de Logro".

### 3.3. Invitado (Empresa / Externo)
*   **Identidad:** Correos genéricos (Gmail, Outlook) o de organizaciones externas.
*   **Responsabilidad:** Consumidor de valor. Utiliza el Kiosko para reclutamiento, visualizando el Elevator Pitch y el One-Pager de los proyectos públicos.

### 3.4. Super Admin (Uziel Isaac, Yael Lopez)
*   **Control Maestro:** Único actor capaz de dar de alta materias, asignar prioridades a docentes y realizar el "Hard-Delete" en caso de registros erróneos. Gestiona el ciclo de vida (apertura y cierre de cuatrimestres).

## 4. Lógica de Interacción y Complejidad (Módulos)

### 4.1. Módulo de Registro Adaptativo
Al ingresar el correo, el sistema procesa el dominio. Si es `@utmetropolitana.edu.mx`, dispara un algoritmo de segmentación:
*   **Si es Alumno:** Bloquea el formulario a la carrera de DSM y solicita Matrícula y Grupo.
*   **Si es Docente:** Solicita especialidad y despliega la lista de grupos de DSM para su auto-asignación.

### 4.2. Creación de Squads y Filtros de Seguridad
Aquí resolvemos la complejidad de los datos:
*   **Handshake de Grupo:** Cuando el Líder crea el proyecto, el sistema inyecta su ID_Grupo.
*   **Filtro de Integrantes:** El buscador de compañeros solo devuelve usuarios que compartan el mismo ID_Grupo.
*   **Validación por Tooltip:** Para evitar errores de homónimos, al pasar el cursor (hover) sobre el nombre de un alumno en la lista de búsqueda, se muestra su Matrícula y foto en un texto flotante. Esto asegura que el Líder agregue a la persona correcta via confirmación visual.
*   **Vinculación Docente:** El sistema filtra automáticamente a los maestros que declararon impartir clase en ese grupo específico.

### 4.3. El Project Canvas (Edición Estilo Notion)
El proyecto se visualiza como una tarjeta dinámica en un Dashboard tipo Microsoft Teams.
*   **Modo Edición:** Un sistema de bloques para cargar la descripción, arquitectura, stack tecnológico (tags) y el Pitch de Video.
*   **Toggle de Visibilidad:** El proyecto nace en estado "Privado". Solo cuando el equipo decide que está listo, se activa el estado "Público" para que sea visible en el Showcase de invitados.

## 5. Requerimientos Técnicos Prioritarios (DSM)
*   **RF-01:** Reconocimiento de rol por Regex de correo institucional.
*   **RF-02:** Filtrado de equipo restringido por el Grupo del Líder.
*   **RF-03:** Tooltip de validación de matrícula en el buscador de miembros.
*   **RF-04:** CRUD de materias y prioridades gestionado por el Super Admin.


---

# Roadmap de Desarrollo y Arquitectura Técnica

## 1. El Core de la Aplicación: La "Triada Académica"
Para resolver la vaguedad de los puntos anteriores, el sistema se construye sobre una relación de dependencia estricta: `Usuario -> Grupo -> Proyecto -> Docente`.

### 1.1. Lógica de Negocio: El "Filtro de Contexto"
*   **Aislamiento de Squads:** El sistema debe inyectar el `grupo_id` en cada consulta. No existe la búsqueda global de alumnos; solo existe la búsqueda dentro del "Contenedor de Grupo".
*   **Integridad de Matrícula:** La matrícula no es un dato estético. Es la clave única (Unique Key) que previene que un alumno se registre dos veces o en grupos distintos.

## 2. Arquitectura de la Interfaz (UI/UX)
Siguiendo la estética de Microsoft Teams (Navegación) y Notion (Contenido).

### 2.1. Componentes Base (Átomos)
*   **Sidebar Institucional:** Navegación fija con módulos: Proyectos Públicos, Mi Squad, Perfil Profesional y Admin Panel (Solo para ti).
*   **Project Card (DSM-Spec):** Debe mostrar: Título, Stack Tecnológico (Badges), Integrantes (Avatares) y un indicador de "Estado" (Borrador/Público).
*   **The Hover-Tooltip:** Componente reactivo que al detectar `onMouseOver` en un nombre, muestra la matrícula y foto de perfil (Storage) guardado en el estado local.

### 2.2. El Editor de Proyectos (The Canvas)
No usaremos un formulario largo. Usaremos un Layout de Bloques:
*   **Bloque de Encabezado:** Título y Banner.
*   **Bloque de Squad:** Gestión de miembros (Agregar/Eliminar).
*   **Bloque de Documentación:** Editor de texto enriquecido para la arquitectura y problemática.
*   **Bloque Multimedia:** Inputs específicos para URL de YouTube (Pitch) y Dropzone para capturas de pantalla.

## 3. Especificación de Roles SCRUM (Rubrica Profesora)
Para cumplir con el instrumento de evaluación, el sistema refleja estos roles en nuestro equipo de desarrollo:
*   **Product Owner (Uziel Isaac):** Gestión de requerimientos y validación de historias de usuario. (Acceso Admin).
*   **Scrum Master:** Encargado de que el flujo de estados (Borrador -> Público) se cumpla.
*   **Dev Team:** El resto del Squad que tiene permisos de edición sobre el Canvas.

## 4. Mapa de Navegación (User Journey)
1.  **Paso 1: Autenticación e Identificación**
    *   Usuario ingresa con Google.
    *   El sistema ejecuta la Regex de Correo.
    *   Resultado: Redirección automática al Dashboard correspondiente (Alumno/Docente/Invitado).
2.  **Paso 2: Configuración de Contexto (Solo Alumnos)**
    *   Si es su primera vez, el sistema obliga a seleccionar Grupo y confirmar Matrícula. Estos campos se vuelven "Read-Only" después para evitar fraude académico.
3.  **Paso 3: Orquestación del Proyecto**
    *   El Líder crea el proyecto.
    *   Invita a miembros (Filtrados por su grupo).
    *   Selecciona al Docente de Integrante (Filtrado por maestros asignados a ese grupo).
4.  **Paso 4: Publicación y Showcase**
    *   El equipo completa el 100% de los bloques obligatorios.
    *   Se activa el botón "Publicar".
    *   El proyecto aparece en la Galería de Invitados para ser visto por reclutadores.

---

# Especificación Técnica de Ingeniería (MVP DSM)

**Enfoque:** Micro-segmentación para la carrera de Desarrollo de Software Multiplataforma.
**Arquitectura de Datos:** Relacional con persistencia en Firestore.

## 1. El Motor de Identidad (Auth Gatekeeper)
La entrada al sistema no es un simple login; es un enrutador de contexto. El sistema procesa el string del correo electrónico antes de permitir el acceso al dashboard.

### 1.1. Algoritmo de Enrutamiento de Dominio
**Trigger de Entrada:** Al momento de la autenticación (Google Auth/Firebase), se extrae el dominio y el prefijo.

#### Lógica de Segmentación:
*   **Regex Académico Alumno:** `^(\d{8})@utmetropolitana\.edu\.mx$`
    *   *Complejidad:* Si hace match con 8 dígitos al inicio, el sistema dispara automáticamente una consulta al catálogo de "Alumnos" para validar Matrícula. Si no existe, lanza el "Formulario de Primer Registro" bloqueando la carrera a "DSM".
*   **Regex Académico Docente:** `^[a-zA-Z.]+@utmetropolitana\.edu\.mx$`
    *   *Complejidad:* Si detecta caracteres alfabéticos, se mapea al rol "Evaluador". Se habilita el módulo de "Asignación de Grupos" donde el docente elige de qué grupos (ej. 5B, 5C) es responsable en el cuatrimestre actual.
*   **Fallback Externo:** Cualquier otro dominio se categoriza como "Invitado". Se restringe la escritura en la base de datos (ReadOnly por defecto).

## 2. Arquitectura de Grupos y Vinculación Docente
Este es el núcleo de la coherencia del sistema. No es un campo de texto, es una relación jerárquica.

### 2.1. El Filtro de "Ecosistema de Grupo"
**Dependencia Funcional:** Un Alumno (A) pertenece a un Grupo (G). Un Docente (D) tiene N Grupos.

#### Lógica de Creación de Proyecto:
*   **Contexto Automático:** Cuando el Alumno "Líder" crea un proyecto, el sistema inyecta el ID del Grupo del líder en el documento del proyecto de forma inmutable.
*   **Selección de Docente:** El sistema realiza un GET a la colección de Docentes filtrando por `grupos_asignados` que contengan el ID_Grupo del alumno.
    *   *Complejidad:* Garantiza que un alumno del 5B solo pueda elegir a un profesor que tenga asignado el 5B, evitando datos "huérfanos".

## 3. Protocolo de Squads (Data Integrity)
Para evitar duplicados, implementamos una lógica de Descubrimiento de Miembros estricta.

### 3.1. Búsqueda de Integrantes por Contexto
*   **Query Restringida:** El buscador de integrantes solo realiza peticiones sobre la colección de usuarios cuyo atributo `grupo == grupo_del_lider`.
*   **Interacción UX (The Hover Logic):**
    *   *Visualización Primaria:* Nombre y Apellidos (UX-Friendly).
    *   *Validación Técnica:* Al detectar el evento `onMouseEnter` (hover) sobre el nombre, se dispara un Tooltip que recupera el atributo matrícula.
    *   *Objetivo:* Eliminar el error humano en homónimos. El líder confirma visualmente la identidad del compañero.

## 4. Gestión de Contenidos: El "Project Canvas"
Abandonamos el formulario estático por un sistema de Bloques de Información dinámicos.

### 4.1. Estructura del Canvas (Modo Edición)
El proyecto se comporta como un documento dinámico (Estilo Notion):
*   **Bloque Header:** Metadatos automáticos (Grupo, Carrera, Cuatrimestre).
*   **Bloque Squad:** Lista de integrantes con roles técnicos (Backend, Frontend, UI/UX).
*   **Bloque Multimedia:** Pitch Video (YouTube/Drive) con validación de URL y Galería de capturas (Lazy Loading).
*   **Bloque Técnico:** Espacio Markdown para descripción de problemática y arquitectura.
*   **Nota:** Se implementará un apartado de visibilidad pública/privada para proteger proyectos en desarrollo.

## 5. Gobierno de Datos (Super Admin)
Como Super Admin, actúas como el oráculo de la Base de Datos.

### 5.1. Control Maestro de Catálogos
*   **Gestión de Docentes:** Capacidad de "Promover" a un docente (Prioridad Alta/Baja). Los docentes de Prioridad Alta tienen sus comentarios destacados.
*   **Gestión de Materias:** Alta de materias de DSM para categorizar los proyectos.
*   **Hard-Delete Académico:** Eliminación de proyectos o desvinculación de alumnos por errores de registro, manteniendo trazabilidad.

## 6. Matriz de Complejidad de UI (Vistas por Rol)
*   **Alumno (Dashboard Colaborativo):** Enfocado en edición y visualización de progreso. Muestra su "Squad" en primer plano.
*   **Docente (Dashboard de Revisión):** Lista de proyectos filtrada por grupos asignados. Incluye "Cola de Evaluación".
*   **Invitado (Showcase):** Galería infinita de proyectos con buscador por "Stack Tecnológico".

---

# Arquitectura de Datos y Flujos de Trabajo (Firestore)

## 1. Modelo de Datos (Esquema Firestore)
Toda la información reside bajo la ruta raíz: `/artifacts/{appId}/`.

### 1.1. Colección: public/data/users
Almacena el perfil profesional de alumnos, docentes e invitados.
*   **ID:** `uid` (Firebase Auth)
*   **Campos:** `nombre_completo`, `rol`, `email`, `matricula` (alumnos), `grupo_id` (alumnos), `grupos_docente` (docentes), `prioridad_docente`.

### 1.2. Colección: public/data/projects
Repositorio central de proyectos.
*   **Campos:** `titulo`, `slug`, `lider_id`, `miembros` (array UIDs), `grupo_contexto`, `docente_asignado`, `estado`, `content_blocks`, `stack_tecnico`, `fecha_creacion`.

### 1.3. Colección: public/data/evaluations
Feedback técnico vinculado a proyectos.
*   **Campos:** `proyecto_id`, `docente_id`, `comentario` (Markdown), `tipo` (oficial/sugerencia), `visto_por_equipo`.

## 2. Flujo de Estados del Proyecto (Visibilidad)
Máquina de estados para gestionar la privacidad:
*   **Borrador (Draft):** Visible solo por el Líder. Creación inicial.
*   **Privado (Squad Only):** Visible por el Squad y Docente asignado. Edición colaborativa.
*   **Público (Published):** Visible por todo el Kiosko. Indexable para invitados.
*   **Histórico (Archived):** Solo lectura. Ejecutado por Admin al fin del cuatrimestre.

## 3. Lógica de Servicio: Filtros en Memoria
Para eficiencia en Firebase:
*   **Buscador de Compañeros:** Descarga lista de users del grupo del líder y filtra localmente (JS).
*   **Galería de Invitados:** Descarga proyectos públicos y filtra por Stack en memoria.

## 4. Validaciones de Seguridad (Reglas Críticas)
*   **Escritura:** Solo miembros del proyecto (`uid` en array `miembros` o `lider_id`) pueden editar.
*   **Evaluación:** Solo docentes con el grupo asignado pueden escribir evaluaciones.

---

# Suplemento de UX Research y Metodología SCRUM

## 1. Definición del Equipo SCRUM
*   **Product Owner:** Uziel Isaac Pech Balam (Visión y Backlog).
*   **Scrum Master:** Jose Yael Lopez (Facilitador).
*   **Equipo de Desarrollo:** Frontend Dev (UI/UX), Backend/Firebase Dev (Seguridad/Datos), QA/UX Tester (Validación flujos).

## 2. Historias de Usuario (User Stories)
*   **HU-01 (Alumno):** Reconocimiento automático por correo para evitar configuración manual.
*   **HU-02 (Líder):** Filtrar compañeros por grupo para evitar errores.
*   **HU-03 (Docente):** Ver solo proyectos de grupos asignados para agilizar evaluación.
*   **HU-04 (Invitado):** Ver video pitch para entender propuesta rápidamente.

## 3. Artefactos de UX
*   **Proto-Persona:** "Jose, el Dev Estresado" (Alumno que necesita visibilidad profesional).
*   **Método AEIOU:** Análisis de actividades, entornos, interacciones, objetos y usuarios.

## 4. Estrategia de Identidad
*   **Nombre:** IntegradorHub: DSM Edition.
*   **Concepto:** Conexión (Network) + Verde Institucional + Azul Tecnológico.
*   **Slogan:** "Del aula al mercado: tu código, tu vitrina."

## 5. Diagrama de Actividades
Flujo lógico desde ingreso de correo hasta asignación de rol y dashboard correspondiente.

---

# Especificación de Diagramas Técnicos

## 1. Diagrama de Casos de Uso (Permisos)
Define límites de interacción para Alumno (Líder), Docente y Admin. Desde autenticación hasta cierre de ciclo académico.

## 2. Diagrama de Secuencia (Invitación de Integrante)
Detalla la interacción Frontend-Backend-DB durante la búsqueda y adición de miembros con validación de grupo y tooltip de matrícula.

## 3. Diagrama de Estados (Ciclo de Vida)
Transiciones formales: Inicial -> Desarrollo -> Exhibición -> Legado.

## 4. Diagrama de Arquitectura Física
React 18 (Presentación) -> Firebase Auth/Hooks (Servicios) -> Firestore (Datos) -> Storage (Multimedia).

---

# Arquitectura del Sistema (Implementación Actual)

Este proyecto implementa una arquitectura moderna, desacoplada y escalable, dividida físicamente en dos grandes bloques tecnológicos: un Backend robusto en .NET 8 y un Frontend reactivo en React 19.

## 1. Stack Tecnológico

| Capa | Tecnología | Versión | Rol Principal |
| :--- | :--- | :--- | :--- |
| **Backend** | .NET (C#) | 8.0 | API REST, Reglas de Negocio, Orquestación. |
| **Frontend** | React | 19.x | Interfaz de Usuario, Estado Global. |
| **Build Tool** | Vite | 7.x | Empaquetado y Entorno de Desarrollo Rápido. |
| **Estilos** | Tailwind CSS | 4.x | Diseño Atómico y Responsivo. |
| **BD** | Google Firestore | NoSQL | Persistencia de Datos Documental. |
| **Auth** | Firebase Auth | SDK | Gestión de Identidad y Roles. |
| **Patrón** | CQRS + Mediator | MediatR | Separación de Comandos y Consultas. |

## 2. Arquitectura Backend (.NET 8)

El backend no sigue una arquitectura de capas tradicional (N-Layer), sino que adopta **Vertical Slice Architecture** (Arquitectura de Cortes Verticales). Este enfoque organiza el código por **Features** (Funcionalidades) en lugar de capas técnicas, lo que permite que cada funcionalidad (ej. "Crear Proyecto") sea autónoma y fácil de mantener.

### Organización del Código
*   **Features/**: Es el corazón del sistema. Cada carpeta aquí representa una "Rebanada Vertical" completa.
    *   *Ejemplo:* `Features/Projects/Create` contiene:
        *   `CreateProjectCommand.cs` (La intención del usuario).
        *   `CreateProjectHandler.cs` (La lógica de negocio).
        *   `CreateProjectValidator.cs` (Reglas de validación, ej. "Título no vacío").
        *   `ProjectsController.cs` (El endpoint HTTP que expone la funcionalidad).
*   **Shared/**: Contiene el núcleo común que comparten las features, como las Entidades del Dominio (`User`, `Project`) y la configuración de Infraestructura (`FirestoreContext`).

### Patrón CQRS (Command Query Responsibility Segregation)
Utilizamos la librería **MediatR** para desacoplar totalmente la recepción de una petición HTTP de su procesamiento.
*   **Commands (Escritura):** Acciones que modifican el estado del sistema (Create, Update, Delete). Retornan éxito o fallo.
*   **Queries (Lectura):** Acciones que solo recuperan datos. Están optimizadas para velocidad y no modifican nada.

## 3. Arquitectura Frontend (React 19 + Vite)

El frontend refleja la estructura modular del backend para reducir la carga cognitiva del desarrollador. Si existe una Feature de "Proyectos" en el backend, existe una Feature de "Proyectos" en el frontend.

### Estructura de Componentes
*   **src/features/**: Contiene la lógica, hooks y componentes específicos de cada módulo de negocio (Auth, ProjectCanvas, Showcase).
*   **src/components/ui/**: Componentes "tontos" y reutilizables (Botones, Inputs, Cards) que siguen un sistema de diseño atómico. No contienen lógica de negocio.
*   **src/lib/**: Configuración de infraestructura frontend (Cliente de Axios, Inicialización de Firebase).

### Flujo de Datos (Data Journey)
1.  **UI:** El usuario interactúa con un componente (ej. clic en "Guardar").
2.  **Hook:** Un Custom Hook (`useProjectOps`) despacha la acción.
3.  **API Layer:** Axios envía la petición HTTP al Backend (.NET).
4.  **CQRS:** El controlador recibe la petición y envía un *Command* a MediatR.
5.  **Handler:** El Handler ejecuta la lógica, valida reglas de negocio y persiste en Firestore.
6.  **Response:** El resultado viaja de vuelta a la UI para actualizar el estado visual.

## 4. Estructura de Directorios del Proyecto

```text
/IntegradorHub-Root
│
├── /backend (Solución .NET 8 - Vertical Slice Architecture)
│   ├── /src
│   │   ├── /IntegradorHub.API
│   │   │   ├── /Features                  <-- LÓGICA DE NEGOCIO (Slices)
│   │   │   │   ├── /Auth                  (Login, Identificación de Roles)
│   │   │   │   ├── /Projects              (CRUD de Proyectos, Lógica de Squads)
│   │   │   │   └── /Evaluations           (Sistema de Feedback Docente)
│   │   │   ├── /Shared                    <-- NÚCLEO COMPARTIDO
│   │   │   │   ├── /Domain                (Entidades: User, Project)
│   │   │   │   └── /Infrastructure        (Conexión a Firestore)
│   │   │   └── Program.cs                 (Configuración de Inyección de Dependencias)
│
├── /frontend (React 19 + Vite - Feature Based)
│   ├── /src
│   │   ├── /features                      <-- MÓDULOS DE UI
│   │   │   ├── /auth                      (Formularios y Hooks de Sesión)
│   │   │   ├── /project-canvas            (Editor de Bloques estilo Notion)
│   │   │   └── /showcase                  (Galería Pública)
│   │   ├── /components                    <-- SISTEMA DE DISEÑO (Atomic)
│   │   ├── /lib                           (Configuración Axios/Firebase)
│   │   └── flujos y rutas                 (Router y Layouts)
│
└── /docs                                  <-- DOCUMENTACIÓN EXTENDIDA
```
