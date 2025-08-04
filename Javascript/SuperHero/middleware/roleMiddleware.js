// roleMiddleware: Middleware para verificar roles de usuario
// Incluye funciones para verificar si el usuario es admin o user

/**
 * Middleware para verificar si el usuario autenticado es admin
 */
export const requireAdmin = (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                error: 'AUTH_001',
                message: 'Token no válido o faltante' 
            });
        }

        if (req.user.role !== 'admin') {
            return res.status(403).json({ 
                success: false,
                error: 'AUTH_006',
                message: 'Acceso denegado. Se requiere rol de administrador.' 
            });
        }

        next();
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'AUTH_007',
            message: 'Error en verificación de rol' 
        });
    }
};

/**
 * Middleware para verificar si el usuario autenticado es user
 */
export const requireUser = (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                error: 'AUTH_001',
                message: 'Token no válido o faltante' 
            });
        }

        if (req.user.role !== 'user') {
            return res.status(403).json({ 
                success: false,
                error: 'AUTH_006',
                message: 'Acceso denegado. Se requiere rol de usuario.' 
            });
        }

        next();
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'AUTH_007',
            message: 'Error en verificación de rol' 
        });
    }
};

/**
 * Middleware para verificar que el usuario sea admin o user (cualquier rol válido)
 */
export const requireValidRole = (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                error: 'AUTH_001',
                message: 'Token no válido o faltante' 
            });
        }

        if (!['admin', 'user'].includes(req.user.role)) {
            return res.status(403).json({ 
                success: false,
                error: 'AUTH_004',
                message: 'Rol de usuario no válido' 
            });
        }

        next();
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'AUTH_005',
            message: 'Error en verificación de rol' 
        });
    }
};

/**
 * Middleware que permite a admin hacer todo y a users operaciones básicas
 */
export const allowAdminOrUser = (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                error: 'AUTH_001',
                message: 'Token no válido o faltante' 
            });
        }

        // Admin puede hacer todo
        if (req.user.role === 'admin') {
            return next();
        }

        // User puede hacer operaciones básicas
        if (req.user.role === 'user') {
            return next();
        }

        return res.status(403).json({ 
            success: false,
            error: 'AUTH_004',
            message: 'Rol de usuario no válido' 
        });

    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'AUTH_005',
            message: 'Error en verificación de rol' 
        });
    }
};

/**
 * Middleware para rutas que permiten tanto admin como user (solo lectura para user)
 */
export const allowReadAccess = (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                error: 'AUTH_001',
                message: 'Token no válido o faltante' 
            });
        }

        // GET requests están permitidas para ambos roles
        if (req.method === 'GET') {
            return next();
        }

        // POST, PUT, DELETE solo para admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({ 
                success: false,
                error: 'AUTH_002',
                message: 'Acceso denegado. Solo los administradores pueden modificar datos.' 
            });
        }

        next();
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'AUTH_003',
            message: 'Error en verificación de acceso' 
        });
    }
};
