// battleController: Define las rutas y lógica para gestionar batallas.
// Incluye endpoints para CRUD, simulación de rounds y eliminación de batallas.
// Utiliza BattleService para la lógica de negocio.

import Express from 'express';
import { check, validationResult } from 'express-validator';
import BattleService from '../services/BattleService.js';
import { allowAdminOrUser, requireValidRole } from '../middleware/roleMiddleware.js';
import mongoose from 'mongoose';

const router = Express.Router();

/**
 * @swagger
 * tags:
 *   name: Battles
 *   description: API para gestionar batallas entre héroes y villanos
 */

/**
 * @swagger
 * /api/battle:
 *   get:
 *     summary: Obtiene todas las batallas del usuario autenticado
 *     tags: [Battles]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *         description: Filtra las batallas por estado
 *     responses:
 *       200:
 *         description: Lista de batallas del usuario autenticado
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Battle'
 *       401:
 *         description: Token no válido o faltante
 */
// Endpoint para obtener todas las batallas
router.get("/", requireValidRole, async (req, res) => {
    try {
        const { status } = req.query;
        let battles;

        if (!req.user || !req.user.id) {
            return res.status(401).json({ error: 'Token no válido o faltante' });
        }

        if (status) {
            // Si se solicita un estado, filtra por usuario y estado
            battles = await BattleService.getBattlesByStatusAndUserId(status, req.user.id);
        } else {
            // Siempre filtra por usuario autenticado
            battles = await BattleService.getAllBattlesByUserId(req.user.id);
        }

        res.json(battles);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @swagger
 * /api/battle/{id}:
 *   get:
 *     summary: Obtiene una batalla específica por ID
 *     tags: [Battles]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la batalla
 *     responses:
 *       200:
 *         description: Batalla encontrada
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Battle'
 *       401:
 *         description: Token no válido o faltante
 *       403:
 *         description: No tienes permiso para ver esta batalla
 *       404:
 *         description: Batalla no encontrada
 */
// Endpoint para obtener una batalla específica por ID
router.get("/:id", requireValidRole, async (req, res) => {
    try {
        if (!req.user || !req.user.id) {
            return res.status(401).json({ error: 'Token no válido o faltante' });
        }

        const battle = await BattleService.getBattleById(req.params.id);
        if (!battle) {
            return res.status(404).json({ error: 'Batalla no encontrada' });
        }

        // Verificar que el usuario sea el propietario de la batalla
        if (battle.userId.toString() !== req.user.id.toString()) {
            return res.status(403).json({ error: 'No tienes permiso para ver esta batalla' });
        }

        res.json(battle);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @swagger
 * /api/battle:
 *   post:
 *     summary: Crea una nueva batalla
 *     tags: [Battles]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - heroTeamIds
 *               - villainTeamIds
 *             properties:
 *               name:
 *                 type: string
 *                 description: Nombre de la batalla
 *               heroTeamIds:
 *                 type: array
 *                 items:
 *                   type: string
 *                   description: ID de un héroe (ObjectId válido de MongoDB)
 *                 minItems: 3
 *                 maxItems: 3
 *                 description: Array con exactamente 3 IDs de héroes
 *               villainTeamIds:
 *                 type: array
 *                 items:
 *                   type: string
 *                   description: ID de un villano (ObjectId válido de MongoDB)
 *                 minItems: 3
 *                 maxItems: 3
 *                 description: Array con exactamente 3 IDs de villanos
 *             example:
 *               name: "Battle for New York"
 *               heroTeamIds: ["64b8f1a2e4b0d6c1a1a1a1a1", "64b8f1a2e4b0d6c1a1a1a1a2", "64b8f1a2e4b0d6c1a1a1a1a3"]
 *               villainTeamIds: ["64b8f1a2e4b0d6c1a1a1a1b1", "64b8f1a2e4b0d6c1a1a1a1b2", "64b8f1a2e4b0d6c1a1a1a1b3"]
 *     responses:
 *       201:
 *         description: Batalla creada exitosamente
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: Token no válido o faltante
 */
// Endpoint para crear una nueva batalla
router.post("/", allowAdminOrUser, [
    check('name').notEmpty().withMessage('El nombre de la batalla es requerido'),
    check('heroTeamIds')
        .isArray({ min: 3, max: 3 })
        .withMessage('Debe especificar exactamente 3 héroes'),
    check('heroTeamIds.*')
        .isMongoId()
        .withMessage('Los IDs de héroes deben ser ObjectIds válidos de MongoDB'),
    check('villainTeamIds')
        .isArray({ min: 3, max: 3 })
        .withMessage('Debe especificar exactamente 3 villanos'),
    check('villainTeamIds.*')
        .isMongoId()
        .withMessage('Los IDs de villanos deben ser ObjectIds válidos de MongoDB')
], async (req, res) => {
    try {
        // Verificar errores de validación
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ 
                success: false,
                error: 'BATTLE_001',
                message: 'Errores de validación',
                details: errors.array()
            });
        }

        const { name, heroTeamIds, villainTeamIds } = req.body;

        // Convertir IDs a ObjectId
        const heroIds = heroTeamIds.map(id => new mongoose.Types.ObjectId(id));
        const villainIds = villainTeamIds.map(id => new mongoose.Types.ObjectId(id));

        console.log('[DEBUG] ID Héroes:', heroIds);
        console.log('[DEBUG] ID Villanos:', villainIds);

        // Intentar crear la batalla
        const newBattle = await BattleService.createBattle({
            name,
            heroTeamIds: heroIds,
            villainTeamIds: villainIds
        }, req.user.id);

        res.status(201).json({
            success: true,
            message: 'Batalla creada exitosamente',
            data: newBattle
        });
    } catch (error) {
        // Manejo específico de errores
        if (error.statusCode === 400) {
            return res.status(400).json({
                success: false,
                error: 'BATTLE_002',
                message: 'IDs inválidos proporcionados',
                details: error.message
            });
        }

        if (error.statusCode === 404) {
            return res.status(404).json({
                success: false,
                error: 'BATTLE_006',
                message: 'Uno o más IDs de héroes/villanos no existen',
                details: error.message
            });
        }

        res.status(500).json({ 
            success: false,
            error: 'BATTLE_007',
            message: 'Error interno del servidor',
            details: error.message
        });
    }
});

/**
 * @swagger
 * /api/battle/{id}:
 *   delete:
 *     summary: Elimina una batalla
 *     tags: [Battles]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Batalla eliminada exitosamente
 *       401:
 *         description: Token no válido o faltante
 *       403:
 *         description: No tienes permiso para eliminar esta batalla
 *       404:
 *         description: Batalla no encontrada
 */
// Endpoint para eliminar una batalla
router.delete("/:id", allowAdminOrUser, async (req, res) => {
    try {
        if (!req.user || !req.user.id) {
            return res.status(401).json({ error: 'Token no válido o faltante' });
        }

        // Validar que el id es un ObjectId válido
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ error: 'ID de batalla inválido. Debe ser un ObjectId válido de MongoDB.' });
        }

        const battle = await BattleService.getBattleById(req.params.id);
        if (!battle) {
            return res.status(404).json({ error: 'Batalla no encontrada' });
        }

        if (battle.userId.toString() !== req.user.id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({ 
                success: false,
                error: 'BATTLE_004',
                message: 'No tienes permiso para eliminar esta batalla' 
            });
        }

        const deletedBattle = await BattleService.deleteBattle(
            req.params.id, 
            req.user.id, 
            req.user.role === 'admin'
        );
        res.json({ 
            success: true,
            message: 'Batalla eliminada exitosamente', 
            data: deletedBattle 
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

console.log('[DEBUG] mongoose está definido:', !!mongoose);

export default router;
