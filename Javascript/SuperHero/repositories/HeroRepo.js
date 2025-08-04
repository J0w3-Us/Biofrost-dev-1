import fs from 'fs-extra';
import Hero from '../models/Hero.js';

const filePath = './data/heroes.json';

// ==============================
// MODELO HÍBRIDO - HÉROES COMPARTIDOS GLOBALMENTE
// Los héroes son accesibles por todos los usuarios
// Se registra contribución comunitaria (createdBy/updatedBy)
// ==============================

async function getHeroes(){
    try {
        // Verificar si el archivo existe, si no, devolver array vacío
        if (!(await fs.pathExists(filePath))) {
            console.log('File does not exist:', filePath);
            return [];
        }
        const data = await fs.readJson(filePath);
        return data.map(heroData => new Hero(
            heroData.id, 
            heroData.name, 
            heroData.alias, 
            heroData.city, 
            heroData.team, 
            heroData.power, 
            heroData.defense,
            heroData.createdBy,
            heroData.updatedBy
        ));
    }
    catch (error){
        console.log('Error reading heroes:', error);
        return [];
    }
}

async function SaveHero(heroes) {
    try {
        // Asegurar que el directorio existe
        await fs.ensureDir('./data');
        await fs.writeJson(filePath, heroes, { spaces: 2 });
    }
    catch(error) {
        console.log('Error saving heroes:', error);
        throw error;
    }
}

async function getHeroById(heroId) {
    const heroes = await fs.readJson(filePath);
    return heroes.find(hero => hero.id === heroId);
}

// ==============================
// NUEVOS MÉTODOS PARA MODELO HÍBRIDO
// ==============================

// Crear nuevo héroe con contribución comunitaria
async function createHero(heroData, userId) {
    try {
        const heroes = await fs.readJson(filePath);
        const newId = heroes.length > 0 ? Math.max(...heroes.map(h => h.id)) + 1 : 1;
        
        const newHero = {
            ...heroData,
            id: newId,
            createdBy: userId,
            updatedBy: userId,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        heroes.push(newHero);
        await SaveHero(heroes);
        return newHero;
    } catch (error) {
        console.log('Error creating hero:', error);
        throw error;
    }
}

// Actualizar héroe existente (con registro de quién lo actualizó)
async function updateHero(heroId, updates, userId) {
    try {
        const heroes = await fs.readJson(filePath);
        const heroIndex = heroes.findIndex(h => h.id === heroId);
        
        if (heroIndex === -1) {
            return null;
        }
        
        heroes[heroIndex] = {
            ...heroes[heroIndex],
            ...updates,
            id: heroId, // Preservar ID
            updatedBy: userId,
            updatedAt: new Date().toISOString()
        };
        
        await SaveHero(heroes);
        return heroes[heroIndex];
    } catch (error) {
        console.log('Error updating hero:', error);
        throw error;
    }
}

// Obtener héroes creados por un usuario específico
async function getHeroesByCreator(userId) {
    try {
        const heroes = await getHeroes();
        return heroes.filter(hero => hero.createdBy === userId);
    } catch (error) {
        console.log('Error reading heroes by creator:', error);
        return [];
    }
}

// Validar que los héroes existen (ya no importa la propiedad, son compartidos)
async function validateHeroesExist(heroIds) {
    try {
        const heroes = await getHeroes();
        const existingHeroIds = heroes.map(h => h.id);
        
        for (let heroId of heroIds) {
            if (!existingHeroIds.includes(heroId)) {
                return false;
            }
        }
        return true;
    } catch (error) {
        console.log('Error validating heroes existence:', error);
        return false;
    }
}

export default {
    getHeroes,
    SaveHero,
    getHeroById,
    createHero,
    updateHero,
    getHeroesByCreator,
    validateHeroesExist
};