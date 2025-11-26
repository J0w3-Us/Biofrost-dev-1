const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// Datos simulados: Recetas estilo "Kinich" (Cocina Yucateca/Mexicana Gourmet)
const recetas = [
    {
        id: 1,
        nombre: "Cochinita Pibil",
        descripcion: "Carne de cerdo marinada en achiote y jugo de naranja agria, cocida en hoja de plátano.",
        tiempo: "4 horas",
        dificultad: "Alta",
        imagen: "https://images.unsplash.com/photo-1564834724105-918b73d1b9e0?q=80&w=800&auto=format&fit=crop",
        ingredientes: ["Cerdo", "Achiote", "Naranja Agria", "Hoja de Plátano", "Cebolla Morada"]
    },
    {
        id: 2,
        nombre: "Sopa de Lima",
        descripcion: "Caldo de pollo ligero con un toque de lima y especias yucatecas, servido con tiras de tortilla frita.",
        tiempo: "45 min",
        dificultad: "Media",
        imagen: "https://images.unsplash.com/photo-1547592180-85f173990554?q=80&w=800&auto=format&fit=crop",
        ingredientes: ["Pollo", "Lima", "Tortilla", "Pimiento", "Tomate"]
    },
    {
        id: 3,
        nombre: "Poc Chuc",
        descripcion: "Filetes de cerdo marinados en naranja agria y asados al carbón.",
        tiempo: "30 min",
        dificultad: "Media",
        imagen: "https://images.unsplash.com/photo-1624300603538-1207400f4116?q=80&w=800&auto=format&fit=crop",
        ingredientes: ["Lomo de Cerdo", "Naranja Agria", "Cebolla", "Rábano", "Frijol"]
    },
    {
        id: 4,
        nombre: "Papadzules",
        descripcion: "Tortillas rellenas de huevo cocido bañadas en salsa de pepita de calabaza.",
        tiempo: "1 hora",
        dificultad: "Alta",
        imagen: "https://images.unsplash.com/photo-1606850780554-b55ea2ce98ff?q=80&w=800&auto=format&fit=crop",
        ingredientes: ["Tortilla", "Huevo", "Pepita de Calabaza", "Epazote", "Tomate"]
    }
];

// Datos simulados: Comandas activas
const comandas = [
    { id: 101, mesa: 4, mesero: "Luis", estado: "Pendiente", items: ["2x Sopa de Lima", "1x Cochinita Pibil"], hora: "14:15" },
    { id: 102, mesa: 2, mesero: "Maria", estado: "En Proceso", items: ["1x Poc Chuc", "1x Papadzules"], hora: "14:20" }
];

// Endpoint 1: Recetas (Catálogo)
app.get('/api/recetas', (req, res) => {
    res.json({
        success: true,
        data: recetas
    });
});

// Endpoint 2: Comandas (Pedidos)
app.get('/api/comandas', (req, res) => {
    res.json({
        success: true,
        data: comandas
    });
});

app.listen(port, () => {
    console.log(`🔥 API Cocina Kinich corriendo en http://localhost:${port}`);
});
