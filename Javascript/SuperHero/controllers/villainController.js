/**
 * villainController: Define las rutas y lógica para gestionar villanos.
 * Incluye endpoints para CRUD y búsqueda por ciudad.
 * Utiliza VillainService para la lógica de negocio.
 */

import Express from 'express';
import { check, validationResult } from 'express-validator';
import VillainService from '../services/VillainService.js';
import { allowReadAccess, requireAdmin, requireValidRole } from '../middleware/roleMiddleware.js';

const router = Express.Router();

/**
 * @swagger
 * tags:
 *   name: Villains
 *   description: API para gestionar villanos
 */

/**
 * @swagger
 * /api/villain:
 *   get:
 *     summary: Obtiene todos los villanos
 *     tags: [Villains]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de villanos
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Villain'
 *       401:
 *         description: Token no válido o faltante
 */
// Endpoint para obtener todos los villanos
router.get("/", allowReadAccess, async (req, res) => {
    try {
        const villains = await VillainService.getAllVillains();
        res.json({
            success: true,
            data: villains,
            count: villains.length
        });
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'VILLAIN_005',
            message: error.message 
        });
    }
});

/**
 * @swagger
 * /api/villain/list:
 *   get:
 *     summary: Obtiene lista simplificada de villanos (ID y nombre)
 *     tags: [Villains]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista simplificada de villanos
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                     description: ObjectId del villano
 *                   name:
 *                     type: string
 *                   alias:
 *                     type: string
 *       401:
 *         description: Token no válido o faltante
 */
// GET /api/villain/list - Obtener lista simplificada de villanos
router.get("/list", allowReadAccess, async (req, res) => {
    try {
        const villains = await VillainService.getAllVillains();
        const simplifiedVillains = villains.map(villain => ({
            _id: villain._id,
            name: villain.name,
            alias: villain.alias,
            team: villain.team
        }));
        res.json(simplifiedVillains);
    } catch (error) {
        res.status(500).json({error: error.message});
    }
});

/**
 * @swagger
 * /api/villain/{id}:
 *   get:
 *     summary: Obtiene un villano por ID
 *     tags: [Villains]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del villano
 *     responses:
 *       200:
 *         description: Villano encontrado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Villain'
 *       401:
 *         description: Token no válido o faltante
 *       404:
 *         description: Villano no encontrado
 */
// Endpoint para obtener un villano por ID
// (Eliminado: solo los dueños pueden eliminar sus villanos, ver endpoint más abajo)

/**
 * @swagger
 * /api/villain:
 *   post:
 *     summary: Crea un nuevo villano
 *     tags: [Villains]
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
 *               - alias
 *               - city
 *               - organization
 *             properties:
 *               name:
 *                 type: string
 *               alias:
 *                 type: string
 *               city:
 *                 type: string
 *               organization:
 *                 type: string
 *     responses:
 *       201:
 *         description: Villano creado exitosamente
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: Token no válido o faltante
 */
// Endpoint para crear un nuevo villano
import { requireUser } from '../middleware/roleMiddleware.js';

// Allow any authenticated user to create a villain
router.post("/", requireUser, [
    check('name').notEmpty().withMessage('El nombre es requerido'),
    check('alias').notEmpty().withMessage('El alias es requerido'),
    check('city').notEmpty().withMessage('La ciudad es requerida'),
    check('organization').notEmpty().withMessage('La organización es requerida')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ 
                success: false,
                error: 'VILLAIN_001',
                message: 'Errores de validación',
                errors: errors.array() 
            });
        }

        // Attach createdBy to villain
        const villainData = { ...req.body, createdBy: req.user.id };
        const newVillain = await VillainService.createVillain(villainData);
        res.status(201).json({
            success: true,
            message: 'Villano creado exitosamente',
            data: newVillain
        });
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'VILLAIN_002',
            message: error.message 
        });
    }
});

