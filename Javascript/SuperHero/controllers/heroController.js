import Express from 'express';
import { check, validationResult } from 'express-validator';
import HeroService from '../services/HeroService.js';
import Hero from '../models/Hero.js';
import { allowReadAccess, requireAdmin, requireValidRole, requireUser } from '../middleware/roleMiddleware.js';

const router = Express.Router();

/**
 * @swagger
 * tags:
 *   name: Heroes
 *   description: API para gestionar superhéroes
 */

/**
 * @swagger
 * /api/hero/list:
 *   get:
 *     summary: Obtiene lista simplificada de héroes (ID y nombre)
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista simplificada de héroes
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                     description: ObjectId del héroe
 *                   name:
 *                     type: string
 *                   alias:
 *                     type: string
 *       401:
 *         description: Token no válido o faltante
 */
// GET /api/hero/list - Obtener lista simplificada de héroes
router.get("/list", requireUser, async (req, res) => {
    try {
        const heroes = await HeroService.getHeroesByCreator(req.user.id);
        res.status(200).json(heroes);
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'HERO_001',
            message: 'Error al obtener héroes' 
        });
    }
});

/**
 * @swagger
 * tags:
 *   name: Heroes
 *   description: API para gestionar superhéroes
 */

/**
 * @swagger
 * /api/hero:
 *   get:
 *     summary: Obtiene todos los superhéroes
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de superhéroes
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Hero'
 *       401:
 *         description: Token no válido o faltante
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/hero - Obtener todos los héroes - Permitido para admin y user
router.get("/", async (req, res) => {
    try {
        const userId = req.user._id; // Obtener ID del usuario autenticado

        // Obtener los héroes predeterminados
        const defaultHeroes = await HeroService.getAllHero();

        // Obtener los héroes creados por el usuario
        const userHeroes = await HeroService.getHeroesByCreator(userId);

        res.json({
            success: true,
            data: [...defaultHeroes, ...userHeroes],
            count: defaultHeroes.length + userHeroes.length
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'HERO_001',
            message: error.message
        });
    }
});

/**
 * @swagger
 * /api/hero/{id}:
 *   get:
 *     summary: Obtiene un héroe por su ID
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID del héroe
 *     responses:
 *       200:
 *         description: Héroe encontrado
 *       404:
 *         description: Héroe no encontrado
 */
