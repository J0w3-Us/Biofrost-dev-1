import AuthService from '../services/AuthService.js';

const authService = new AuthService();

export const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

        if (!token) {
            return res.status(401).json({ 
                success: false,
                error: 'AUTH_001',
                message: 'Token de acceso requerido' 
            });
        }

        const decoded = await authService.verifyToken(token);
        
        req.user = { 
            id: decoded.id, 
            username: decoded.username, 
            role: decoded.role,
            dbUser: decoded.dbUser 
        };
        next();
    } catch (error) {
        console.error('Auth error:', error.message);
        return res.status(403).json({ 
            success: false,
            error: 'AUTH_010',
            message: 'Token inválido o expirado'
        });
    }
};

export default authenticateToken;
