import mongoose from 'mongoose';

const UserSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        minlength: 3,
        maxlength: 50
    },
    password: {
        type: String,
        required: true,
        minlength: 6
    },
    role: {
        type: String,
        enum: ['admin', 'user'],
        default: 'user',
        required: true
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// Método para convertir a JSON sin incluir password
UserSchema.methods.toJSON = function() {
    const user = this.toObject();
    delete user.password;
    return user;
};

// Método para verificar si es admin
UserSchema.methods.isAdmin = function() {
    return this.role === 'admin';
};

// Método para verificar si es user
UserSchema.methods.isUser = function() {
    return this.role === 'user';
};

const User = mongoose.model('User', UserSchema);

export default User;
