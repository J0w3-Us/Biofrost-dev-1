// heroes.js - Lógica de gestión de héroes

document.addEventListener('DOMContentLoaded', () => {
    const heroesList = document.getElementById('heroes-list');
    const addHeroButton = document.getElementById('add-hero-btn');

    // Cargar lista de héroes
    async function fetchHeroes(newHero = null) {
        try {
            const token = localStorage.getItem('token');
            console.log('Token retrieved:', token);
            if (!token) throw new Error('No authentication token found');

            const response = await fetch(`${window.API.baseURL}/api/hero`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) throw new Error('Error fetching heroes');

            const { data: heroes } = await response.json();
            console.log('Heroes fetched:', heroes);

            // Si se proporciona un nuevo héroe, agregarlo al inicio de la lista
            if (newHero) {
                heroes.unshift(newHero);
            }

            heroesList.innerHTML = heroes.map(hero => `
                <div class="hero-card">
                    <div class="character-icon">🦸‍♂️</div>
                    <h3 class="character-name">${hero.name}</h3>
                    <p class="character-alias">"${hero.alias}"</p>
                    
                    <div class="character-details">
                        <div class="character-detail">
                            <span class="detail-label">Ciudad:</span>
                            <span class="detail-value">${hero.city}</span>
                        </div>
                        <div class="character-detail">
                            <span class="detail-label">Equipo:</span>
                            <span class="detail-value">${hero.team}</span>
                        </div>
                        <div class="character-detail">
                            <span class="detail-label">Poder:</span>
                            <span class="detail-value">${hero.power}</span>
                        </div>
                        <div class="character-detail">
                            <span class="detail-label">Defensa:</span>
                            <span class="detail-value">${hero.defense}</span>
                        </div>
                    </div>
                    
                    <div class="character-actions">
                        <button class="action-btn edit edit-hero" data-id="${hero._id}">✏️ Editar</button>
                        <button class="action-btn delete delete-hero" data-id="${hero._id}">🗑️ Eliminar</button>
                    </div>
                </div>
            `).join('');
        } catch (error) {
            console.error('Failed to fetch heroes:', error);
            heroesList.innerHTML = `
                <div style="text-align: center; color: var(--text-villain); padding: 2rem;">
                    <p>Error al cargar los héroes. Por favor, intenta de nuevo.</p>
                </div>
            `;
        }
    }

    // Add hero functionality
    if (addHeroButton) {
        addHeroButton.addEventListener('click', async () => {
            const name = prompt('Ingrese el nombre del héroe:');
            if (!name) return;
            
            const alias = prompt('Ingrese el alias del héroe:');
            if (!alias) return;
            
            const city = prompt('Ingrese la ciudad del héroe:');
            if (!city) return;
            
            const team = prompt('Ingrese el equipo del héroe:');
            if (!team) return;
            
            const power = Math.floor(Math.random() * 100) + 1;
            const defense = Math.floor(Math.random() * 100) + 1;

            try {
                const token = localStorage.getItem('token');
                console.log('Token retrieved for adding hero:', token);
                if (!token) throw new Error('No authentication token found');

                const response = await fetch(`${window.API.baseURL}/api/hero`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ name, alias, city, team, power, defense })
                });

                if (!response.ok) throw new Error('Error adding hero');

                const newHero = await response.json();
                console.log('Hero added successfully');
                fetchHeroes(newHero);
            } catch (error) {
                console.error('Failed to add hero:', error);
                alert('Error al agregar el héroe. Por favor, intenta de nuevo.');
            }
        });
    }

    // Event delegation for edit and delete buttons
    heroesList.addEventListener('click', async (e) => {
        if (e.target.classList.contains('edit-hero')) {
            const heroId = e.target.dataset.id;
            const newName = prompt('Ingrese el nuevo nombre del héroe:');
            if (!newName) return;
            
            const newAlias = prompt('Ingrese el nuevo alias del héroe:');
            if (!newAlias) return;
            
            const newCity = prompt('Ingrese la nueva ciudad del héroe:');
            if (!newCity) return;
            
            const newTeam = prompt('Ingrese el nuevo equipo del héroe:');
            if (!newTeam) return;
            
            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                const response = await fetch(`/api/hero/${heroId}`, {
                    method: 'PUT',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ 
                        name: newName, 
                        alias: newAlias,
                        city: newCity,
                        team: newTeam
                    })
                });

                const result = await response.json();
                if (!response.ok) {
                    if (result.error === 'NOT_OWNER') {
                        throw new Error('No puedes editar este héroe porque no te pertenece');
                    } else {
                        throw new Error('Error editing hero');
                    }
                }

                console.log(`Hero with ID: ${heroId} edited successfully`);
                fetchHeroes();
            } catch (error) {
                console.error('Failed to edit hero:', error);
                alert(error.message || 'Error al editar el héroe. Por favor, intenta de nuevo.');
            }
        } else if (e.target.classList.contains('delete-hero')) {
            const heroId = e.target.dataset.id;
            if (!confirm('¿Estás seguro de que quieres eliminar este héroe?')) return;
            
            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                const response = await fetch(`/api/hero/${heroId}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                const result = await response.json();
                if (!response.ok) {
                    if (result.error === 'NOT_OWNER') {
                        throw new Error('No puedes eliminar este héroe porque no te pertenece');
                    } else {
                        throw new Error('Error deleting hero');
                    }
                }

                console.log(`Hero with ID: ${heroId} deleted successfully`);
                fetchHeroes();
            } catch (error) {
                console.error('Failed to delete hero:', error);
                alert(error.message || 'Error al eliminar el héroe. Por favor, intenta de nuevo.');
            }
        }
    });

    // Inicializar carga de héroes
    fetchHeroes();
});
