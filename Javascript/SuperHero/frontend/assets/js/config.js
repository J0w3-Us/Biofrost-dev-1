// config.js - Configuración de URLs y constantes

// Detectar si estamos en producción o desarrollo
const isProduction = window.location.hostname !== 'localhost' && 
                     window.location.hostname !== '127.0.0.1' &&
                     window.location.hostname !== '0.0.0.0';

// Configurar URL base según el entorno
let baseURL;
if (isProduction) {
    // En producción, usar la URL de Render
    baseURL = 'https://superhero-1-3gmw.onrender.com';
} else {
    // En desarrollo, usar localhost
    baseURL = 'http://localhost:4000';
}

console.log(`🌐 Entorno detectado: ${isProduction ? 'PRODUCCIÓN' : 'DESARROLLO'}`);
console.log(`🔗 API Base URL configurada: ${baseURL}`);

window.CONFIG = {
    API_BASE_URL: baseURL,
    HEROES_ENDPOINT: '/api/hero',
    VILLAINS_ENDPOINT: '/api/villain',
    BATTLES_ENDPOINT: '/api/battle',
    USERS_ENDPOINT: '/api/user'
};

// Para compatibilidad con código existente
const API_BASE_URL = window.CONFIG.API_BASE_URL;
window.API_BASE_URL = baseURL;
const HEROES_ENDPOINT = window.CONFIG.HEROES_ENDPOINT;
const VILLAINS_ENDPOINT = window.CONFIG.VILLAINS_ENDPOINT;
const BATTLES_ENDPOINT = window.CONFIG.BATTLES_ENDPOINT;
const USERS_ENDPOINT = window.CONFIG.USERS_ENDPOINT;