// GET /api/hero/:id - Obtener héroe por ID
router.get("/:id", allowReadAccess, async (req, res) => {
    try {
        const hero = await HeroService.getHeroById(req.params.id);
        if (!hero) {
            return res.status(404).json({ error: 'Héroe no encontrado' });
        }
        res.json(hero);
    } catch (error) {
        console.log('Error fetching hero by ID:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * @swagger
 * /api/hero/city/{city}:
 *   get:
 *     summary: Busca superhéroes por ciudad
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: city
 *         required: true
 *         schema:
 *           type: string
 *         description: Nombre de la ciudad
 *         example: "New York"
 *     responses:
 *       200:
 *         description: Lista de superhéroes en la ciudad especificada
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Hero'
 *       400:
 *         description: Error en la solicitud
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Token no válido o faltante
 */
// GET /api/hero/city/:city - Buscar héroes por ciudad
router.get("/city/:city", allowReadAccess, async (req, res) => {
    try {
        const heroes = await HeroService.findHeroByCity(req.params.city);
        res.json(heroes);
    } catch (error) {
        res.status(400).json ({error: error.message})
    }
});

/**
 * @swagger
 * /api/hero/list:
 *   get:
 *     summary: Obtiene lista simplificada de héroes (ID y nombre)
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista simplificada de héroes
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                     description: ObjectId del héroe
 *                   name:
 *                     type: string
 *                   alias:
 *                     type: string
 *       401:
 *         description: Token no válido o faltante
 */
// GET /api/hero/list - Obtener lista simplificada de héroes
router.get("/list", allowReadAccess, async (req, res) => {
    try {
        const heroes = await HeroService.getAllHero();
        const simplifiedHeroes = heroes.map(hero => ({
            _id: hero._id,
            name: hero.name,
            alias: hero.alias,
            team: hero.team
        }));
        res.json(simplifiedHeroes);
    } catch (error) {
        res.status(500).json({error: error.message});
    }
});

/**
 * @swagger
 * /api/hero:
 *   post:
 *     summary: Crea un nuevo superhéroe
 *     tags: [Heroes]
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
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Peter Parker"
 *               alias:
 *                 type: string
 *                 example: "Spider-Man"
 *               city:
 *                 type: string
 *                 example: "New York"
 *               team:
 *                 type: string
 *                 example: "Avengers"
 *     responses:
 *       201:
 *         description: Superhéroe creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Hero'
 *       400:
 *         description: Error de validación
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Token no válido o faltante
 *       500:
 *         description: Error del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// POST /api/hero - Crear un nuevo héroe - Solo admin
router.post("/", 
    requireUser,
    [
        check('name').not().isEmpty().withMessage('name is required'),
        check('alias').not().isEmpty().withMessage('alias is required')
    ],

    async (req, res) =>{
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error : errors.array() });
        }

        try {
            const {name, alias, city, team} = req.body;
            const heroData = { name, alias, city, team, createdBy: req.user.id };
            const newHero = await HeroService.createHero(heroData);

            res.status(201).json(newHero);
        } catch (error) {
            res.status(500).json({error: error.message});
        }
});

/**
 * @swagger
 * /api/hero/{id}:
 *   put:
 *     summary: Actualiza un superhéroe existente
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del superhéroe
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
 *               team:
 *                 type: string
 *     responses:
 *       200:
 *         description: Superhéroe actualizado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Hero'
 *       400:
 *         description: Error en la solicitud
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Token no válido o faltante
 */
// PUT /api/hero/:id - Actualizar un héroe - Solo admin
router.put("/:id", requireUser, async (req, res) => {
    try {
        const heroId = req.params.id;
        const hero = await HeroService.getHeroById(heroId);

        if (!hero) {
            return res.status(404).json({
                success: false,
                error: 'HERO_003',
                message: 'Héroe no encontrado'
            });
        }

        // Solo permitir editar si el héroe tiene createdBy y pertenece al usuario
        if (!hero.createdBy || hero.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({
                success: false,
                error: 'NOT_OWNER',
                message: 'No puedes editar este héroe porque no te pertenece o es predeterminado'
            });
        }

        const updatedHero = await HeroService.updateHero(heroId, req.body);
        res.json({
            success: true,
            data: updatedHero
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'HERO_002',
            message: error.message
        });
    }
})

/**
 * @swagger
 * /api/hero/{id}:
 *   delete:
 *     summary: Elimina un superhéroe
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del superhéroe a eliminar
 *     responses:
 *       200:
 *         description: Superhéroe eliminado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Hero deleted successfully"
 *       400:
 *         description: Error en la solicitud
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Token no válido o faltante
 */
// DELETE /api/hero/:id - Eliminar un héroe - Solo admin
router.delete("/:id", requireUser, async (req, res) => {
    try {
        const heroId = req.params.id;

        if (!heroId.match(/^[0-9a-fA-F]{24}$/)) {
            return res.status(400).json({
                success: false,
                error: 'HERO_007',
                message: 'ID de héroe inválido. Debe ser un ObjectId válido de MongoDB.'
            });
        }

        const hero = await HeroService.getHeroById(heroId);
        if (!hero) {
            return res.status(404).json({
                success: false,
                error: 'HERO_003',
                message: 'Héroe no encontrado'
            });
        }

        // Solo permitir eliminar si el héroe tiene createdBy y pertenece al usuario
        if (!hero.createdBy || hero.createdBy.toString() !== req.user.id.toString()) {
            return res.status(403).json({
                success: false,
                error: 'NOT_OWNER',
                message: 'No puedes eliminar este héroe porque no te pertenece o es predeterminado'
            });
        }

        await HeroService.deleteHero(heroId);
        res.json({
            success: true,
            message: 'Héroe eliminado exitosamente'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'HERO_002',
            message: error.message
        });
    }
});

/**
 * @swagger
 * /api/hero/team:
 *   get:
 *     summary: Obtiene todos los héroes cuyo team coincide con el usuario autenticado
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de héroes del equipo
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Hero'
 *       401:
 *         description: Token no válido o faltante
 */
router.get('/team', requireValidRole, async (req, res) => {
    try {
        const heroes = await HeroService.getAllHero({ team: req.user.id });
        res.json(heroes);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @swagger
 * /api/hero/{id}:
 *   put:
 *     summary: Agrega o quita un héroe al equipo del usuario autenticado
 *     tags: [Heroes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID del héroe
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
 *         description: Héroe actualizado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Hero'
 *       403:
 *         description: Acceso denegado
 *       404:
 *         description: Héroe no encontrado
 */
router.put('/:id', requireValidRole, async (req, res) => {
    try {
        const hero = await HeroService.getHeroById(req.params.id);
        if (!hero) return res.status(404).json({ error: 'Héroe no encontrado' });
        if (hero.isDefault) return res.status(403).json({ error: 'Acceso denegado. No puedes modificar personajes predeterminados.' });
        if (hero.team && hero.team !== req.user.id) return res.status(403).json({ error: 'Acceso denegado. Solo el dueño puede modificar su equipo.' });
        hero.team = req.body.action === 'add' ? req.user.id : null;
        await hero.save();
        res.json(hero);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

export default router;