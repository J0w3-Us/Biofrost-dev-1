import fs from 'fs-extra';
import path from 'path';
import { fileURLToPath } from 'url';
import User from '../models/User.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class UserRepository {
    constructor() {
        this.filePath = path.join(__dirname, '../data/users.json');
    }

    async readUsers() {
        try {
            const data = await fs.readJson(this.filePath);
            return data.map(userData => new User(
                userData.id,
                userData.username,
                userData.password,
                userData.token
            ));
        } catch (error) {
            console.error('Error reading users:', error);
            return [];
        }
    }

    async writeUsers(users) {
        try {
            // Convertir users a objetos planos sin email ni createdAt
            const usersData = users.map(user => ({
                id: user.id,
                username: user.username,
                password: user.password,
                token: user.token
            }));
            await fs.writeJson(this.filePath, usersData, { spaces: 2 });
        } catch (error) {
            console.error('Error writing users:', error);
            throw error;
        }
    }

    async findById(id) {
        const users = await this.readUsers();
        return users.find(user => user.id === id);
    }

    async findByUsername(username) {
        const users = await this.readUsers();
        return users.find(user => user.username === username);
    }



    async findByToken(token) {
        const users = await this.readUsers();
        return users.find(user => user.token === token);
    }

    async create(userData) {
        const users = await this.readUsers();
        const newId = users.length > 0 ? Math.max(...users.map(u => u.id)) + 1 : 1;

        const userToSave = {
            id: newId,
            username: userData.username,
            password: userData.password,
            token: userData.token
        };

        const allUsers = await this.readUsers();
        const usersData = allUsers.map(user => ({
            id: user.id,
            username: user.username,
            password: user.password,
            token: user.token
        }));

        usersData.push(userToSave);
        await fs.writeJson(this.filePath, usersData, { spaces: 2 });

        return new User(
            userToSave.id,
            userToSave.username,
            userToSave.password,
            userToSave.token
        );
    }

    async update(id, userData) {
        const users = await this.readUsers();
        const index = users.findIndex(user => user.id === id);
        
        if (index === -1) {
            return null;
        }

        users[index] = { ...users[index], ...userData };
        await this.writeUsers(users);
        return users[index];
    }

    async delete(id) {
        const users = await this.readUsers();
        const filteredUsers = users.filter(user => user.id !== id);
        
        if (filteredUsers.length === users.length) {
            return false;
        }

        await this.writeUsers(filteredUsers);
        return true;
    }
}

export default UserRepository;
