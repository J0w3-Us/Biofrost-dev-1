// team.js - Lógica para Mi equipo

async function loadComponents() {
    await Promise.all([
        loadComponent('/components/header.html', 'header-container'),
        loadComponent('/components/sidebar.html', 'sidebar-container'),
        loadComponent('/components/footer.html', 'footer-container'),
        loadComponent('/components/modals.html', 'modal-container')
    ]);
}

async function fetchTeamHeroes() {
    try {
        const response = await api.get('/api/hero/team');
        return response.data;
    } catch (error) {
        showError('Error al cargar héroes del equipo');
        return [];
    }
}

async function fetchTeamVillains() {
    try {
        const response = await api.get('/api/villain/team');
        return response.data;
    } catch (error) {
        showError('Error al cargar villanos del equipo');
        return [];
    }
}

function renderTeamList(listId, items, cardComponent) {
    const list = document.getElementById(listId);
    list.innerHTML = '';
    items.forEach(item => {
        fetch(cardComponent)
            .then(res => res.text())
            .then(template => {
                let card = template
                    .replace(/{{name}}/g, item.name)
                    .replace(/{{alias}}/g, item.alias || '')
                    .replace(/{{power}}/g, item.power || '')
                    .replace(/{{description}}/g, item.description || '');
                const div = document.createElement('div');
                div.innerHTML = card;
                list.appendChild(div);
            });
    });
}

async function loadTeam() {
    const heroes = await fetchTeamHeroes();
    const villains = await fetchTeamVillains();
    renderTeamList('team-heroes-list', heroes, '/components/hero-card.html');
    renderTeamList('team-villains-list', villains, '/components/villain-card.html');
}

function addArenaAccessButton() {
    const contentSection = document.querySelector('.content-section');
    if (contentSection) {
        const arenaButton = document.createElement('div');
        arenaButton.innerHTML = `
            <div style="
                text-align: center;
                margin: 2rem 0;
                padding: 2rem;
                background: linear-gradient(135deg, var(--bg-panel), rgba(171, 71, 188, 0.1));
                border: 2px solid var(--text-battle);
                border-radius: 16px;
                box-shadow: 0 8px 32px rgba(171, 71, 188, 0.2);
            ">
                <h2 style="
                    color: var(--text-battle);
                    margin-bottom: 1rem;
                    font-size: 2rem;
                    text-transform: uppercase;
                    letter-spacing: 2px;
                    text-shadow: 0 0 15px rgba(171, 71, 188, 0.5);
                ">⚔️ Arena de Combate</h2>
                <p style="
                    color: var(--text-secondary);
                    margin-bottom: 2rem;
                    font-size: 1.1rem;
                    max-width: 600px;
                    margin-left: auto;
                    margin-right: auto;
                ">¡Entra al combate por turnos estilo Pokémon! Selecciona tu equipo y batalla contra poderosos enemigos en una experiencia épica.</p>
                <button onclick="goToArenaCombat()" style="
                    background: linear-gradient(135deg, var(--text-battle), #9c27b0);
                    color: white;
                    border: 2px solid var(--text-battle);
                    padding: 1rem 2rem;
                    border-radius: 12px;
                    font-size: 1.2rem;
                    font-weight: bold;
                    text-transform: uppercase;
                    letter-spacing: 1px;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    box-shadow: 0 4px 15px rgba(171, 71, 188, 0.3);
                " onmouseover="this.style.transform='translateY(-3px)'; this.style.boxShadow='0 8px 25px rgba(171, 71, 188, 0.5)'"
                   onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(171, 71, 188, 0.3)'">
                    🏟️ Entrar al Combate
                </button>
            </div>
        `;
        
        // Insertar después del título
        const title = contentSection.querySelector('h1');
        if (title) {
            title.insertAdjacentElement('afterend', arenaButton);
        }
    }
}

function goToArenaCombat() {
    // Redirigir a la página de combate de arena
    window.location.href = '../arena-combat.html';
}

async function init() {
    await loadComponents();
    addArenaAccessButton();
    loadTeam();
}

document.addEventListener('DOMContentLoaded', init);
