import express from 'express';
import cors from 'cors';
import herocontroller from './controllers/heroController.js';
import villaincontroller from './controllers/villainController.js';
import battlecontroller from './controllers/battleController.js';
import roundcontroller from './controllers/roundController.js';
import authcontroller from './controllers/authController.js';
import { swaggerUi, specs } from './config/swagger.js';
import authenticateToken from './middleware/auth.js';
import connectDB from './config/db.js';
import path from 'path';
import { fileURLToPath } from 'url';

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Aquí va la configuración de CORS optimizada para Render
const corsOptions = {
    origin: function (origin, callback) {
        // Permitir orígenes específicos en producción
        const allowedOrigins = [
            'https://superhero-1-3gmw.onrender.com',
            'http://localhost:3000',
            'http://localhost:4000',
            'http://127.0.0.1:3000',
            'http://127.0.0.1:4000'
        ];
        
        // En desarrollo o si no hay origen (aplicaciones móviles, Postman, etc.)
        if (!origin || allowedOrigins.includes(origin) || process.env.NODE_ENV !== 'production') {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
    credentials: true,
    optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
// Middleware para procesar JSON en el body
app.use(express.json());

// Servir archivos estáticos del frontend y assets
app.use(express.static(path.join(__dirname, 'frontend')));
app.use('/assets', express.static(path.join(__dirname, 'frontend', 'assets'), {
    setHeaders: (res, path) => {
        if (path.endsWith('.css')) {
            res.setHeader('Content-Type', 'text/css');
        }
    }
}));

app.use('/pages', express.static(path.join(__dirname, 'frontend', 'pages'), {
    setHeaders: (res, path) => {
        if (path.endsWith('.html')) {
            res.setHeader('Content-Type', 'text/html');
        }
    }
}));

// Middleware de logging
app.use((req, res, next) => {
    console.log(`${req.method} ${req.url}`);
    next();
});

// Conectar a MongoDB
connectDB().then(() => {
    console.log('Database connected successfully');
}).catch((error) => {
    console.error('Database connection failed:', error.message);
});

// 🎮 RUTAS ESPECÍFICAS - Cada ruta va a su página correspondiente
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'auth', 'login.html'));
});

app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'auth', 'login.html'));
});

app.get('/register', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'auth', 'register.html'));
});

app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'dashboard.html'));
});

app.get('/heroes', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'heroes.html'));
});

app.get('/villains', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'villains.html'));
});

app.get('/battles', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'battles.html'));
});

app.get('/arena', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'arena-combat.html'));
});

app.get('/team', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'team.html'));
});

app.get('/profile', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'profile.html'));
});

app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'admin.html'));
});

// Rutas con parámetros
app.get('/battle/:id', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'battle-detail.html'));
});

app.get('/arena/:battleId', (req, res) => {
    res.sendFile(path.join(__dirname, 'frontend', 'pages', 'arena-combat.html'));
});

// Catch-all para rutas no encontradas (SPA fallback)
app.get('*', (req, res, next) => {
    // Si es una ruta de API, continuar al siguiente middleware
    if (req.url.startsWith('/api/')) {
        return next();
    }
    
    // Si es una solicitud de archivo estático específico, intentar servirlo
    if (req.url.includes('.html') || req.url.includes('.js') || req.url.includes('.css')) {
        // Express.static ya debería manejar esto, pero por si acaso
        return next();
    }
    
    // Para cualquier otra ruta, redirigir al login
    console.log(`🔍 Ruta no encontrada: ${req.url}, redirigiendo al login`);
    res.redirect('/login');
});

// Ruta específica para servir páginas del frontend
app.get('/pages/*', (req, res) => {
    const filePath = path.join(__dirname, 'frontend', req.url);
    res.sendFile(filePath, (err) => {
        if (err) {
            res.status(404).sendFile(path.join(__dirname, 'frontend', 'pages', '404.html'));
        }
    });
});

// Debug endpoint temporal para obtener información de la base de datos
app.get('/api/debug/data', async (req, res) => {
    try {
        // Importar modelos dinámicamente
        const { default: Hero } = await import('./models/Hero.js');
        const { default: Villain } = await import('./models/Villain.js');
        const { default: User } = await import('./models/User.js');
        const { default: Battle } = await import('./models/Battle.js');

        const heroCount = await Hero.countDocuments();
        const villainCount = await Villain.countDocuments();
        const userCount = await User.countDocuments();
        const battleCount = await Battle.countDocuments();

        // Obtener algunos IDs de ejemplo
        const sampleHeroes = await Hero.find().limit(3).select('_id alias');
        const sampleVillains = await Villain.find().limit(3).select('_id alias');
        const sampleUsers = await User.find().limit(3).select('_id username role');

        res.json({
            counts: {
                heroes: heroCount,
                villains: villainCount,
                users: userCount,
                battles: battleCount
            },
            samples: {
                heroes: sampleHeroes,
                villains: sampleVillains,
                users: sampleUsers
            },
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            error: error.message,
            stack: error.stack
        });
    }
});

// Configuración de Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

// Rutas de autenticación (sin protección)
app.use('/api/auth', authcontroller)

// Rutas protegidas con autenticación JWT
app.use('/api/hero', authenticateToken, herocontroller)
app.use('/api/villain', authenticateToken, villaincontroller)
app.use('/api/battle', authenticateToken, battlecontroller)
app.use('/api/round', authenticateToken, roundcontroller)

const PORT = process.env.PORT || 4000;
app.listen(PORT, _ => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`API available at: ${process.env.NODE_ENV === 'production' ? 'https://superhero-1-3gmw.onrender.com' : `http://localhost:${PORT}`}`);
    console.log(`Swagger documentation available at: ${process.env.NODE_ENV === 'production' ? 'https://superhero-1-3gmw.onrender.com/api-docs' : `http://localhost:${PORT}/api-docs`}`);
});