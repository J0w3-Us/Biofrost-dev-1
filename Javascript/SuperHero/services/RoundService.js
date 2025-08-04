import Round from '../models/Round.js';
import Battle from '../models/Battle.js';

class RoundService {
    // Obtener todos los rounds de una batalla
    async getRoundsByBattleId(battleId) {
        try {
            const rounds = await Round.find({ battleId })
                .populate('hero')
                .populate('villain')
                .populate('battleId', 'name createdBy status')
                .sort({ roundIndex: 1 });
            return rounds;
        } catch (error) {
            console.log('Error fetching rounds by battle ID:', error);
            throw error;
        }
    }

    // Obtener un round específico
    async getRoundById(roundId) {
        try {
            const round = await Round.findById(roundId)
                .populate('hero')
                .populate('villain')
                .populate('battleId');
            return round;
        } catch (error) {
            console.log('Error fetching round by ID:', error);
            throw error;
        }
    }

    // Simular un round específico
    async simulateRound(battleId, roundIndex, target, attackType) {
        try {
            // Log para depuración
            console.log(`Searching for round with battleId: ${battleId}, roundIndex: ${roundIndex}`);

            // Buscar el round en la base de datos
            const round = await Round.findOne({ battleId, roundIndex })
                .populate('hero')
                .populate('villain')
                .populate('battleId');

            if (!round) {
                throw new Error('Round not found');
            }

            // Log del round encontrado
            console.log(`Round found: ${JSON.stringify(round)}`);

            // Lógica de daño
            const damageMap = { 1: 5, 2: 20, 3: 30 };
            let damage = damageMap[attackType];

            // Validar ataque crítico
            if (attackType === 3) {
                const basicAttacks = round.basicAttacksUsed || 0;
                const specialAttacks = round.specialAttacksUsed || 0;

                if (basicAttacks < 5 && !(basicAttacks >= 3 && specialAttacks >= 1)) {
                    console.log('Critical attack conditions not met, converting to basic attack');
                    damage = damageMap[1];
                    attackType = 1;
                }
            }

            // Aplicar daño
            if (target === 'hero') {
                round.heroHealth = Math.max(0, round.heroHealth - damage);
            } else if (target === 'villain') {
                round.villainHealth = Math.max(0, round.villainHealth - damage);
            }

            // Actualizar contadores de ataque
            if (attackType === 1) {
                round.basicAttacksUsed = (round.basicAttacksUsed || 0) + 1;
            } else if (attackType === 2) {
                round.specialAttacksUsed = (round.specialAttacksUsed || 0) + 1;
            }

            // Determinar si la batalla ha terminado
            if (round.heroHealth === 0 || round.villainHealth === 0) {
                round.result = round.heroHealth === 0 ? 'Villain wins' : 'Hero wins';
            }

            // Guardar el round actualizado en la base de datos
            await round.save();

            // Log después de guardar
            console.log(`Updated round saved: ${JSON.stringify(round)}`);

            // Retornar el round actualizado
            return round;
        } catch (error) {
            console.error(`Error in simulateRound: ${error.message}`);
            throw error;
        }
    }

    // Aplicar daño manual a un round específico
    async applyDamage(roundId, attackType, target) {
        try {
            const round = await this.getRoundById(roundId);
            if (!round) {
                throw new Error('Round not found');
            }

            if (round.result !== null) {
                throw new Error('Round already completed');
            }

            // Calcular daño base según tipo de ataque
            let baseDamage = 0;
            if (attackType === 1) baseDamage = 10;      // Ataque básico
            else if (attackType === 2) baseDamage = 30; // Ataque especial
            else if (attackType === 3) baseDamage = 50; // Ataque crítico
            else throw new Error('Tipo de ataque no válido');

            let damage = 0;
            let attacker, defender;

            if (target === 'villain') {
                // El héroe ataca al villano
                attacker = round.hero;
                defender = round.villain;
                damage = Math.max(0, baseDamage + attacker.power - defender.defense);
                round.villainHealth = Math.max(0, round.villainHealth - damage);
            } else if (target === 'hero') {
                // El villano ataca al héroe
                attacker = round.villain;
                defender = round.hero;
                damage = Math.max(0, baseDamage + attacker.power - defender.defense);
                round.heroHealth = Math.max(0, round.heroHealth - damage);
            } else {
                throw new Error('Target inválido');
            }

            // Verificar si alguien murió
            if (round.heroHealth <= 0 || round.villainHealth <= 0) {
                if (round.heroHealth <= 0 && round.villainHealth <= 0) {
                    round.result = 'draw';
                } else {
                    round.result = round.heroHealth > 0 ? 'hero' : 'villain';
                }
            }

            round.updatedAt = new Date();
            await round.save();

            return {
                round,
                damageInfo: {
                    attacker: attacker.alias,
                    defender: defender.alias,
                    attackType,
                    baseDamage,
                    finalDamage: damage,
                    attackerPower: attacker.power,
                    defenderDefense: defender.defense
                }
            };
        } catch (error) {
            console.log('Error applying damage:', error);
            throw error;
        }
    }

    // Resetear la vida de un round
    async resetRoundHealth(roundId) {
        try {
            const round = await this.getRoundById(roundId);
            if (!round) {
                throw new Error('Round not found');
            }

            round.heroHealth = 100;
            round.villainHealth = 100;
            round.result = null;
            round.heroDamage = 0;
            round.villainDamage = 0;
            round.updatedAt = new Date();

            await round.save();
            return round;
        } catch (error) {
            console.log('Error resetting round health:', error);
            throw error;
        }
    }

    // Simular todos los rounds de una batalla
    async simulateAllRounds(battleId) {
        try {
            const rounds = await this.getRoundsByBattleId(battleId);
            const simulatedRounds = [];

            for (const round of rounds) {
                if (round.result === null) {
                    const simulatedRound = await this.simulateRound(round._id);
                    simulatedRounds.push(simulatedRound);
                } else {
                    simulatedRounds.push(round);
                }
            }

            // Determinar ganador de la batalla
            const heroWins = simulatedRounds.filter(r => r.result === 'hero').length;
            const villainWins = simulatedRounds.filter(r => r.result === 'villain').length;
            
            const battle = await Battle.findById(battleId);
            if (heroWins > villainWins) {
                battle.setWinner('heroes');
            } else {
                battle.setWinner('villains');
            }
            await battle.save();

            return {
                rounds: simulatedRounds,
                winner: battle.winner,
                heroWins,
                villainWins
            };
        } catch (error) {
            console.log('Error simulating all rounds:', error);
            throw error;
        }
    }
}

export default RoundService;
