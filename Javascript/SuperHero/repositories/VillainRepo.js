import fs from 'fs-extra';
import path from 'path';
import { fileURLToPath } from 'url';
import Villain from '../models/Villain.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ==============================
// MODELO HÍBRIDO - VILLANOS COMPARTIDOS GLOBALMENTE
// Los villanos son accesibles por todos los usuarios
// Se registra contribución comunitaria (createdBy/updatedBy)
// ==============================

class VillainRepo {
    constructor() {
        this.filePath = path.join(__dirname, '../data/villains.json');
    }

    // Obtiene todos los villanos desde el archivo JSON (compartidos globalmente)
    async getAll() {
        try {
            const data = await fs.readFile(this.filePath, 'utf8');
            return JSON.parse(data).map(villainData => ({
                id: villainData.id,
                name: villainData.name,
                alias: villainData.alias,
                team: villainData.team || undefined,
                city: villainData.city,
                organization: villainData.organization,
                power: villainData.power || 5,
                defense: villainData.defense || 5,
                createdBy: villainData.createdBy,
                updatedBy: villainData.updatedBy,
                createdAt: villainData.createdAt,
                updatedAt: villainData.updatedAt
            }));
        } catch (error) {
            console.error('Error reading villains file:', error);
            return [];
        }
    }

    // Obtiene un villano por su ID
    async getById(id) {
        const villains = await this.getAll();
        return villains.find(villain => villain.id === parseInt(id));
    }

    // Crea un nuevo villano con contribución comunitaria
    async create(villain, userId) {
        const villains = await this.getAll();
        const newId = villains.length > 0 ? Math.max(...villains.map(v => v.id)) + 1 : 1;
        
        const newVillain = { 
            ...villain, 
            id: newId,
            createdBy: userId,
            updatedBy: userId,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        villains.push(newVillain);
        await this.saveAll(villains);
        return newVillain;
    }

    // Actualiza un villano existente (con registro de quién lo actualizó)
    async update(id, updatedVillain, userId) {
        const villains = await this.getAll();
        const index = villains.findIndex(villain => villain.id === parseInt(id));
        if (index !== -1) {
            villains[index] = { 
                ...villains[index], 
                ...updatedVillain, 
                id: parseInt(id),
                updatedBy: userId,
                updatedAt: new Date().toISOString()
            };
            await this.saveAll(villains);
            return villains[index];
        }
        return null;
    }

    // Elimina un villano por su ID
    async delete(id) {
        const villains = await this.getAll();
        const index = villains.findIndex(villain => villain.id === parseInt(id));
        if (index !== -1) {
            const deletedVillain = villains.splice(index, 1)[0];
            await this.saveAll(villains);
            return deletedVillain;
        }
        return null;
    }

    // Guarda todos los villanos en el archivo JSON
    async saveAll(villains) {
        try {
            
            await fs.writeFile(this.filePath, JSON.stringify(villains, null, 2));
        } catch (error) {
            console.error('Error writing villains file:', error);
            throw error;
        }
    }

    // Obtener villanos filtrados por userId
    async getByUserId(userId) {
        try {
            const villains = await this.getAll();
            return villains.filter(villain => villain.userId === userId);
        } catch (error) {
            console.error('Error reading villains by userId:', error);
            return [];
        }
    }

    // Obtener villano por ID y verificar que pertenece al usuario
    async getByIdAndUserId(id, userId) {
        try {
            const villain = await this.getById(id);
            if (villain && villain.userId === userId) {
                return villain;
            }
            return null;
        } catch (error) {
            console.error('Error reading villain by ID and userId:', error);
            return null;
        }
    }

    // ==============================
    // NUEVOS MÉTODOS PARA MODELO HÍBRIDO
    // ==============================

    // Obtener villanos creados por un usuario específico
    async getByCreator(userId) {
        try {
            const villains = await this.getAll();
            return villains.filter(villain => villain.createdBy === userId);
        } catch (error) {
            console.error('Error reading villains by creator:', error);
            return [];
        }
    }

    // Validar que los villanos existen (ya no importa la propiedad, son compartidos)
    async validateVillainsExist(villainIds) {
        try {
            const villains = await this.getAll();
            const existingVillainIds = villains.map(v => v.id);
            
            for (let villainId of villainIds) {
                if (!existingVillainIds.includes(villainId)) {
                    return false;
                }
            }
            return true;
        } catch (error) {
            console.error('Error validating villains existence:', error);
            return false;
        }
    }
}

export default new VillainRepo();
