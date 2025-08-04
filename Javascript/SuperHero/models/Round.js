import mongoose from 'mongoose';

const RoundSchema = new mongoose.Schema({
    battleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Battle',
        required: true
    },
    roundIndex: {
        type: Number,
        required: true
    },
    hero: {
        type: Object,
        required: true
    },
    villain: {
        type: Object,
        required: true
    },
    heroHealth: {
        type: Number,
        default: 100
    },
    villainHealth: {
        type: Number,
        default: 100
    },
    basicAttacksUsed: {
        type: Number,
        default: 0
    },
    specialAttacksUsed: {
        type: Number,
        default: 0
    },
    result: {
        type: String,
        default: null
    }
});

const Round = mongoose.model('Round', RoundSchema);

export default Round;
