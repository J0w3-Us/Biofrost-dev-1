import express from 'express';
import { body, validationResult } from 'express-validator';
import AuthService from '../services/AuthService.js';

const router = express.Router();
const authService = new AuthService();

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - username
 *         - password
 *       properties:
 *         id:
 *           type: integer
 *           description: ID único del usuario
 *         username:
 *           type: string
 *           description: Nombre de usuario único
 *         token:
 *           type: string
 *           description: Token JWT del usuario
 *     LoginRequest:
 *       type: object
 *       required:
 *         - username
 *         - password
 *       properties:
 *         username:
 *           type: string
 *           description: Nombre de usuario
 *         password:
 *           type: string
 *           description: Contraseña del usuario
 *     RegisterRequest:
 *       type: object
 *       required:
 *         - username
 *         - password
 *       properties:
 *         username:
 *           type: string
 *           description: Nombre de usuario único
 *         password:
 *           type: string
 *           description: Contraseña del usuario
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Registrar un nuevo usuario
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RegisterRequest'
 *     responses:
 *       201:
 *         description: Usuario registrado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: Error de validación
 *       500:
 *         description: Error interno del servidor
 */
router.post('/register', [
    body('username')
        .notEmpty()
        .withMessage('El nombre de usuario es requerido'),
    body('password')
        .notEmpty()
        .withMessage('La contraseña es requerida')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                error: 'AUTH_013',
                message: 'Errores de validación',
                errors: errors.array()
            });
        }

        const { username, password, role } = req.body;
        const user = await authService.register(username, password, role);

        res.status(201).json({
            success: true,
            message: 'Usuario registrado exitosamente',
            token: user.token,
            _id: user._id,
            username: user.username,
            role: user.role,
            isActive: user.isActive
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'AUTH_014',
            message: error.message
        });
    }
});

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Iniciar sesión
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoginRequest'
 *     responses:
 *       200:
 *         description: Login exitoso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: Error de validación
 *       401:
 *         description: Credenciales incorrectas
 *       500:
 *         description: Error interno del servidor
 */
router.post('/login', [
    body('username')
        .notEmpty()
        .withMessage('El nombre de usuario es requerido'),
    body('password')
        .notEmpty()
        .withMessage('La contraseña es requerida')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                error: 'AUTH_011',
                message: 'Errores de validación',
                errors: errors.array()
            });
        }

        const { username, password } = req.body;
        const user = await authService.login(username, password);

        res.json({
            success: true,
            message: 'Login exitoso',
            data: {
                token: user.token,
                username: user.username,
                role: user.role,
                id: user._id
            }
        });
    } catch (error) {
        res.status(401).json({
            success: false,
            error: 'AUTH_012',
            message: error.message
        });
    }
});

export default router;
