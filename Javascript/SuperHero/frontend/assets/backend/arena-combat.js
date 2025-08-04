// ===== SISTEMA DE COMBATE ARENA =====
// Inspirado en Pokémon Rojo pero adaptado a nuestra Superhero API

class BattleArena {
    constructor() {
        this.battleId = null;
        this.currentBattle = null;
        this.isPlayerTurn = true;
        this.isProcessingTurn = false;
        this.actionLog = [];
        this.init();
    }

    async init() {
        console.log('🏟️ Inicializando Arena de Combate...');
        
        // Ocultar pantalla de carga después de un momento
        setTimeout(() => {
            const loadingScreen = document.querySelector('.loading-arena');
            if (loadingScreen) {
                loadingScreen.style.display = 'none';
            }
        }, 2000);
        
        try {
            // Obtener battleId de los parámetros de la URL o crear una nueva batalla
            const urlParams = new URLSearchParams(window.location.search);
            this.battleId = urlParams.get('battleId');
            
            console.log('🔍 BattleId desde URL:', this.battleId);
            
            if (this.battleId) {
                console.log('📡 Cargando batalla existente...');
                await this.loadBattle();
            } else {
                console.log('🆕 Usando datos mock...');
                await this.showMockBattle();
            }
            
            console.log('🎮 Configurando event listeners...');
            this.setupEventListeners();
            
            console.log('🎨 Renderizando interfaz de batalla...');
            this.renderBattleInterface();
            
            console.log('✅ Arena inicializada correctamente');
        } catch (error) {
            console.error('❌ Error en init():', error);
            // Mostrar contenido mock si hay error
            this.showMockBattle();
            this.setupEventListeners();
            this.renderBattleInterface();
        }
    }

    async createNewBattle() {
        try {
            console.log('🆕 Creando nueva batalla...');
            
            // Datos mock para desarrollo - reemplazar con selección real
            const battleData = {
                name: "Combate de Arena",
                heroTeam: ["675c9e11b22a6f4e63db1e23"], // ID de ejemplo
                villainTeam: ["675c9e11b22a6f4e63db1e25"] // ID de ejemplo
            };

            const response = await fetch(`${window.API.baseURL}/api/battles`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                },
                body: JSON.stringify(battleData)
            });

