// battle-detail.js - Simulación de batalla

// Cargar componentes
async function loadComponents() {
    await Promise.all([
        loadComponent('/components/header.html', 'header-container'),
        loadComponent('/components/sidebar.html', 'sidebar-container'),
        loadComponent('/components/footer.html', 'footer-container'),
        loadComponent('/components/modals.html', 'modal-container')
    ]);
}

// Renderizar detalle de batalla
function renderBattleDetail(detail) {
    const container = document.getElementById('battle-detail-container');
    fetch('/components/battle-detail-card.html')
        .then(res => res.text())
        .then(template => {
            let card = template
                .replace(/{{hero}}/g, detail.hero?.name || '')
                .replace(/{{villain}}/g, detail.villain?.name || '')
                .replace(/{{winner}}/g, detail.winner?.name || '')
                .replace(/{{log}}/g, detail.log || '');
            container.innerHTML = card;
        });
}

// Simular batalla
async function simulateBattle() {
    openModal({
        title: 'Simular Batalla',
        content: `
            <form id="simulate-battle-form">
                <input type="text" name="hero" placeholder="ID o nombre del héroe" required>
                <input type="text" name="villain" placeholder="ID o nombre del villano" required>
                <button type="submit" class="primary-btn">Simular</button>
            </form>
        `
    });
    document.getElementById('simulate-battle-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        const form = e.target;
        const data = {
            hero: form.hero.value,
            villain: form.villain.value
        };
        try {
            const response = await api.post('/api/battles/simulate', data);
            closeModal();
            renderBattleDetail(response.data);
        } catch (error) {
            showError('Error al simular batalla');
        }
    });
}

// Inicializar página
async function init() {
    await loadComponents();
    document.getElementById('simulate-battle-btn').addEventListener('click', simulateBattle);
}

document.addEventListener('DOMContentLoaded', init);
