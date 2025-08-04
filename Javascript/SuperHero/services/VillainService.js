// VillainService: Proporciona lógica de negocio para gestionar villanos.
// Incluye métodos para CRUD, búsqueda por ciudad en el modelo híbrido.
// 
// ==============================
// MODELO HÍBRIDO - VILLANOS COMPARTIDOS GLOBALMENTE
// Los villanos son accesibles por todos los usuarios para batallas
// Se registra contribución comunitaria (createdBy/updatedBy)
// ==============================

import Villain from '../models/Villain.js';
import mongoose from 'mongoose';

// Obtiene todos los villanos (compartidos globalmente)
async function getAllVillains() {
    try {
        const villains = await Villain.find();
        return villains;
    } catch (error) {
        console.log('Error fetching villains:', error);
        throw error;
    }
}

// Obtiene villanos creados por un usuario específico (contribución comunitaria)
async function getVillainsByCreator(userId) {
    try {
        const villains = await Villain.find({ createdBy: userId });
        return villains;
    } catch (error) {
        console.log('Error fetching villains by creator:', error);
        throw error;
    }
}

// Obtiene un villano por su ID
async function getVillainById(id) {
    try {
        const villain = await Villain.findById(id);
        return villain;
    } catch (error) {
        console.log('Error getting villain by ID:', error);
        throw error;
    }
}

// Crea un nuevo villano con contribución comunitaria
async function createVillain(newVillain, userId) {
    try {
        // Validar que el villano tenga un nombre
        if (!newVillain || !newVillain.name) {
            throw new Error("The villain must have a name");
        }

        const villain = new Villain(newVillain);
        const savedVillain = await villain.save();
        return savedVillain;
    } catch (error) {
        console.log('Error creating villain:', error);
        throw error;
    }
}

// Actualizar villano existente (cualquier usuario puede editar, se registra quién lo hizo)
async function updateVillain(id, updatedVillain, userId) {
    try {
        const villain = await Villain.findByIdAndUpdate(id, updatedVillain, { new: true });
        if (!villain) {
            throw new Error("Villain not found");
        }
        return villain;
    } catch (error) {
        console.log('Error updating villain:', error);
        throw error;
    }
}

// Eliminar villano (cualquier usuario puede eliminar - modelo comunitario)
async function deleteVillain(id, userId) {
    try {
        // Validar que el id es un ObjectId válido
        if (!mongoose.Types.ObjectId.isValid(id)) {
            throw new Error("Invalid villainId format. Must be a valid MongoDB ObjectId.");
        }

        const deletedVillain = await Villain.findByIdAndDelete(id);
        if (!deletedVillain) {
            throw new Error("Villain not found");
        }

        return { 
            message: "Villain deleted successfully",
            deletedBy: userId,
            deletedAt: new Date().toISOString(),
            deletedVillain: deletedVillain
        };
    } catch (error) {
        console.log('Error deleting villain:', error);
        throw error;
    }
}

// Buscar villanos por ciudad (acceso global)
async function getVillainsByCity(city) {
    try {
        const villains = await Villain.find({ city: new RegExp(city, 'i') });
        return villains;
    } catch (error) {
        console.log('Error finding villains by city:', error);
        throw error;
    }
}

// Obtener villanos por IDs (validar que existen)
async function getVillainsByIds(ids) {
    try {
        // Validar que los IDs son ObjectIds válidos
        const invalidIds = ids.filter(id => !mongoose.Types.ObjectId.isValid(id));
        if (invalidIds.length > 0) {
            const error = new Error(`Los siguientes IDs de villanos son inválidos: ${invalidIds.join(', ')}`);
            error.statusCode = 400; // Bad Request
            throw error;
        }

        const villains = await Villain.find({ _id: { $in: ids } });
        if (villains.length !== ids.length) {
            const missingIds = ids.filter(id => !villains.some(villain => villain._id.toString() === id));
            const error = new Error(`One or more villains do not exist. IDs faltantes: ${missingIds.join(', ')}`);
            error.statusCode = 404; // Not Found
            throw error;
        }
        return villains;
    } catch (error) {
        console.log('Error getting villains by IDs:', error);
        throw error;
    }
}

export default {
    getAllVillains,
    getVillainsByCreator,
    getVillainById,
    createVillain,
    updateVillain,
    deleteVillain,
    getVillainsByCity,
    getVillainsByIds
};
