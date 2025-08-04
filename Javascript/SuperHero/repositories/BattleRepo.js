// BattleRepo: Proporciona acceso a la base de datos de batallas.
// Incluye métodos para obtener, guardar y manipular datos de batallas.
// 
// ==============================
// MODELO HÍBRIDO - BATALLAS PRIVADAS POR USUARIO
// Las batallas mantienen aislamiento por userId
// Los héroes/villanos usados son referencias a recursos compartidos
// ==============================

import fs from 'fs-extra';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const filePath = './data/battles.json';

class BattleRepo {
    constructor() {
        this.filePath = path.join(__dirname, '../data/battles.json');
    }

    // Obtiene todas las batallas desde el archivo JSON
    async getAll() {
        try {
            const data = await fs.readFile(this.filePath, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            console.error('Error reading battles file:', error);
            return [];
        }
    }

    // Obtiene una batalla por su ID
    async getById(id) {
        const battles = await this.getAll();
        return battles.find(battle => battle.id === parseInt(id));
    }

    // Crea una nueva batalla (privada por usuario)
    async create(battle) {
        const battles = await this.getAll();
        const newId = battles.length > 0 ? Math.max(...battles.map(b => b.id)) + 1 : 1;

        const newBattle = {
            ...battle,
            heroTeam: Array.isArray(battle.heroTeam) ? battle.heroTeam : [],
            villainTeam: Array.isArray(battle.villainTeam) ? battle.villainTeam : [],
            id: newId,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        battles.push(newBattle);
        await this.saveAll(battles);
        return newBattle;
    }

    // Actualiza una batalla existente (solo si pertenece al usuario)
    async update(id, updatedBattle) {
        const battles = await this.getAll();
        const index = battles.findIndex(battle => battle.id === parseInt(id));
        if (index !== -1) {
            battles[index] = { 
                ...battles[index], 
                ...updatedBattle, 
                id: parseInt(id),
                updatedAt: new Date().toISOString()
            };
            await this.saveAll(battles);
            return battles[index];
        }
        return null;
    }

    // Actualizar batalla por ID
    async update(battle) {
        const battles = await this.getAll();
        const index = battles.findIndex(b => b.id === battle.id);
        if (index !== -1) {
            battles[index] = battle;
            await fs.writeFile(this.filePath, JSON.stringify(battles, null, 2));
        }
    }

    // Elimina una batalla por su ID
    async delete(id) {
        const battles = await this.getAll();
        const index = battles.findIndex(battle => battle.id === parseInt(id));
        if (index !== -1) {
            const deletedBattle = battles.splice(index, 1)[0];
            await this.saveAll(battles);
            return deletedBattle;
        }
        return null;
    }

    // Guarda todas las batallas en el archivo JSON
    async saveAll(battles) {
        try {
            await fs.writeFile(this.filePath, JSON.stringify(battles, null, 2));
        } catch (error) {
            console.error('Error writing battles file:', error);
            throw error;
        }
    }

    // Obtiene una batalla por su ID (método adicional)
    async getBattleById(battleId) {
        const battles = await this.getAll();
        return battles.find(battle => battle.id === battleId);
    }

    // Obtener batallas filtradas por userId
    async getByUserId(userId) {
        try {
            const battles = await this.getAll();
            return battles.filter(battle => battle.userId === userId);
        } catch (error) {
            console.error('Error reading battles by userId:', error);
            return [];
        }
    }

    // Obtener batalla por ID y verificar que pertenece al usuario
    async getByIdAndUserId(id, userId) {
        try {
            const battle = await this.getById(id);
            if (battle && battle.userId === userId) {
                return battle;
            }
            return null;
        } catch (error) {
            console.error('Error reading battle by ID and userId:', error);
            return null;
        }
    }

    // Obtener batallas por estado y usuario
    async getBattlesByStatusAndUserId(status, userId) {
        try {
            const userBattles = await this.getByUserId(userId);
            return userBattles.filter(battle => battle.status === status);
        } catch (error) {
            console.error('Error reading battles by status and userId:', error);
            return [];
        }
    }

    // Actualizar batalla solo si pertenece al usuario
    async updateByUserOwnership(id, updatedBattle, userId) {
        try {
            const battle = await this.getByIdAndUserId(id, userId);
            if (!battle) {
                return null; // Batalla no encontrada o no pertenece al usuario
            }
            return await this.update(id, updatedBattle);
        } catch (error) {
            console.error('Error updating battle with user ownership:', error);
            return null;
        }
    }

    // Eliminar batalla solo si pertenece al usuario
    async deleteByUserOwnership(id, userId) {
        try {
            const battle = await this.getByIdAndUserId(id, userId);
            if (!battle) {
                return null; // Batalla no encontrada o no pertenece al usuario
            }
            return await this.delete(id);
        } catch (error) {
            console.error('Error deleting battle with user ownership:', error);
            return null;
        }
    }
}

export default BattleRepo;
