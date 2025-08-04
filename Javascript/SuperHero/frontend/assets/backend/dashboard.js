// dashboard.js - Lógica principal del panel

// dashboard.js - Lógica principal del panel

// Verificar autenticación al cargar la página
const token = localStorage.getItem('token');
const userRole = localStorage.getItem('role') || 'user';

if (!token) {
    alert('Debes iniciar sesión para acceder a esta página');
    window.location.href = 'auth/login.html';
} else {
    // Configurar sidebar según el rol del usuario
    const sidebar = document.getElementById('sidebar');
    if (sidebar) {
        if (userRole === 'admin') {
            sidebar.innerHTML = `
                <ul class="sidebar-list">
                    <li><a href="heroes.html">Héroes</a></li>
                    <li><a href="villains.html">Villanos</a></li>
                    <li><a href="battles.html">Batallas</a></li>
                    <li><a href="team.html">Mi equipo</a></li>
                    <li><a href="profile.html">Perfil de usuario</a></li>
                    <li><a href="admin.html">Panel admin</a></li>
                </ul>
            `;
        } else if (userRole === 'user') {
            sidebar.innerHTML = `
                <ul class="sidebar-list">
                    <li><a href="heroes.html">Héroes</a></li>
                    <li><a href="villains.html">Villanos</a></li>
                    <li><a href="battles.html">Batallas</a></li>
                    <li><a href="team.html">Mi equipo</a></li>
                    <li><a href="profile.html">Perfil de usuario</a></li>
                </ul>
            `;
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
  // Ejemplo: cargar datos rápidos del backend
    fetch(`${window.API.baseURL}/api/debug/data`)
        .then(r => r.json())
        .then(data => {
            if (data.counts) {
                document.getElementById('hero-count').textContent = data.counts.heroes;
                document.getElementById('villain-count').textContent = data.counts.villains;
                document.getElementById('battle-count').textContent = data.counts.battles;
            }
        });

    document.body.addEventListener('click', async function(e) {
        console.log('Button clicked:', e.target.textContent.trim()); // Debugging log
        if (e.target.tagName === 'BUTTON' && e.target.textContent.trim() === 'Ver héroes') {
            try {
                console.log('Fetching heroes from API...'); // Debugging log
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');
                const response = await fetch(`${window.API.baseURL}/api/hero`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                if (!response.ok) throw new Error('Error fetching heroes');
                const { data: heroes } = await response.json();
                console.log('Heroes fetched:', heroes); // Debugging log
                const heroesContainer = document.getElementById('heroes-container');
                const panelContainer = document.getElementById('panel-container');
                if (panelContainer) {
                    panelContainer.innerHTML = ''; // Limpia el contenido del panel azul
                }
                if (heroesContainer) {
                    heroesContainer.innerHTML = heroes.map(hero => `
                        <div style="border: 1px solid white; padding: 10px; margin: 5px;">
                            <h3>${hero.name} (${hero.alias})</h3>
                            <p><strong>Ciudad:</strong> ${hero.city}</p>
                            <p><strong>Equipo:</strong> ${hero.team}</p>
                            <p><strong>Poder:</strong> ${hero.power}</p>
                            <p><strong>Defensa:</strong> ${hero.defense}</p>
                        </div>
                    `).join('');
                } else {
                    console.error('Heroes container not found');
                }
            } catch (error) {
                console.error('Failed to fetch heroes:', error);
            }
        } else if (e.target.tagName === 'BUTTON' && e.target.textContent.trim() === 'Ver villanos') {
            try {
                console.log('Fetching villains from API...'); // Debugging log
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');
                const response = await fetch(`${window.API.baseURL}/api/villain`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                if (!response.ok) throw new Error('Error fetching villains');
                const { data: villains } = await response.json();
                console.log('Villains fetched:', villains); // Debugging log
                const villainsContainer = document.getElementById('villains-container');
                const panelContainer = document.getElementById('panel-container');
                if (panelContainer) {
                    panelContainer.innerHTML = ''; // Limpia el contenido del panel azul
                }
                if (villainsContainer) {
                    villainsContainer.innerHTML = villains.map(villain => `
                        <div style="border: 1px solid white; padding: 10px; margin: 5px;">
                            <h3>${villain.name} (${villain.alias})</h3>
                            <p><strong>Ciudad:</strong> ${villain.city}</p>
                            <p><strong>Equipo:</strong> ${villain.team}</p>
                            <p><strong>Poder:</strong> ${villain.power}</p>
                            <p><strong>Defensa:</strong> ${villain.defense}</p>
                        </div>
                    `).join('');
                } else {
                    console.error('Villains container not found');
                }
            } catch (error) {
                console.error('Failed to fetch villains:', error);
            }
        } else if (e.target.tagName === 'BUTTON' && e.target.textContent.trim() === 'Ver batallas') {
            try {
                console.log('Fetching battles from API...'); // Debugging log
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');
                const response = await fetch(`${window.API.baseURL}/api/battle`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                if (!response.ok) throw new Error('Error fetching battles');
                const { data: battles } = await response.json();
                console.log('Battles fetched:', battles); // Debugging log
                const battlesContainer = document.getElementById('battles-container');
                const panelContainer = document.getElementById('panel-container');
                if (panelContainer) {
                    panelContainer.innerHTML = ''; // Limpia el contenido del panel azul
                }
                if (battlesContainer) {
                    battlesContainer.innerHTML = battles.map(battle => `
                        <div style="border: 1px solid white; padding: 10px; margin: 5px;">
                            <h3>Batalla ID: ${battle._id}</h3>
                            <p><strong>Fecha:</strong> ${new Date(battle.createdAt).toLocaleDateString()}</p>
                            <p><strong>Estado:</strong> ${battle.status}</p>
                        </div>
                    `).join('');
                } else {
                    console.error('Battles container not found');
                }
            } catch (error) {
                console.error('Failed to fetch battles:', error);
            }
        }
    });
        // Cargar componentes HTML
    fetch('/components/sidebar.html')
        .then(r => r.text())
        .then(html => document.getElementById('sidebar').innerHTML = html);
    fetch('/components/footer.html').then(r => r.text()).then(html => document.getElementById('footer').innerHTML = html);
    fetch('/components/hero-card.html').then(r => r.text()).then(html => document.getElementById('hero-card').innerHTML = html);
    fetch('/components/villain-card.html').then(r => r.text()).then(html => document.getElementById('villain-card').innerHTML = html);
    fetch('/components/battle-card.html').then(r => r.text()).then(html => document.getElementById('battle-card').innerHTML = html);
    fetch('/components/modals.html').then(r => r.text()).then(html => document.getElementById('modals').innerHTML = html);
});

async function ensureToken() {
    let token = localStorage.getItem('token');
    if (!token) {
        try {
            const response = await fetch(`${window.API.baseURL}/api/auth/token`);
            if (!response.ok) throw new Error('Failed to fetch token');
            const { token: newToken } = await response.json();
            localStorage.setItem('token', newToken);
            console.log('Token stored successfully');
        } catch (error) {
            console.error('Failed to ensure token:', error);
        }
    }
}

// Ensure token is available
ensureToken();

if (typeof Router === 'undefined') {
    console.error('Router is not defined');
}