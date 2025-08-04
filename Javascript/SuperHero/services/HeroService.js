import Hero from "../models/Hero.js";
import mongoose from 'mongoose';

// ==============================
// MODELO HÍBRIDO - HÉROES COMPARTIDOS GLOBALMENTE
// Los héroes son accesibles por todos los usuarios para batallas
// Se registra contribución comunitaria (createdBy/updatedBy)
// ==============================

// Obtener todos los héroes (compartidos globalmente)
async function getAllHero(){
    try {
        const heroes = await Hero.find();
        return heroes;
    } catch (error) {
        console.log('Error fetching heroes:', error);
        throw error;
    }
}

// Obtener héroes creados por un usuario específico (contribución comunitaria)
async function getHeroesByCreator(userId){
    try {
        const heroes = await Hero.find({ createdBy: userId });
        return heroes;
    } catch (error) {
        console.log('Error fetching heroes by creator:', error);
        throw error;
    }
}

// Crear nuevo héroe (contribución comunitaria)
async function createHero(heroData) {
    try {
        const newHero = new Hero(heroData);
        const savedHero = await newHero.save();
        return savedHero;
    } catch (error) {
        console.log('Error creating hero:', error);
        throw error;
    }
}

// Actualizar héroe existente (cualquier usuario puede editar, se registra quién lo hizo)
async function updateHero(id, updatedHero){
    try {
        const updated = await Hero.findByIdAndUpdate(id, updatedHero, { new: true });
        if (!updated) {
            throw new Error("Hero not found");
        }
        return updated;
    } catch (error) {
        throw error;
    }
}

// Eliminar héroe existente
async function deleteHero(id) {
    try {
        const deleted = await Hero.findByIdAndDelete(id);
        if (!deleted) {
            throw new Error("Hero not found");
        }
        return deleted;
    } catch (error) {
        throw error;
    }
}

// Buscar héroes por ciudad (acceso global)
async function findHeroByCity(city) {
    try {
        const heroes = await Hero.find({ city: new RegExp(city, 'i') });
        return heroes;
    } catch (error) {
        console.log('Error finding heroes by city:', error);
        throw error;
    }
}

// Obtener héroes por IDs (validar que existen)
async function getHeroesByIds(ids) {
    try {
        // Validar que los IDs son ObjectIds válidos
        const invalidIds = ids.filter(id => !mongoose.Types.ObjectId.isValid(id));
        if (invalidIds.length > 0) {
            const error = new Error(`Los siguientes IDs de héroes son inválidos: ${invalidIds.join(', ')}`);
            error.statusCode = 400; // Bad Request
            throw error;
        }

        const heroes = await Hero.find({ _id: { $in: ids } });
        if (heroes.length !== ids.length) {
            const missingIds = ids.filter(id => !heroes.some(hero => hero._id.toString() === id));
            const error = new Error(`One or more heroes do not exist. IDs faltantes: ${missingIds.join(', ')}`);
            error.statusCode = 404; // Not Found
            throw error;
        }
        return heroes;
    } catch (error) {
        console.log('Error getting heroes by IDs:', error);
        throw error;
    }
}

// Obtener héroe por ID
async function getHeroById(heroId) {
    try {
        const hero = await Hero.findById(heroId);
        return hero;
    } catch (error) {
        console.log('Error getting hero by ID:', error);
        throw error;
    }
}

// exporta las funciones del modelo híbrido
export default {
    getAllHero,
    getHeroesByCreator,
    createHero,
    updateHero,
    deleteHero,
    findHeroByCity,
    getHeroesByIds,
    getHeroById
};