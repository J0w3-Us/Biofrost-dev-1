# Reglas Generales del Proyecto IntegradorHub para Agentes

Estas reglas deben ser seguidas estrictamente por cualquier agente o subagente que interactúe con el código de este proyecto.

## 1. Frontend (React)
* **Estructura de Carpetas:** NO se utiliza el patrón de carpetas `features/` en el frontend. La interfaz se construye uniendo componentes de forma directa (ej. utilizando la carpeta `components/` u otras carpetas estándar, pero no agrupando por *features*). Dado caso deveras leer el proyecto, el usuario puede desconocer
* **Estilos:** El framework de diseño y estilado a utilizar es única y exclusivamente **Tailwind CSS**.
* **Manejo de Estado:** Para el manejo del estado global de la aplicación se debe utilizar únicamente **Context API**.

## 2. Backend (C# / .NET)
* **Arquitectura:** Se sigue una arquitectura orientada a características (`Features/`), respetando siempre la regla de separación de responsabilidades y la inyección de dependencias.

## 3. Comportamiento del Agente y Metodología (¡Obligatorio!)
* **Instalación de Dependencias:** **Prohibido** instalar paquetes (npm, NuGet, etc.) automáticamente. Siempre debes solicitar permiso al usuario primero y explicar detalladamente **el porqué** es requerida dicha dependencia.
* **Revisión del Estado:** Antes de intentar "pulir", refactorizar o hacer cambios masivos, debes verificar el estado actual del proyecto (cómo funciona actualmente, si compila, etc.).
* **Idioma:** Toda la documentación del proyecto, los comentarios dentro del código, los mensajes de commit y las explicaciones deben redactarse obligatoriamente en **Español** (LATAM).
