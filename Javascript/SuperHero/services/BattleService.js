// BattleService: Proporciona lógica de negocio para gestionar batallas.
// Incluye métodos para CRUD, simulación de rounds y cálculo de daño.
// 
// ==============================
// MODELO HÍBRIDO - BATALLAS PRIVADAS CON PERSONAJES COMPARTIDOS
// Las batallas mantienen aislamiento por userId
// Los héroes/villanos usados son referencias a recursos compartidos globales
// ==============================

import HeroService from './HeroService.js';
import VillainService from './VillainService.js';
import Battle from '../models/Battle.js';
import Round from '../models/Round.js';
import mongoose from 'mongoose';

class BattleService {
    // Obtiene todas las batallas (para admin - normalmente no se usa)
    async getAllBattles() {
        try {
            const battles = await Battle.find().populate('heroTeam').populate('villainTeam');
            return battles;
        } catch (error) {
            console.log('Error fetching all battles:', error);
            throw error;
        }
    }

    // Obtiene todas las batallas de un usuario específico (PRIVACIDAD MANTENIDA)
    async getAllBattlesByUserId(userId) {
        try {
            const battles = await Battle.find({ userId }).populate('heroTeam').populate('villainTeam');
            return battles;
        } catch (error) {
            console.log('Error fetching battles by user:', error);
            throw error;
        }
    }

    // Obtiene una batalla por su ID
    async getBattleById(id) {
        try {
            const battle = await Battle.findById(id).populate('heroTeam').populate('villainTeam');
            return battle;
        } catch (error) {
            console.log('Error getting battle by ID:', error);
            throw error;
        }
    }

    // Obtiene una batalla por su ID con validación de usuario (PRIVACIDAD MANTENIDA)
    async getBattleByIdAndUserId(id, userId) {
        try {
            const battle = await Battle.findOne({ _id: id, userId }).populate('heroTeam').populate('villainTeam');
            return battle;
        } catch (error) {
            console.log('Error getting battle by ID and user:', error);
            throw error;
        }
    }


    // Crea una nueva batalla (usando personajes compartidos)
    async createBattle(battleData, userId) {
        try {
            const { name, heroTeamIds, villainTeamIds } = battleData;

            // Validar que hay exactamente 3 héroes y 3 villanos
            if (!Array.isArray(heroTeamIds) || heroTeamIds.length !== 3) {
                throw new Error('Debes seleccionar exactamente 3 héroes');
            }
            if (!Array.isArray(villainTeamIds) || villainTeamIds.length !== 3) {
                throw new Error('Debes seleccionar exactamente 3 villanos');
            }

            // Validar que los IDs son ObjectIds válidos
            const invalidHeroIds = heroTeamIds.filter(id => !mongoose.Types.ObjectId.isValid(id));
            const invalidVillainIds = villainTeamIds.filter(id => !mongoose.Types.ObjectId.isValid(id));

            if (invalidHeroIds.length > 0) {
                throw new Error(`Los siguientes IDs de héroes son inválidos: ${invalidHeroIds.join(', ')}`);
            }
            if (invalidVillainIds.length > 0) {
                throw new Error(`Los siguientes IDs de villanos son inválidos: ${invalidVillainIds.join(', ')}`);
            }

            // Validar que los héroes existen
            const heroes = await HeroService.getHeroesByIds(heroTeamIds);
            if (heroes.length !== heroTeamIds.length) {
                throw new Error('Some heroes do not exist');
            }

            // Validar que los villanos existen
            const villains = await VillainService.getVillainsByIds(villainTeamIds);
            if (villains.length !== villainTeamIds.length) {
                throw new Error('Some villains do not exist');
            }

            // Crear la batalla
            const newBattle = new Battle({
                name,
                description: battleData.description || `Batalla entre ${heroes.map(h => h.name).join(', ')} vs ${villains.map(v => v.name).join(', ')}`,
                heroTeam: heroTeamIds,
                villainTeam: villainTeamIds,
                userId,
                status: 'pending'
            });

            const savedBattle = await newBattle.save();

            // Crear rounds separados
            await savedBattle.createRounds();
            
            // Retornar con datos poblados y rounds
            const battleWithPopulated = await Battle.findById(savedBattle._id)
                .populate('heroTeam')
                .populate('villainTeam');
            
            const rounds = await savedBattle.getRounds();
            
            return {
                battle: battleWithPopulated,
                rounds: rounds
            };
        } catch (error) {
            console.log('Error creating battle:', error);
            throw error;
        }
    }

    // Elimina una batalla del repositorio con validación de usuario
    async deleteBattleByUserId(id, userId) {
        try {
            const deletedBattle = await Battle.findOneAndDelete({ _id: id, userId });
            if (!deletedBattle) {
                throw new Error('Battle not found or you are not authorized to delete it');
            }
            return deletedBattle;
        } catch (error) {
            console.log('Error deleting battle:', error);
            throw error;
        }
    }

    // Elimina una batalla (para admins o propietarios)
    async deleteBattle(id, userId = null, isAdmin = false) {
        try {
            // Validar que el id es un ObjectId válido
            if (!mongoose.Types.ObjectId.isValid(id)) {
                throw new Error('Invalid battleId format');
            }

            let deletedBattle;

            if (isAdmin) {
                // Admin puede eliminar cualquier batalla
                deletedBattle = await Battle.findByIdAndDelete(id);
            } else if (userId) {
                // Usuario normal solo puede eliminar sus propias batallas
                deletedBattle = await Battle.findOneAndDelete({ _id: id, userId });
            } else {
                throw new Error('Se requiere userId o permisos de admin');
            }

            if (!deletedBattle) {
                throw new Error('Battle not found or you are not authorized to delete it');
            }

            // También eliminar rounds asociados
            await Round.deleteMany({ battleId: id });

            return deletedBattle;
        } catch (error) {
            console.log('Error deleting battle:', error);
            throw error;
        }
    }

    // Obtiene batallas por su estado y usuario (PRIVACIDAD MANTENIDA)
    async getBattlesByStatusAndUserId(status, userId) {
        try {
            const battles = await Battle.find({ status, userId }).populate('heroTeam').populate('villainTeam');
            return battles;
        } catch (error) {
            console.log('Error getting battles by status and user:', error);
            throw error;
        }
    }
}

export default new BattleService();
