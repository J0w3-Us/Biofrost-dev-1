// auth.js - Manejo de autenticación

window.Auth = {
    saveToken: function(token) {
        localStorage.setItem('token', token);
    },

    getToken: function() {
        return localStorage.getItem('token');
    },

    removeToken: function() {
        localStorage.removeItem('token');
    },

    isAuthenticated: function() {
        return !!this.getToken();
    },

    logout: function() {
        this.removeToken();
        window.location.href = '/frontend/pages/auth/login.html';
    }
};

// Para compatibilidad con código existente
function saveToken(token) {
    return window.Auth.saveToken(token);
}

function getToken() {
    return window.Auth.getToken();
}

function removeToken() {
    return window.Auth.removeToken();
}

function isAuthenticated() {
    return window.Auth.isAuthenticated();
}
