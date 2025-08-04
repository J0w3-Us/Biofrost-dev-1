import mongoose from 'mongoose';

const BattleSchema = new mongoose.Schema({
    name: { type: String, required: true },
    description: { type: String },
    heroTeam: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Hero',
        required: true
    }],
    villainTeam: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Villain',
        required: true
    }],
    status: {
        type: String,
        enum: ['pending', 'in_progress', 'completed'],
        default: 'pending'
    },
    userId: { type: String, required: true },
    winner: {
        type: String,
        enum: ['heroes', 'villains', null],
        default: null
    },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
    completedAt: { type: Date },
    basicAttacksUsed: {
        type: Number,
        default: 0
    },
    specialAttacksUsed: {
        type: Number,
        default: 0
    }
});

// Método para crear rounds separados
BattleSchema.methods.createRounds = async function() {
    const Round = mongoose.model('Round');
    const rounds = [];
    
    for (let i = 0; i < 3; i++) {
        const round = new Round({
            roundIndex: i + 1,
            battleId: this._id,
            hero: this.heroTeam[i],
            villain: this.villainTeam[i],
            result: null,
            heroDamage: 0,
            villainDamage: 0
        });
        await round.save();
        rounds.push(round);
    }
    
    return rounds;
};

// Método para obtener rounds de esta batalla
BattleSchema.methods.getRounds = async function() {
    const Round = mongoose.model('Round');
    return await Round.find({ battleId: this._id }).sort({ roundIndex: 1 });
};

// Método para establecer ganador
BattleSchema.methods.setWinner = function(winner) {
    this.winner = winner;
    this.status = 'completed';
    this.completedAt = new Date();
    this.updatedAt = new Date();
};

const Battle = mongoose.model('Battle', BattleSchema);

export default Battle;
