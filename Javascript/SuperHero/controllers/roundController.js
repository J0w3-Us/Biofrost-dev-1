import Express from 'express';
import RoundService from '../services/RoundService.js';

const roundService = new RoundService();
const router = Express.Router();

/**
 * @swagger
 * tags:
 *   name: Rounds
 *   description: API para gestionar los rounds de las batallas
 */

/**
 * @swagger
 * /api/round/{battleId}:
 *   get:
 *     summary: Obtiene los rounds de una batalla
 *     tags: [Rounds]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: battleId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la batalla
 *     responses:
 *       200:
 *         description: Lista de rounds
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   hero:
 *                     type: object
 *                   villain:
 *                     type: object
 *                   result:
 *                     type: string
 *       401:
 *         description: Token no válido o faltante
 */
router.get('/:battleId', async (req, res) => {
    try {
        const rounds = await roundService.getRoundsByBattleId(req.params.battleId);
        
        // Limpiar y estructurar la respuesta para mostrar solo lo esencial
        const cleanRounds = rounds.map(round => ({
            roundId: round._id,
            roundIndex: round.roundIndex,
            battle: {
                id: round.battleId._id,
                name: round.battleId.name,
                createdBy: round.battleId.createdBy,
                status: round.battleId.status
            },
            hero: round.hero ? {
                id: round.hero._id,
                alias: round.hero.alias,
                team: round.hero.team,
                city: round.hero.city,
                power: round.hero.power,
                defense: round.hero.defense,
                health: round.heroHealth
            } : null,
            villain: round.villain ? {
                id: round.villain._id,
                alias: round.villain.alias,
                team: round.villain.team,
                city: round.villain.city,
                power: round.villain.power,
                defense: round.villain.defense,
                health: round.villainHealth
            } : null,
            result: round.result
        }));
        
        res.status(200).json(cleanRounds);
    } catch (error) {
        res.status(500).json({ error: 'Error fetching rounds' });
    }
});

/**
 * @swagger
 * /api/round/{battleId}/{roundIndex}:
 *   post:
 *     summary: Simula un round específico de una batalla
 *     tags: [Rounds]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: battleId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la batalla
 *       - in: path
 *         name: roundIndex
 *         required: true
 *         schema:
 *           type: number
 *         description: Índice del round
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               target:
 *                 type: string
 *                 enum: [hero, villain]
 *                 description: El objetivo del ataque
 *               attackType:
 *                 type: number
 *                 enum: [1, 2, 3]
 *                 description: El tipo de ataque
 *     responses:
 *       200:
 *         description: Resultado del round
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 result:
 *                   type: string
 *       400:
 *         description: Target o attackType inválido
 *       401:
 *         description: Token no válido o faltante
 */
router.post('/:battleId/:roundIndex', async (req, res) => {
    try {
        const { battleId, roundIndex } = req.params;
        const { target, attackType } = req.body;

        // Log para depuración
        console.log(`Simulating round for battleId: ${battleId}, roundIndex: ${roundIndex}, target: ${target}, attackType: ${attackType}`);

        // Validar entrada
        if (!['hero', 'villain'].includes(target) || ![1, 2, 3].includes(attackType)) {
            return res.status(400).json({ error: 'Invalid target or attackType' });
        }

        // Llamada al servicio
        const simulatedRound = await roundService.simulateRound(battleId, roundIndex, target, attackType);

        // Log del round simulado
        console.log(`Simulated round: ${JSON.stringify(simulatedRound)}`);

        // Respuesta exitosa
        res.status(200).json(simulatedRound);
    } catch (error) {
        if (error.message === 'Battle not found') {
            res.status(404).json({ error: 'Battle not found' });
        } else if (error.message === 'Round not found') {
            res.status(404).json({ error: 'Round not found' });
        } else {
            console.error(`Error simulating round: ${error.message}`);
            res.status(500).json({ error: 'Error simulating round' });
        }
    }
});

export default router;