/**
 * @swagger
 * /api/villain/{id}:
 *   put:
 *     summary: Actualiza un villano
 *     tags: [Villains]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               alias:
 *                 type: string
 *               city:
 *                 type: string
 *               organization:
 *                 type: string
 *     responses:
 *       200:
 *         description: Villano actualizado exitosamente
 *       401:
 *         description: Token no válido o faltante
 *       404:
 *         description: Villano no encontrado
 */
// Endpoint para actualizar un villano existente
// Allow only the owner to update their villain
router.put("/:id", requireUser, async (req, res) => {
    try {
        const villain = await VillainService.getVillainById(req.params.id);
        if (!villain) {
            return res.status(404).json({ error: 'Villano no encontrado' });
        }
        if (!villain.createdBy || villain.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({ error: 'No puedes editar este villano porque no te pertenece o es predeterminado' });
        }
        const updatedVillain = await VillainService.updateVillain(req.params.id, req.body);
        res.json({ success: true, data: updatedVillain });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @swagger
 * /api/villain/{id}:
 *   delete:
 *     summary: Elimina un villano
 *     tags: [Villains]
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
 *         description: Villano eliminado exitosamente
 *       401:
 *         description: Token no válido o faltante
 *       404:
 *         description: Villano no encontrado
 */
// Endpoint para eliminar un villano
// Allow only the owner to delete their villain
router.delete("/:id", requireUser, async (req, res) => {
    try {
        const villainId = req.params.id;
        // Validar formato de ObjectId
        if (!villainId.match(/^[0-9a-fA-F]{24}$/)) {
            return res.status(400).json({ 
                success: false,
                error: 'VILLAIN_005',
                message: 'ID de villano inválido. Debe ser un ObjectId válido de MongoDB.'
            });
        }
        // Verificar si el villano existe antes de intentar eliminarlo
        const villain = await VillainService.getVillainById(villainId);
        if (!villain) {
            return res.status(404).json({ 
                success: false,
                error: 'VILLAIN_003',
                message: `Villano con ID ${villainId} no encontrado` 
            });
        }
        if (!villain.createdBy || villain.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({ 
                success: false,
                error: 'NOT_OWNER',
                message: 'No puedes eliminar este villano porque no te pertenece o es predeterminado'
            });
        }
        const deletedVillain = await VillainService.deleteVillain(villainId, req.user.id);
        res.json({ 
            success: true,
            message: 'Villano eliminado exitosamente', 
            data: deletedVillain 
        });
    } catch (error) {
        console.error('Error deleting villain:', error);
        res.status(500).json({ 
            success: false,
            error: 'VILLAIN_004',
            message: 'Error interno del servidor',
            details: error.message 
        });
    }
});

/**
 * @swagger
 * /api/villain/team:
 *   get:
 *     summary: Obtiene todos los villanos cuyo team coincide con el usuario autenticado
 *     tags: [Villains]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de villanos del equipo
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Villain'
 *       401:
 *         description: Token no válido o faltante
 */
router.get('/team', requireValidRole, async (req, res) => {
    try {
        const villains = await VillainService.getAllVillains({ team: req.user.id });
        res.json(villains);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @swagger
 * /api/villain/{id}:
 *   put:
 *     summary: Agrega o quita un villano al equipo del usuario autenticado
 *     tags: [Villains]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID del villano
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               action:
 *                 type: string
 *                 enum: [add, remove]
 *                 description: Acción a realizar (agregar o quitar)
 *     responses:
 *       200:
 *         description: Villano actualizado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Villain'
 *       403:
 *         description: Acceso denegado
 *       404:
 *         description: Villano no encontrado
 */
router.put('/:id', requireValidRole, async (req, res) => {
    try {
        const villain = await VillainService.getVillainById(req.params.id);
        if (!villain) return res.status(404).json({ error: 'Villano no encontrado' });
        if (villain.isDefault) return res.status(403).json({ error: 'Acceso denegado. No puedes modificar personajes predeterminados.' });
        if (villain.team && villain.team !== req.user.id) return res.status(403).json({ error: 'Acceso denegado. Solo el dueño puede modificar su equipo.' });
        villain.team = req.body.action === 'add' ? req.user.id : null;
        await villain.save();
        res.json(villain);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});


export default router;
