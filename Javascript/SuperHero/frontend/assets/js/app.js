// app.js - Inicialización principal del frontend

document.addEventListener('DOMContentLoaded', () => {
  // Inicializa el router
    if (typeof Router !== 'undefined') {
        Router.init();
    }

    // Verifica autenticación y muestra la página correspondiente
    Router.navigateTo('/pages/auth/login.html'); // Always redirect to login
});
