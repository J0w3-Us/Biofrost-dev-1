const express = require('express');
const router = express.Router();
const UserService = require('../services/UserService');
const { requireAdmin } = require('../middleware/authMiddleware');

// ...existing routes...

router.get("/role", requireAdmin, async (req, res) => {
    try {
        const roles = await UserService.getAllRoles();
        res.status(200).json(roles);
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: 'USER_001',
            message: 'Error al obtener roles' 
        });
    }
});

module.exports = router;
