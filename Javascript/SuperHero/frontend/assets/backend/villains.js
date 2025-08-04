// villains.js - Lógica de gestión de villanos

document.addEventListener('DOMContentLoaded', () => {
    const villainsList = document.getElementById('villains-list');
    const addVillainButton = document.getElementById('add-villain-btn');

    // Cargar lista de villanos
    async function fetchVillains(newVillain = null) {
        try {
            const token = localStorage.getItem('token');
            if (!token) throw new Error('No authentication token found');

            const response = await fetch(`${window.API.baseURL}/api/villain`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) throw new Error('Error fetching villains');

            const result = await response.json();
            let villains = Array.isArray(result.data) ? result.data : [];

            // Si se proporciona un nuevo villano, agregarlo al inicio de la lista
            if (newVillain && newVillain.data) {
                villains.unshift(newVillain.data);
            } else if (newVillain) {
                villains.unshift(newVillain);
            }

            // Filtrar villanos válidos
            const validVillains = villains.filter(villain => villain && villain.name && villain._id);

            villainsList.innerHTML = validVillains.map(villain => `
                <div class="villain-card">
                    <div class="character-icon">🦹‍♂️</div>
                    <h3 class="character-name">${villain.name}</h3>
                    <p class="character-alias">"${villain.alias || 'Sin alias'}"</p>
                    
                    <div class="character-details">
                        <div class="character-detail">
                            <span class="detail-label">Ciudad:</span>
                            <span class="detail-value">${villain.city || 'Desconocida'}</span>
                        </div>
                        <div class="character-detail">
                            <span class="detail-label">Organización:</span>
                            <span class="detail-value">${villain.organization || 'Independiente'}</span>
                        </div>
                        <div class="character-detail">
                            <span class="detail-label">Poder:</span>
                            <span class="detail-value">${villain.power || 'N/A'}</span>
                        </div>
                        <div class="character-detail">
                            <span class="detail-label">Descripción:</span>
                            <span class="detail-value">${villain.description || 'Sin descripción'}</span>
                        </div>
                    </div>
                    
                    <div class="character-actions">
                        <button class="action-btn edit edit-villain" data-id="${villain._id}">✏️ Editar</button>
                        <button class="action-btn delete delete-villain" data-id="${villain._id}">🗑️ Eliminar</button>
                    </div>
                </div>
            `).join('');
        } catch (error) {
            console.error('Failed to fetch villains:', error);
            villainsList.innerHTML = `
                <div style="text-align: center; color: var(--text-villain); padding: 2rem;">
                    <p>Error al cargar los villanos. Por favor, intenta de nuevo.</p>
                </div>
            `;
        }
    }

    // Add villain functionality
    if (addVillainButton) {
        addVillainButton.addEventListener('click', async () => {
            const name = prompt('Ingrese el nombre del villano:');
            if (!name) return;
            
            const alias = prompt('Ingrese el alias del villano:');
            if (!alias) return;
            
            const city = prompt('Ingrese la ciudad del villano:');
            if (!city) return;
            
            const organization = prompt('Ingrese la organización del villano:');
            if (!organization) return;

            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                const response = await fetch(`${window.API.baseURL}/api/villain`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ name, alias, city, organization })
                });

                if (!response.ok) {
                    const result = await response.json();
                    if (result && result.message) throw new Error(result.message);
                    throw new Error('Error adding villain');
                }

                const newVillain = await response.json();
                fetchVillains(newVillain);
            } catch (error) {
                console.error('Failed to add villain:', error);
                alert('Error al agregar el villano. Por favor, intenta de nuevo.');
            }
        });
    }

    // Event delegation for edit and delete buttons
    villainsList.addEventListener('click', async (e) => {
        if (e.target.classList.contains('edit-villain')) {
            const villainId = e.target.dataset.id;
            const newName = prompt('Ingrese el nuevo nombre del villano:');
            if (!newName) return;
            
            const newAlias = prompt('Ingrese el nuevo alias del villano:');
            if (!newAlias) return;
            
            const newCity = prompt('Ingrese la nueva ciudad del villano:');
            if (!newCity) return;
            
            const newOrganization = prompt('Ingrese la nueva organización del villano:');
            if (!newOrganization) return;

            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                const response = await fetch(`/api/villain/${villainId}`, {
                    method: 'PUT',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ 
                        name: newName, 
                        alias: newAlias,
                        city: newCity,
                        organization: newOrganization
                    })
                });

                const result = await response.json();
                if (!response.ok) {
                    if (result.error === 'NOT_OWNER') {
                        throw new Error('No puedes editar este villano porque no te pertenece');
                    } else if (result.message) {
                        throw new Error(result.message);
                    } else {
                        throw new Error('Error editing villain');
                    }
                }

                fetchVillains();
            } catch (error) {
                console.error('Failed to edit villain:', error);
                alert(error.message || 'Error al editar el villano. Por favor, intenta de nuevo.');
            }
        } else if (e.target.classList.contains('delete-villain')) {
            const villainId = e.target.dataset.id;
            if (!confirm('¿Estás seguro de que quieres eliminar este villano?')) return;

            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                const response = await fetch(`/api/villain/${villainId}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                const result = await response.json();
                if (!response.ok) {
                    if (result.error === 'NOT_OWNER') {
                        throw new Error('No puedes eliminar este villano porque no te pertenece');
                    } else if (result.message) {
                        throw new Error(result.message);
                    } else {
                        throw new Error('Error deleting villain');
                    }
                }

                fetchVillains();
            } catch (error) {
                console.error('Failed to delete villain:', error);
                alert(error.message || 'Error al eliminar el villano. Por favor, intenta de nuevo.');
            }
        }
    });

    // Initialize page
    fetchVillains();
});