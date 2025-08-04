// Villain: Modelo que representa un villano.
// Incluye atributos como id, nombre, alias, ciudad, organización, y metadatos de contribución comunitaria.

import mongoose from 'mongoose';

const VillainSchema = new mongoose.Schema({
    name: { type: String, required: true },
    alias: { type: String, required: true },
    city: { type: String, required: true },
    team: { type: String }, // Cambiado de organization a team para coincidir con los datos
    organization: { type: String }, // Mantener para compatibilidad
    power: { type: Number, default: 5 }, // Agregar campos que están en los datos
    defense: { type: Number, default: 5 },
    createdBy: { type: String },
    updatedBy: { type: String },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
});

const Villain = mongoose.model('Villain', VillainSchema);

export default Villain;
