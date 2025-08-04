    // router.js - Navegación entre páginas SPA

    const Router = {
    init() {
        window.addEventListener('popstate', () => {
        this.render(window.location.pathname);
        });
        this.render(window.location.pathname);
    },
    navigateTo(path) {
        window.history.pushState({}, '', path);
        this.render(path);
    },
    async render(path) {
        const app = document.getElementById('app');
        try {
        const res = await fetch(path);
        const html = await res.text();
        app.innerHTML = html;
        } catch (err) {
        app.innerHTML = '<h2>Página no encontrada</h2>';
        }
    }
};

window.Router = Router;
