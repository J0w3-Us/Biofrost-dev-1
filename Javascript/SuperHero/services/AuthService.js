import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';

class AuthService {
    constructor() {
        this.jwtSecret = process.env.JWT_SECRET || 'superhero_secret_key_2025'; // Usar variable de entorno
        this.saltRounds = 10;
    }

    async register(username, password, role = 'user') {
        try {
            if (!username || !password) {
                throw new Error('Nombre de usuario y contraseña son requeridos');
            }

            // Verificar si el usuario ya existe
            const existingUser = await User.findOne({ username });
            if (existingUser) {
                throw new Error('El nombre de usuario ya existe');
            }

            // Encriptar la contraseña
            const hashedPassword = await bcrypt.hash(password, this.saltRounds);

            // Crear el usuario
            const user = new User({
                username,
                password: hashedPassword,
                role
            });

            await user.save();
            
            // Generar token JWT
            const token = jwt.sign(
                { 
                    id: user._id, 
                    username: user.username,
                    role: user.role 
                },
                this.jwtSecret,
                { expiresIn: '24h' }
            );

            // Retornar usuario con token pero sin contraseña
            return {
                _id: user._id,
                username: user.username,
                role: user.role,
                isActive: user.isActive,
                token: token
            };
        } catch (error) {
            throw error;
        }
    }

    async login(username, password) {
        try {
            if (!username || !password) {
                throw new Error('Nombre de usuario y contraseña son requeridos');
            }

            // Buscar el usuario
            const user = await User.findOne({ username, isActive: true });
            if (!user) {
                throw new Error('Usuario o contraseña incorrectos');
            }

            // Verificar la contraseña
            const isPasswordValid = await bcrypt.compare(password, user.password);
            if (!isPasswordValid) {
                throw new Error('Usuario o contraseña incorrectos');
            }

            // Generar nuevo token
            const token = jwt.sign(
                { 
                    id: user._id, 
                    username: user.username,
                    role: user.role 
                },
                this.jwtSecret,
                { expiresIn: '24h' }
            );

            // Retornar usuario con token pero sin contraseña
            return {
                _id: user._id,
                username: user.username,
                role: user.role,
                isActive: user.isActive,
                token: token
            };
        } catch (error) {
            throw error;
        }
    }

    async verifyToken(token) {
        try {
            // Verificar el token JWT
            const decoded = jwt.verify(token, this.jwtSecret);
            
            // Buscar el usuario en la base de datos
            const user = await User.findById(decoded.id);
            if (!user || !user.isActive) {
                throw new Error('Token inválido');
            }

            return { 
                id: user._id, 
                username: user.username,
                role: user.role,
                dbUser: user 
            };
        } catch (error) {
            throw new Error('Token inválido o expirado');
        }
    }

    async createAdminUser(username, password) {
        try {
            return await this.register(username, password, 'admin');
        } catch (error) {
            throw error;
        }
    }

    async getAllUsers() {
        try {
            return await User.find({ isActive: true }).select('-password');
        } catch (error) {
            throw error;
        }
    }

    async updateUserRole(userId, newRole) {
        try {
            if (!['admin', 'user'].includes(newRole)) {
                throw new Error('Rol no válido');
            }

            const user = await User.findByIdAndUpdate(
                userId, 
                { role: newRole }, 
                { new: true }
            ).select('-password');

            if (!user) {
                throw new Error('Usuario no encontrado');
            }

            return user;
        } catch (error) {
            throw error;
        }
    }
}

export default AuthService;