            if (response.ok) {
                const newBattle = await response.json();
                this.battleId = newBattle._id;
                this.currentBattle = newBattle;
                console.log('✅ Nueva batalla creada:', this.battleId);
            } else {
                throw new Error('Error al crear batalla');
            }
        } catch (error) {
            console.error('❌ Error creando batalla:', error);
            this.showMockBattle();
        }
    }

    async loadBattle() {
        try {
            console.log('📡 Cargando batalla:', this.battleId);
            
            const response = await fetch(`/api/battles/${this.battleId}`, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                }
            });

            if (response.ok) {
                this.currentBattle = await response.json();
                console.log('✅ Batalla cargada:', this.currentBattle);
            } else {
                throw new Error('Batalla no encontrada');
            }
        } catch (error) {
            console.error('❌ Error cargando batalla:', error);
            this.showMockBattle();
        }
    }

    showMockBattle() {
        console.log('🎭 Usando datos mock para desarrollo');
        this.currentBattle = {
            _id: 'mock_battle_id',
            name: 'Combate de Prueba',
            status: 'active',
            enemy: {
                name: 'RHYDON',
                level: 59,
                hp: 180,
                maxHp: 200,
                sprite: '👹',
                type: 'villain'
            },
            player: {
                name: 'CHARIZARD',
                level: 64,
                hp: 196,
                maxHp: 200,
                sprite: '🐲',
                type: 'hero',
                moves: [
                    { name: 'GARRA DRAGÓN', currentPP: 12, maxPP: 15, type: 'dragon' },
                    { name: 'LANZALLAMAS', currentPP: 10, maxPP: 15, type: 'fire' },
                    { name: 'TERREMOTO', currentPP: 8, maxPP: 10, type: 'ground' },
                    { name: 'VUELO', currentPP: 5, maxPP: 15, type: 'flying' }
                ]
            },
            action_log: [
                '¡El combate ha comenzado!',
                'CHARIZARD está listo para la batalla.',
                'RHYDON entra en combate.'
            ],
            isOver: false
        };
    }

    setupEventListeners() {
        // Event listeners para los botones de ataque
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('move-button') && !this.isProcessingTurn) {
                const moveIndex = parseInt(e.target.dataset.moveIndex);
                this.executePlayerAttack(moveIndex);
            }
        });

        // Event listener para cerrar modal de fin de batalla
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('battle-end-close')) {
                this.closeBattleEndModal();
            }
        });
    }

    renderBattleInterface() {
        console.log('🎨 Iniciando renderBattleInterface...');
        console.log('📊 Estado actual de batalla:', this.currentBattle);
        
        const container = document.querySelector('.arena-content') || document.body;
        console.log('📦 Contenedor encontrado:', container);
        
        // Remover pantalla de carga
        const loadingScreen = document.querySelector('.loading-arena');
        if (loadingScreen) {
            console.log('🚫 Removiendo pantalla de carga...');
            loadingScreen.classList.add('fade-out');
            setTimeout(() => loadingScreen.remove(), 500);
        }
        
        if (!this.currentBattle) {
            console.error('❌ No hay datos de batalla para renderizar!');
            return;
        }
        
        console.log('🏗️ Construyendo HTML de batalla...');
        
        const battleHtml = `
            <div class="battle-arena">
                <!-- Zona superior - Enemigo -->
                <div class="enemy-zone">
                    <div class="enemy-status">
                        ${this.renderCombatantStatus(this.currentBattle.enemy, 'enemy')}
                    </div>
                    <div class="combatant-sprite enemy-sprite">
                        ${this.currentBattle.enemy.sprite}
                    </div>
                </div>

                <!-- Zona central - Log de batalla -->
                <div class="battle-log-zone">
                    <div class="battle-log" id="battleLog">
                        ${this.renderBattleLog()}
                    </div>
                </div>

                <!-- Zona inferior - Jugador -->
                <div class="player-zone">
                    <div class="player-status">
                        ${this.renderCombatantStatus(this.currentBattle.player, 'player')}
                    </div>
                    <div class="combatant-sprite player-sprite">
                        ${this.currentBattle.player.sprite}
                    </div>
                </div>

                <!-- Botones de movimientos -->
                <div class="moves-container">
                    ${this.renderMoveButtons()}
                </div>

                <!-- Loading spinner -->
                <div class="turn-loading" id="turnLoading" style="display: none;"></div>
            </div>
        `;

        console.log('📝 HTML generado:', battleHtml.substring(0, 200) + '...');
        console.log('🔄 Insertando HTML en contenedor...');
        
        container.innerHTML = battleHtml;
        
        console.log('✅ HTML insertado, verificando elementos...');
        console.log('🎯 Arena element:', document.querySelector('.battle-arena'));
        console.log('👤 Player zone:', document.querySelector('.player-zone'));
        console.log('👹 Enemy zone:', document.querySelector('.enemy-zone'));
        
        // Animar entrada de mensajes existentes
        console.log('🎬 Animando mensajes...');
        this.animateLogMessages();
        
        console.log('🏁 renderBattleInterface completado');
    }

    renderCombatantStatus(combatant, type) {
        const healthPercent = (combatant.hp / combatant.maxHp) * 100;
        const healthClass = healthPercent > 50 ? '' : healthPercent > 25 ? 'medium' : 'low';

        return `
            <div class="combatant-info">
                <div>
                    <div class="combatant-name">${combatant.name}</div>
                    <div class="combatant-level">Nv. ${combatant.level}</div>
                </div>
            </div>
            <div class="health-bar-container">
                <div class="health-bar-label">HP</div>
                <div class="health-bar">
                    <div class="health-fill ${healthClass}" style="width: ${healthPercent}%"></div>
                </div>
                <div class="health-text">${combatant.hp}/${combatant.maxHp}</div>
            </div>
        `;
    }

    renderMoveButtons() {
        if (!this.currentBattle.player.moves) return '';

        return this.currentBattle.player.moves.map((move, index) => `
            <button class="move-button" data-move-index="${index}" 
                    ${move.currentPP <= 0 ? 'disabled' : ''}>
                <div class="move-name">${move.name}</div>
                <div class="move-info">
                    <span class="move-pp">PP ${move.currentPP}/${move.maxPP}</span>
                    <span class="move-type ${move.type}">${move.type}</span>
                </div>
            </button>
        `).join('');
    }

    renderBattleLog() {
        return this.currentBattle.action_log.map(message => 
            `<div class="log-message">${message}</div>`
        ).join('');
    }

    async executePlayerAttack(moveIndex) {
        if (this.isProcessingTurn || !this.isPlayerTurn) return;

        const selectedMove = this.currentBattle.player.moves[moveIndex];
        if (selectedMove.currentPP <= 0) return;

        this.isProcessingTurn = true;
        this.showTurnLoading(true);

        try {
            // Agregar mensaje de ataque del jugador
            await this.addLogMessage(`${this.currentBattle.player.name} usó ${selectedMove.name.toUpperCase()}.`);

            if (this.battleId === 'mock_battle_id') {
                // Simulación para desarrollo
                await this.simulateAttack(moveIndex);
            } else {
                // Llamada real a la API
                await this.executeRealAttack(moveIndex);
            }

        } catch (error) {
            console.error('❌ Error ejecutando ataque:', error);
            await this.addLogMessage('Error en el ataque. Intenta de nuevo.');
        } finally {
            this.isProcessingTurn = false;
            this.showTurnLoading(false);
        }
    }

    async executeRealAttack(moveIndex) {
        const selectedMove = this.currentBattle.player.moves[moveIndex];

        const response = await fetch(`${window.API.baseURL}/api/battle/attack`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify({
                battleId: this.battleId,
                attackerId: this.currentBattle.player.id,
                move: selectedMove.name
            })
        });

        if (response.ok) {
            const result = await response.json();
            await this.processBattleResult(result);
        } else {
            throw new Error('Error en ataque API');
        }
    }

    async simulateAttack(moveIndex) {
        const selectedMove = this.currentBattle.player.moves[moveIndex];
        
        // Simular daño al enemigo
        const damage = Math.floor(Math.random() * 50) + 20;
        const isEffective = Math.random() > 0.7;
        
        if (isEffective) {
            await this.addLogMessage('¡Es súper efectivo!');
        }
        
        await this.addLogMessage(`${this.currentBattle.enemy.name} recibió ${damage} de daño.`);
        
        // Actualizar HP del enemigo
        this.currentBattle.enemy.hp = Math.max(0, this.currentBattle.enemy.hp - damage);
        this.animateDamage('enemy');
        this.updateHealthBar('enemy');
        
        // Reducir PP del movimiento
        selectedMove.currentPP = Math.max(0, selectedMove.currentPP - 1);
        this.updateMoveButtons();
        
        // Verificar si el enemigo fue derrotado
        if (this.currentBattle.enemy.hp <= 0) {
            await this.addLogMessage(`${this.currentBattle.enemy.name} fue derrotado.`);
            await this.addLogMessage(`¡${this.currentBattle.player.name} ganó!`);
            this.endBattle(true);
            return;
        }
        
        // Turno del enemigo
        await this.executeEnemyTurn();
    }

    async executeEnemyTurn() {
        await this.delay(1000);
        
        const enemyMove = 'ATAQUE ROCA'; // Movimiento aleatorio del enemigo
        await this.addLogMessage(`${this.currentBattle.enemy.name} usó ${enemyMove}.`);
        
        // Simular daño al jugador
        const damage = Math.floor(Math.random() * 40) + 15;
        await this.addLogMessage(`${this.currentBattle.player.name} recibió ${damage} de daño.`);
        
        // Actualizar HP del jugador
        this.currentBattle.player.hp = Math.max(0, this.currentBattle.player.hp - damage);
        this.animateDamage('player');
        this.updateHealthBar('player');
        
        // Verificar si el jugador fue derrotado
        if (this.currentBattle.player.hp <= 0) {
            await this.addLogMessage(`${this.currentBattle.player.name} fue derrotado.`);
            await this.addLogMessage(`${this.currentBattle.enemy.name} ganó...`);
            this.endBattle(false);
            return;
        }
        
        this.isPlayerTurn = true;
    }

    async addLogMessage(message) {
        const logContainer = document.getElementById('battleLog');
        if (!logContainer) return;

        const messageDiv = document.createElement('div');
        messageDiv.className = 'log-message';
        messageDiv.textContent = message;
        
        logContainer.appendChild(messageDiv);
        logContainer.scrollTop = logContainer.scrollHeight;
        
        // Delay para efecto narrativo
        await this.delay(800);
    }

    animateDamage(target) {
        const sprite = document.querySelector(`.${target}-sprite`);
        if (sprite) {
            sprite.classList.add('damaged');
            setTimeout(() => sprite.classList.remove('damaged'), 500);
        }
    }

    updateHealthBar(target) {
        const combatant = target === 'enemy' ? this.currentBattle.enemy : this.currentBattle.player;
        const healthPercent = (combatant.hp / combatant.maxHp) * 100;
        const healthClass = healthPercent > 50 ? '' : healthPercent > 25 ? 'medium' : 'low';
        
        const healthFill = document.querySelector(`.${target}-zone .health-fill`);
        const healthText = document.querySelector(`.${target}-zone .health-text`);
        
        if (healthFill) {
            healthFill.style.width = `${healthPercent}%`;
            healthFill.className = `health-fill ${healthClass}`;
        }
        
        if (healthText) {
            healthText.textContent = `${combatant.hp}/${combatant.maxHp}`;
        }
    }

    updateMoveButtons() {
        const moveButtons = document.querySelectorAll('.move-button');
        moveButtons.forEach((button, index) => {
            const move = this.currentBattle.player.moves[index];
            const ppElement = button.querySelector('.move-pp');
            if (ppElement) {
                ppElement.textContent = `PP ${move.currentPP}/${move.maxPP}`;
            }
            button.disabled = move.currentPP <= 0;
        });
    }

    showTurnLoading(show) {
        const loader = document.getElementById('turnLoading');
        if (loader) {
            loader.style.display = show ? 'block' : 'none';
        }
        
        // Deshabilitar botones durante el turno
        const moveButtons = document.querySelectorAll('.move-button');
        moveButtons.forEach(button => {
            button.disabled = show || this.currentBattle.player.moves[button.dataset.moveIndex].currentPP <= 0;
        });
    }

    endBattle(playerWon) {
        this.currentBattle.isOver = true;
        this.isPlayerTurn = false;
        
        const modalHtml = `
            <div class="battle-end-modal">
                <div class="battle-end-content">
                    <div class="battle-result ${playerWon ? 'victory' : 'defeat'}">
                        ${playerWon ? '🏆' : '💀'}
                    </div>
                    <div class="battle-end-message">
                        ${playerWon ? '¡VICTORIA!' : 'DERROTA...'}
                    </div>
                    <button class="cyber-btn primary battle-end-close">
                        Continuar
                    </button>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    }

    closeBattleEndModal() {
        const modal = document.querySelector('.battle-end-modal');
        if (modal) {
            modal.remove();
        }
        
        // Redirigir a la página de batallas
        window.location.href = '../battles.html';
    }

    animateLogMessages() {
        const messages = document.querySelectorAll('.log-message');
        messages.forEach((message, index) => {
            setTimeout(() => {
                message.style.opacity = '0';
                message.style.transform = 'translateX(-20px)';
                setTimeout(() => {
                    message.style.opacity = '1';
                    message.style.transform = 'translateX(0)';
                }, 50);
            }, index * 200);
        });
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async processBattleResult(result) {
        // Procesar resultado de la API real
        if (result.action_log) {
            for (const message of result.action_log) {
                await this.addLogMessage(message);
            }
        }
        
        // Actualizar estado de la batalla
        if (result.enemy) {
            this.currentBattle.enemy = result.enemy;
            this.updateHealthBar('enemy');
        }
        
        if (result.player) {
            this.currentBattle.player = result.player;
            this.updateHealthBar('player');
            this.updateMoveButtons();
        }
        
        // Verificar fin de batalla
        if (result.isOver) {
            this.endBattle(result.winner === 'player');
        }
    }
}

// Inicializar cuando se carga la página
document.addEventListener('DOMContentLoaded', () => {
    console.log('🎮 DOM cargado, inicializando BattleArena...');
    try {
        new BattleArena();
    } catch (error) {
        console.error('❌ Error inicializando BattleArena:', error);
        
        // Mostrar error en pantalla
        const container = document.querySelector('.arena-content');
        if (container) {
            container.innerHTML = `
                <div style="
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
                    color: #ff7043;
                    flex-direction: column;
                    gap: 1rem;
                    text-align: center;
                    padding: 2rem;
                ">
                    <h2>❌ Error Cargando Arena</h2>
                    <p>No se pudo inicializar el sistema de combate.</p>
                    <p>Error: ${error.message}</p>
                    <button onclick="location.reload()" style="
                        background: #64b5f6;
                        color: white;
                        border: none;
                        padding: 1rem 2rem;
                        border-radius: 8px;
                        cursor: pointer;
                        font-size: 1rem;
                    ">🔄 Reintentar</button>
                </div>
            `;
        }
    }
});

// Exportar para uso global
window.BattleArena = BattleArena;
