## Reglas para Agentes — Flujo de Trabajo (para equipos de desarrollo móvil)

Estas reglas sirven como checklist operativo para los agentes que implementan tareas de producto y diseño. Basadas en el rol y responsabilidades descritas en AI/agents.md, están pensadas para ser concisas y accionables.

1. Regla de Oro: Identificar el tipo de trabajo

- Antes de tocar código, determina si el requerimiento es: Historia de Usuario, Definición de Entidad, o Endpoint. Decide si corresponde a un flujo de Consulta (Query) o a un Comando (Command).

2. Arquitectura y Modelado

- Usa CQRS: comparte la intención en el PR/issue ("Query" o "Command").
- Nunca reutilices el mismo modelo para lectura y escritura. Define `ReadModel` optimizado para UI y `CommandModel` para transacciones.
- Convenciones de nombres: `MyEntityReadModel`, `CreateMyEntityCommand`, `UpdateMyEntityCommand`.

3. Mapeo de contratos y seguridad de tipos

- Cuando el backend es .NET/C#, mapea explícitamente DTOs a clases Dart con Null Safety.
- Usa tipos que representen correctamente nullabilidad y fechas (ISO 8601). Documenta diferencias de convención de nombres (PascalCase ⇄ camelCase) y transforma en la capa de serialización.

4. Gestión de Estado y UX

- Implementa gestor de estado reactivo (BLoC/Riverpod/Provider). En la descripción del cambio indica cuál usas y por qué.
- Feedback inmediato: la UI debe reaccionar localmente (optimistic update) y mostrar estado de envío/resultado. Siempre definir rollback en caso de error.

5. Consultas y Performance (Kiosk Mode)

- Para ReadModels, aplica caché con patrón Stale-While-Revalidate: servir desde caché y refrescar en background.
- Define TTL, política de invalidación y una estrategia para refresco forzado por el usuario.

6. Manejo de errores y UX resiliente

- Traduce errores técnicos a mensajes humanos. Categoriza: Conexión (ej. "No hay conexión — Reintentar"), Validación de negocio (mostrar mensaje junto al campo), Error inesperado (SnackBar genérico).
- Incluye códigos de error o correlación para debugging en logs, pero no los muestres al usuario final.

7. Entregables y artefactos mínimos por tarea

- Modelos Dart (Read/Command), repositorio/servicio, gestor de estado, tests unitarios para serialización y lógica, y widgets básicos si aplica.
- Incluye en el PR: resumen, tipo (Query/Command), mapping con el DTO backend (ej. campo X: string? → String?), y checklist de QA.

8. Validaciones y QA mental (antes de PR)

- ¿Se manejan nulos? ¿Fechas en ISO? ¿Rollback definido para optimistic updates? ¿Mensajes de error diferenciados? ¿Textos accesibles y editables en SVGs cuando corresponda? (ver reglas de SVG relacionadas)

9. Estándares de commit y PR

- Título: `[CQRS][Query|Command] <breve-descripción>`
- Body: descripción técnica breve, archivos clave cambiados, y artefactos anexos (mocks, ejemplos de payload).

10. Referencias

- Sigue las responsabilidades y criterios descritos en AI/agents.md al implementar cada paso.

Aplica estas reglas en cada tarea y menciona en el PR que la checklist fue seguida.
