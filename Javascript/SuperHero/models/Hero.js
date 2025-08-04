import mongoose from 'mongoose';

const HeroSchema = new mongoose.Schema({
    name: { type: String, required: true },
    alias: { type: String, required: true },
    city: { type: String, required: true },
    team: { type: String },
    power: { type: Number, default: 5 },
    defense: { type: Number, default: 5 },
    createdBy: { type: String },
    updatedBy: { type: String },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
});

const Hero = mongoose.model('Hero', HeroSchema, 'heroes');

export default Hero;