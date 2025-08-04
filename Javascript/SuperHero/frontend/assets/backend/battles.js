// battles.js - Lógica de gestión de batallas

document.addEventListener('DOMContentLoaded', () => {
    // Verificar autenticación
    const token = localStorage.getItem('token');
    if (!token) {
        alert('Debes iniciar sesión para acceder a esta página');
        window.location.href = '../auth/login.html';
        return;
    }

    const battlesList = document.getElementById('battles-list');
    const createBattleButton = document.getElementById('create-battle-btn');

    // Configurar actualización automática cada 10 segundos
    let autoRefreshInterval;
    
    // Función para iniciar el auto-refresh
    function startAutoRefresh() {
        // Limpiar cualquier intervalo existente
        if (autoRefreshInterval) {
            clearInterval(autoRefreshInterval);
        }
        
        // Crear nuevo intervalo para actualizar cada 10 segundos
        autoRefreshInterval = setInterval(() => {
            console.log('🔄 Auto-refrescando lista de batallas...');
            fetchBattles(null, true); // Mostrar indicador en auto-refresh
        }, 10000); // 10 segundos
    }
    
    // Función para detener el auto-refresh
    function stopAutoRefresh() {
        if (autoRefreshInterval) {
            clearInterval(autoRefreshInterval);
            autoRefreshInterval = null;
        }
    }
    
    // Detectar cuando la página se vuelve visible/invisible
    document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
            stopAutoRefresh();
            console.log('📵 Página no visible, deteniendo auto-refresh');
        } else {
            console.log('👁️ Página visible, iniciando auto-refresh y refrescando datos');
            fetchBattles(null, true); // Mostrar indicador al volver
            startAutoRefresh();
        }
    });
    
    // Escuchar mensajes del almacenamiento local para detectar actualizaciones de batalla
    window.addEventListener('storage', (e) => {
        if (e.key === 'battleCompleted' && e.newValue) {
            console.log('🎯 Batalla completada detectada, actualizando lista...');
            setTimeout(() => {
                fetchBattles();
                localStorage.removeItem('battleCompleted'); // Limpiar la señal
            }, 1000);
        }
    });
    
    // También verificar al cargar la página si hay una batalla recién completada
    if (localStorage.getItem('battleCompleted')) {
        console.log('🎯 Batalla completada detectada al cargar, actualizando lista...');
        setTimeout(() => {
            fetchBattles();
            localStorage.removeItem('battleCompleted');
        }, 500);
    }
    
    // Verificar si se debe forzar una actualización por parámetros de URL
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('refresh') === 'true') {
        console.log('🔄 Actualización forzada por URL, refrescando inmediatamente...');
        setTimeout(() => {
            fetchBattles();
            // Limpiar el parámetro de la URL sin recargar la página
            window.history.replaceState({}, document.title, window.location.pathname);
        }, 200);
    }

    // Cargar lista de batallas
    async function fetchBattles(newBattle = null, showRefreshIndicator = false) {
        try {
            const token = localStorage.getItem('token');
            if (!token) throw new Error('No authentication token found');

            console.log('🔍 Solicitando batallas del backend...'); // Debug
            
            // Mostrar indicador de actualización si se solicita
            if (showRefreshIndicator && battlesList) {
                const refreshIndicator = document.createElement('div');
                refreshIndicator.id = 'refresh-indicator';
                refreshIndicator.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    background: var(--text-battle);
                    color: white;
                    padding: 10px 20px;
                    border-radius: 25px;
                    z-index: 1000;
                    font-size: 14px;
                    box-shadow: 0 4px 8px rgba(0,0,0,0.3);
                    animation: pulse 1s infinite;
                `;
                refreshIndicator.innerHTML = '🔄 Actualizando batallas...';
                document.body.appendChild(refreshIndicator);
                
                // Remover el indicador después de 3 segundos máximo
                setTimeout(() => {
                    const indicator = document.getElementById('refresh-indicator');
                    if (indicator) indicator.remove();
                }, 3000);
            }

            const response = await fetch(`${window.API_BASE_URL}/api/battle`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) throw new Error('Error fetching battles');

            const result = await response.json();
            console.log('📊 Respuesta del backend:', result); // Debug

            let battles = Array.isArray(result.data) ? result.data : 
                         Array.isArray(result) ? result : 
                         [];

            console.log('⚔️ Batallas procesadas:', battles); // Debug

            // Si se proporciona una nueva batalla, agregarla al inicio de la lista
            if (newBattle && newBattle.data) {
                battles.unshift(newBattle.data);
            } else if (newBattle) {
                battles.unshift(newBattle);
            }

            // Filtrar batallas válidas (más permisivo)
            const validBattles = battles.filter(battle => battle && (battle.name || battle.battleName) && battle._id);
            console.log('✅ Batallas válidas encontradas:', validBattles.length); // Debug

            if (validBattles.length === 0) {
                battlesList.innerHTML = `
                    <div class="empty-state">
                        <h3>No hay batallas creadas aún</h3>
                        <p>¡Crea tu primera batalla usando el botón de arriba!</p>
                    </div>
                `;
                return;
            }

            battlesList.innerHTML = validBattles.map(battle => {
                // Manejo robusto del nombre de batalla
                const battleName = battle.name || battle.battleName || 'Batalla sin nombre';
                
                // Manejo robusto de equipos
                const heroTeam = battle.heroTeam || battle.heroes || [];
                const villainTeam = battle.villainTeam || battle.villains || [];
                
                console.log(`🏷️ Renderizando batalla: ${battleName}`, {
                    heroTeam: heroTeam.length,
                    villainTeam: villainTeam.length,
                    status: battle.status
                }); // Debug

                return `
                <div class="battle-card">
                    <div class="battle-header">
                        <div class="battle-icon">⚔️</div>
                        <div class="battle-info">
                            <h3 class="battle-name">${battleName}</h3>
                            <div class="battle-status ${getBattleStatusClass(battle.status)}">
                                ${getStatusText(battle.status)}
                            </div>
                        </div>
                    </div>
                    
                    <div class="battle-teams">
                        <div class="team heroes-team">
                            <div class="team-header">
                                <span class="team-icon">🦸‍♂️</span>
                                <span class="team-label">Equipo Héroes (${heroTeam.length})</span>
                            </div>
                            <div class="team-members">
                                ${formatTeamMembers(heroTeam, 'hero')}
                            </div>
                        </div>
                        
                        <div class="vs-divider">
                            <span class="vs-text">VS</span>
                        </div>
                        
                        <div class="team villains-team">
                            <div class="team-header">
                                <span class="team-icon">🦹‍♂️</span>
                                <span class="team-label">Equipo Villanos (${villainTeam.length})</span>
                            </div>
                            <div class="team-members">
                                ${formatTeamMembers(villainTeam, 'villain')}
                            </div>
                        </div>
                    </div>
                    
                    <div class="battle-meta">
                        <div class="meta-item">
                            <span class="meta-icon">🆔</span>
                            <span class="meta-text">ID: ${battle._id.substring(0, 8)}...</span>
                        </div>
                        <div class="meta-item">
                            <span class="meta-icon">�</span>
                            <span class="meta-text">${formatDate(battle.createdAt)}</span>
                        </div>
                        <div class="meta-item">
                            <span class="meta-icon">�️</span>
                            <span class="meta-text">${battle.rounds?.length || 0} rounds</span>
                        </div>
                    </div>
                    
                    <div class="battle-actions">
                        <button class="action-btn primary" onclick="viewBattleDetails('${battle._id}')">
                            <span class="btn-icon">👁️</span>
                            <span class="btn-text">Ver Detalles</span>
                        </button>
                        <button class="action-btn secondary" onclick="simulateBattle('${battle._id}')" 
                                ${battle.status === 'completed' ? 'disabled' : ''}>
                            <span class="btn-icon">⚡</span>
                            <span class="btn-text">${battle.status === 'completed' ? 'Completada' : 'Simular'}</span>
                        </button>
                        <button class="action-btn danger" onclick="deleteBattle('${battle._id}')">
                            <span class="btn-icon">🗑️</span>
                            <span class="btn-text">Eliminar</span>
                        </button>
                    </div>
                        </button>
                    </div>
                </div>
            `;
            }).join('');
            
            // Remover indicador de actualización si existe
            const refreshIndicator = document.getElementById('refresh-indicator');
            if (refreshIndicator) {
                refreshIndicator.remove();
            }
        } catch (error) {
            console.error('Failed to fetch battles:', error);
            
            // Remover indicador de actualización si existe
            const refreshIndicator = document.getElementById('refresh-indicator');
            if (refreshIndicator) {
                refreshIndicator.remove();
            }
            
            battlesList.innerHTML = `
                <div class="empty-state error-state">
                    <h3>Error al cargar las batallas</h3>
                    <p>Por favor, intenta refrescar la página o revisa tu conexión.</p>
                </div>
            `;
        }
    }

    // Función para obtener nombres de equipos
    function getTeamNames(team) {
        if (!team || !Array.isArray(team)) return 'Ninguno';
        return team.map(member => member.name || member).join(', ');
    }

    // Función para obtener texto de estado
    function getStatusText(status) {
        switch (status) {
            case 'active': return '🔥 Activa';
            case 'completed': return '✅ Completada';
            case 'pending': return '⏳ Pendiente';
            case 'in_progress': return '⚡ En Progreso';
            case 'ready': return '🎯 Lista para Simular';
            default: return '❓ Estado Desconocido';
        }
    }

    // Función para formatear fecha
    function formatDate(dateString) {
        if (!dateString) return 'Fecha desconocida';
        try {
            const date = new Date(dateString);
            return date.toLocaleDateString('es-ES', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (error) {
            return 'Fecha inválida';
        }
    }

    // Función para obtener clase CSS del estado de batalla
    function getBattleStatusClass(status) {
        switch (status) {
            case 'active': return 'status-active';
            case 'completed': return 'status-completed';
            case 'pending': return 'status-pending';
            case 'in_progress': return 'status-progress';
            default: return 'status-unknown';
        }
    }

    // Función para formatear miembros del equipo
    function formatTeamMembers(team, type) {
        if (!team || !Array.isArray(team) || team.length === 0) {
            return '<div class="no-members">Sin miembros asignados</div>';
        }
        
        return team.map(member => {
            // Manejo robusto de diferentes formatos de datos
            let name, alias;
            
            if (typeof member === 'string') {
                // Si es solo un string (nombre)
                name = member;
                alias = '';
            } else if (member && typeof member === 'object') {
                // Si es un objeto con propiedades
                name = member.name || member.heroName || member.villainName || 'Sin nombre';
                alias = member.alias || member.heroAlias || member.villainAlias || '';
            } else {
                name = 'Personaje desconocido';
                alias = '';
            }
            
            const aliasText = alias ? `"${alias}"` : '';
            const iconClass = type === 'hero' ? 'member-hero' : 'member-villain';
            
            return `
                <div class="team-member ${iconClass}">
                    <div class="member-name">${name}</div>
                    ${aliasText ? `<div class="member-alias">${aliasText}</div>` : ''}
                </div>
            `;
        }).join('');
    }

    // Crear nueva batalla
    if (createBattleButton) {
        createBattleButton.addEventListener('click', async () => {
            console.log('Botón crear batalla clickeado'); // Debug
            
            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                // Obtener héroes y villanos disponibles
                const [heroesRes, villainsRes] = await Promise.all([
                    fetch(`${window.API_BASE_URL}/api/hero`, { headers: { 'Authorization': `Bearer ${token}` } }),
                    fetch(`${window.API_BASE_URL}/api/villain`, { headers: { 'Authorization': `Bearer ${token}` } })
                ]);

                const heroesData = await heroesRes.json();
                const villainsData = await villainsRes.json();

                const heroes = Array.isArray(heroesData.data) ? heroesData.data : [];
                const villains = Array.isArray(villainsData.data) ? villainsData.data : [];

                if (heroes.length < 3 || villains.length < 3) {
                    alert('Se necesitan al menos 3 héroes y 3 villanos para crear una batalla.');
                    return;
                }

                // Crear modal de selección
                showBattleCreationModal(heroes, villains);

            } catch (error) {
                console.error('Failed to load characters:', error);
                alert('Error al cargar los personajes. Por favor, intenta de nuevo.');
            }
        });
    }

    // Función para mostrar modal de creación de batalla
    function showBattleCreationModal(heroes, villains) {
        // Crear el modal
        const modalHTML = `
            <div id="battle-modal" style="
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.8);
                display: flex;
                justify-content: center;
                align-items: center;
                z-index: 1000;
            ">
                <div style="
                    background: var(--bg-panel);
                    border: 2px solid var(--border-primary);
                    border-radius: 12px;
                    padding: 2rem;
                    max-width: 800px;
                    max-height: 90vh;
                    overflow-y: auto;
                    color: var(--text-primary);
                ">
                    <h2 style="color: var(--text-battle); margin-bottom: 1rem;">⚔️ Crear Nueva Batalla</h2>
                    
                    <div style="margin-bottom: 1.5rem;">
                        <label style="display: block; margin-bottom: 0.5rem; color: var(--text-secondary);">
                            Nombre de la batalla:
                        </label>
                        <input type="text" id="battle-name-input" style="
                            width: 100%;
                            padding: 0.75rem;
                            background: var(--bg-card);
                            border: 2px solid var(--border-secondary);
                            border-radius: 6px;
                            color: var(--text-primary);
                            font-size: 1rem;
                        " placeholder="Ingresa el nombre de la batalla">
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem;">
                        <div>
                            <h3 style="color: var(--text-hero); margin-bottom: 1rem;">🦸‍♂️ Selecciona 3 Héroes:</h3>
                            <div id="heroes-selection" style="max-height: 200px; overflow-y: auto;">
                                ${heroes.map(hero => `
                                    <label style="
                                        display: block;
                                        margin-bottom: 0.5rem;
                                        padding: 0.5rem;
                                        background: var(--bg-card);
                                        border-radius: 6px;
                                        cursor: pointer;
                                        transition: all 0.3s ease;
                                    " class="character-option">
                                        <input type="checkbox" name="hero-selection" value="${hero._id}" data-name="${hero.name}" style="margin-right: 0.5rem;">
                                        ${hero.name} ${hero.alias ? '(' + hero.alias + ')' : ''}
                                    </label>
                                `).join('')}
                            </div>
                            <div id="selected-heroes" style="margin-top: 0.5rem; color: var(--text-hero); font-size: 0.9rem;">
                                Seleccionados: 0/3
                            </div>
                        </div>

                        <div>
                            <h3 style="color: var(--text-villain); margin-bottom: 1rem;">🦹‍♂️ Selecciona 3 Villanos:</h3>
                            <div id="villains-selection" style="max-height: 200px; overflow-y: auto;">
                                ${villains.map(villain => `
                                    <label style="
                                        display: block;
                                        margin-bottom: 0.5rem;
                                        padding: 0.5rem;
                                        background: var(--bg-card);
                                        border-radius: 6px;
                                        cursor: pointer;
                                        transition: all 0.3s ease;
                                    " class="character-option">
                                        <input type="checkbox" name="villain-selection" value="${villain._id}" data-name="${villain.name}" style="margin-right: 0.5rem;">
                                        ${villain.name} ${villain.alias ? '(' + villain.alias + ')' : ''}
                                    </label>
                                `).join('')}
                            </div>
                            <div id="selected-villains" style="margin-top: 0.5rem; color: var(--text-villain); font-size: 0.9rem;">
                                Seleccionados: 0/3
                            </div>
                        </div>
                    </div>

                    <div style="margin-top: 2rem; display: flex; gap: 1rem; justify-content: center;">
                        <button id="create-battle-confirm" style="
                            padding: 0.75rem 1.5rem;
                            background: var(--text-battle);
                            color: white;
                            border: none;
                            border-radius: 6px;
                            cursor: pointer;
                            font-size: 1rem;
                            font-weight: bold;
                        ">⚔️ Crear Batalla</button>
                        <button id="cancel-battle-creation" style="
                            padding: 0.75rem 1.5rem;
                            background: var(--border-secondary);
                            color: white;
                            border: none;
                            border-radius: 6px;
                            cursor: pointer;
                            font-size: 1rem;
                        ">❌ Cancelar</button>
                    </div>
                </div>
            </div>
        `;

        // Agregar modal al DOM
        document.body.insertAdjacentHTML('beforeend', modalHTML);

        // Event listeners para selección
        setupBattleModalListeners();
    }

    // Configurar listeners del modal
    function setupBattleModalListeners() {
        const modal = document.getElementById('battle-modal');
        const heroCheckboxes = document.querySelectorAll('input[name="hero-selection"]');
        const villainCheckboxes = document.querySelectorAll('input[name="villain-selection"]');
        const selectedHeroesDiv = document.getElementById('selected-heroes');
        const selectedVillainsDiv = document.getElementById('selected-villains');
        const createButton = document.getElementById('create-battle-confirm');
        const cancelButton = document.getElementById('cancel-battle-creation');

        // Actualizar contador de selección
        function updateSelectionCount() {
            const selectedHeroes = Array.from(heroCheckboxes).filter(cb => cb.checked);
            const selectedVillains = Array.from(villainCheckboxes).filter(cb => cb.checked);

            selectedHeroesDiv.textContent = `Seleccionados: ${selectedHeroes.length}/3`;
            selectedVillainsDiv.textContent = `Seleccionados: ${selectedVillains.length}/3`;

            // Habilitar/deshabilitar checkboxes si ya se seleccionaron 3
            if (selectedHeroes.length >= 3) {
                heroCheckboxes.forEach(cb => {
                    if (!cb.checked) cb.disabled = true;
                });
            } else {
                heroCheckboxes.forEach(cb => cb.disabled = false);
            }

            if (selectedVillains.length >= 3) {
                villainCheckboxes.forEach(cb => {
                    if (!cb.checked) cb.disabled = true;
                });
            } else {
                villainCheckboxes.forEach(cb => cb.disabled = false);
            }

            // Habilitar botón crear solo si se tienen exactamente 3 de cada uno
            createButton.disabled = !(selectedHeroes.length === 3 && selectedVillains.length === 3);
            createButton.style.opacity = createButton.disabled ? '0.5' : '1';
        }

        // Event listeners para checkboxes
        heroCheckboxes.forEach(cb => cb.addEventListener('change', updateSelectionCount));
        villainCheckboxes.forEach(cb => cb.addEventListener('change', updateSelectionCount));

        // Llamar una vez para establecer estado inicial
        updateSelectionCount();

        // Botón cancelar
        cancelButton.addEventListener('click', () => {
            modal.remove();
        });

        // Botón crear batalla
        createButton.addEventListener('click', async () => {
            const battleName = document.getElementById('battle-name-input').value.trim();
            
            if (!battleName) {
                alert('Por favor, ingresa un nombre para la batalla.');
                return;
            }

            const selectedHeroes = Array.from(heroCheckboxes).filter(cb => cb.checked);
            const selectedVillains = Array.from(villainCheckboxes).filter(cb => cb.checked);

            if (selectedHeroes.length !== 3 || selectedVillains.length !== 3) {
                alert('Debes seleccionar exactamente 3 héroes y 3 villanos.');
                return;
            }

            try {
                const token = localStorage.getItem('token');
                const response = await fetch(`${window.API_BASE_URL}/api/battle`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        name: battleName, // ¡Cambiado de battleName a name!
                        heroTeamIds: selectedHeroes.map(cb => cb.value), // IDs de héroes
                        villainTeamIds: selectedVillains.map(cb => cb.value) // IDs de villanos
                    })
                });

                const result = await response.json();
                
                if (!response.ok) {
                    console.error('Error response:', result);
                    throw new Error(result.message || 'Error creating battle');
                }

                modal.remove();
                fetchBattles(result);
                alert('¡Batalla creada exitosamente!');
            } catch (error) {
                console.error('Failed to create battle:', error);
                alert('Error al crear la batalla: ' + error.message);
            }
        });

        // Cerrar modal al hacer clic fuera
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.remove();
            }
        });
    }

    // Event delegation for battle action buttons
    battlesList.addEventListener('click', async (e) => {
        // Buscar el botón padre si se hizo click en el icono o texto
        const button = e.target.closest('.view-battle, .simulate-battle, .delete-battle');
        if (!button) return;

        const battleId = button.dataset.id;

        if (button.classList.contains('view-battle')) {
            // Funcionalidad de ver detalles
            alert('Funcionalidad de ver detalles próximamente disponible.');
        } else if (button.classList.contains('simulate-battle')) {
            // Funcionalidad de simular batalla
            if (!confirm('¿Deseas simular esta batalla? Se ejecutarán los rounds automáticamente.')) return;
            
            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                // Aquí iría la lógica para simular la batalla
                alert('Funcionalidad de simulación próximamente disponible.');
                
            } catch (error) {
                console.error('Failed to simulate battle:', error);
                alert('Error al simular la batalla. Por favor, intenta de nuevo.');
            }
        } else if (button.classList.contains('delete-battle')) {
            if (!confirm('¿Estás seguro de que quieres eliminar esta batalla?')) return;

            try {
                const token = localStorage.getItem('token');
                if (!token) throw new Error('No authentication token found');

                const response = await fetch(`${window.API_BASE_URL}/api/battle/${battleId}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!response.ok) {
                    const result = await response.json();
                    if (result && result.message) throw new Error(result.message);
                    throw new Error('Error deleting battle');
                }

                fetchBattles();
                alert('Batalla eliminada exitosamente.');
            } catch (error) {
                console.error('Failed to delete battle:', error);
                alert('Error al eliminar la batalla. Por favor, intenta de nuevo.');
            }
        }
    });

    // Funciones globales para los botones de batalla
    window.viewBattleDetails = async function(battleId) {
        try {
            const token = localStorage.getItem('token');
            const response = await fetch(`${window.API_BASE_URL}/api/battle/${battleId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) throw new Error('Error al obtener detalles de la batalla');

            const battleData = await response.json();
            const battle = battleData.data || battleData;

            // Crear modal con detalles de la batalla
            showBattleDetailsModal(battle);

        } catch (error) {
            console.error('Error al cargar detalles de batalla:', error);
            alert('Error al cargar los detalles de la batalla');
        }
    };

    window.simulateBattle = function(battleId) {
        // Redirigir a la arena con la batalla preseleccionada
        window.location.href = `arena-combat.html?battleId=${battleId}&action=simulate`;
    };

    window.deleteBattle = async function(battleId) {
        if (confirm('¿Estás seguro de que quieres eliminar esta batalla? Esta acción no se puede deshacer.')) {
            try {
                const token = localStorage.getItem('token');
                const response = await fetch(`${window.API_BASE_URL}/api/battle/${battleId}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!response.ok) throw new Error('Error al eliminar batalla');

                fetchBattles();
                alert('✅ Batalla eliminada exitosamente');
            } catch (error) {
                console.error('Error al eliminar batalla:', error);
                alert('❌ Error al eliminar la batalla. Intenta de nuevo.');
            }
        }
    };

    // Función para mostrar modal de detalles
    function showBattleDetailsModal(battle) {
        const modalHtml = `
            <div class="modal-overlay" id="battleDetailsModal">
                <div class="modal-content battle-details-modal">
                    <div class="modal-header">
                        <h2>🏟️ Detalles de Batalla</h2>
                        <button class="modal-close" onclick="closeBattleDetailsModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="battle-overview">
                            <h3>${battle.name || battle.battleName || 'Batalla sin nombre'}</h3>
                            <div class="battle-status-large ${getBattleStatusClass(battle.status)}">
                                ${getStatusText(battle.status)}
                            </div>
                        </div>

                        <div class="battle-content-wrapper">
                            <div class="battle-horizontal-content">
                                <!-- Sección de Información General -->
                                <div class="battle-section general-info-section">
                                    <h4>📊 Información General</h4>
                                    <div class="section-content">
                                        <div class="info-card">
                                            <div class="info-item">
                                                <span class="label">ID:</span>
                                                <span class="value">${battle._id}</span>
                                            </div>
                                            <div class="info-item">
                                                <span class="label">Creada:</span>
                                                <span class="value">${formatDate(battle.createdAt)}</span>
                                            </div>
                                            <div class="info-item">
                                                <span class="label">Estado:</span>
                                                <span class="value">${getStatusText(battle.status)}</span>
                                            </div>
                                            <div class="info-item">
                                                <span class="label">Rounds:</span>
                                                <span class="value">${battle.rounds?.length || 0}</span>
                                            </div>
                                        </div>

                                        <!-- Equipos debajo de la información general -->
                                        <div class="teams-grid">
                                            <div class="team-card heroes-card">
                                                <h5>🦸 Equipo de Héroes</h5>
                                                <div class="team-members-list">
                                                    ${renderDetailedTeam(battle.heroTeam || battle.heroes || [], 'hero')}
                                                </div>
                                            </div>
                                            <div class="team-card villains-card">
                                                <h5>🦹 Equipo de Villanos</h5>
                                                <div class="team-members-list">
                                                    ${renderDetailedTeam(battle.villainTeam || battle.villains || [], 'villain')}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Sección de Estadísticas -->
                                <div class="battle-section stats-section">
                                    <h4>⚔️ Progreso de Batalla</h4>
                                    <div class="section-content">
                                        ${renderBattleProgress(battle)}
                                    </div>
                                </div>

                                <!-- Sección de Rounds (si existen) -->
                                ${battle.rounds && battle.rounds.length > 0 ? `
                                <div class="battle-section rounds-section">
                                    <h4>🎲 Historial de Rounds</h4>
                                    <div class="section-content">
                                        ${renderRoundsDetails(battle.rounds)}
                                    </div>
                                </div>
                                ` : ''}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHtml);
    }

    window.closeBattleDetailsModal = function() {
        const modal = document.getElementById('battleDetailsModal');
        if (modal) {
            modal.remove();
        }
    };

    // Función para renderizar progreso de batalla
    function renderBattleProgress(battle) {
        const totalRounds = battle.rounds?.length || 0;
        const completedRounds = battle.rounds?.filter(r => r.status === 'completed').length || 0;
        const heroWins = battle.rounds?.filter(r => r.winner && r.winner.includes('hero')).length || 0;
        const villainWins = battle.rounds?.filter(r => r.winner && r.winner.includes('villain')).length || 0;

        return `
            <div class="progress-stats">
                <div class="stat-item">
                    <span class="stat-label">Rounds completados:</span>
                    <span class="stat-value">${completedRounds}/${totalRounds}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Victorias héroes:</span>
                    <span class="stat-value hero-color">${heroWins}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Victorias villanos:</span>
                    <span class="stat-value villain-color">${villainWins}</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${totalRounds > 0 ? (completedRounds / totalRounds) * 100 : 0}%"></div>
                </div>
            </div>
        `;
    }

    // Función para renderizar equipo detallado
    function renderDetailedTeam(team, type) {
        if (!team || team.length === 0) {
            return '<p class="no-team-members">No hay miembros en este equipo</p>';
        }

        return team.map(member => {
            const name = member.name || member.realName || 'Desconocido';
            const alias = member.alias || member.superheroName || 'Sin alias';
            return `
                <div class="team-member-detail ${type}">
                    <div class="member-info">
                        <div class="member-name">${name}</div>
                        <div class="member-alias">"${alias}"</div>
                    </div>
                    <div class="member-stats">
                        <span class="stat">⚡ ${member.power || member.powers || 'N/A'}</span>
                        <span class="stat">💪 ${member.strength || 'N/A'}</span>
                    </div>
                </div>
            `;
        }).join('');
    }

    // Función para renderizar detalles de rounds
    function renderRoundsDetails(rounds) {
        return `
            <div class="rounds-section">
                <h4>🎮 Historial de Rounds</h4>
                <div class="rounds-list">
                    ${rounds.map((round, index) => `
                        <div class="round-item ${round.status}">
                            <div class="round-header">
                                <span class="round-number">Round ${index + 1}</span>
                                <span class="round-status">${round.status === 'completed' ? '✅' : '⏳'}</span>
                            </div>
                            ${round.status === 'completed' && round.winner ? `
                                <div class="round-result">
                                    <span class="winner">🏆 Ganador: ${round.winner}</span>
                                </div>
                            ` : ''}
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    // Initialize page
    fetchBattles();
    startAutoRefresh(); // Iniciar actualización automática
    console.log('🚀 Sistema de batallas inicializado con auto-refresh cada 10 segundos');
});
