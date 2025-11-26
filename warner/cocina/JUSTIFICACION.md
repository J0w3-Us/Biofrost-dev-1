# Justificación Técnica del Proyecto "Cocina Kinich"

## 1. Selección de Tecnología para el Frontend
Para el desarrollo de la interfaz de usuario de la aplicación "Cocina Kinich", hemos optado por utilizar **Vanilla JavaScript (ES6+)**, junto con **HTML5 Semántico** y **CSS3 Moderno** (sin preprocesadores ni frameworks pesados).

## 2. ¿Por qué elegimos esta tecnología?
Decidimos no utilizar frameworks como React o Vue para este módulo específico por las siguientes razones:
*   **Simplicidad y Ligereza**: Al ser una aplicación enfocada en la visualización de recetas y comandas, no requerimos la complejidad de gestión de estado que ofrecen librerías grandes. Queríamos que la carga fuera instantánea.
*   **Control Visual Absoluto**: Para lograr la estética "Premium" y las animaciones personalizadas estilo "Kinich", trabajar directamente con CSS y el DOM nos permite un ajuste fino de las transiciones sin luchar contra las abstracciones de un framework.
*   **Requisito Académico**: Cumplimos estrictamente con la restricción de "No Angular" y demostramos dominio de los fundamentos de la web.

## 3. Ventajas Encontradas
*   **Rendimiento Nativo**: La aplicación no requiere un proceso de "transpilación" o "build". El navegador interpreta el código directamente, lo que resulta en tiempos de carga mínimos.
*   **Flexibilidad en el Diseño**: El uso de Variables CSS (`:root`) nos permitió implementar un tema oscuro y elegante muy fácilmente, modificable en tiempo real.
*   **Independencia**: No dependemos de actualizaciones de terceros o versiones de librerías que puedan romper el código en el futuro.

## 4. Dificultades Enfrentadas
*   **Manipulación del DOM**: Actualizar la interfaz (como renderizar la lista de recetas) requiere más líneas de código imperativo (`document.createElement`, `appendChild`) comparado con la sintaxis declarativa de frameworks modernos (JSX).
*   **Gestión de Estado**: Mantener la sincronización entre los datos del backend y lo que ve el usuario requiere una planificación cuidadosa, ya que no tenemos un "Virtual DOM" que lo haga automáticamente.

---
**Conclusión**:
Esta arquitectura "Vanilla" es la ideal para una "Mini Aplicación" de restaurante, equilibrando perfectamente el rendimiento con una experiencia de usuario de alta calidad visual.
