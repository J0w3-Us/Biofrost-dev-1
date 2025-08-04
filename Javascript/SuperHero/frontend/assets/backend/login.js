// login.js - Lógica de login modular

document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('login-form');
    if (!form) return;
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        const messageDiv = document.getElementById('login-message');

        // Validación básica frontend
        if (username.length < 3) {
        messageDiv.textContent = 'El nombre de usuario debe tener al menos 3 caracteres.';
        messageDiv.style.color = 'red';
        return;
        }
        if (password.length < 6) {
        messageDiv.textContent = 'La contraseña debe tener al menos 6 caracteres.';
        messageDiv.style.color = 'red';
        return;
        }
        try {
        console.log('Intentando login con:', { username, password: '***' });
        console.log('API baseURL:', window.API.baseURL);
        
        const response = await fetch(`${window.API.baseURL}/api/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        
        console.log('Response status:', response.status);
        const result = await response.json();
        console.log('Login result:', result);
        if (!result.success) {
            if (result.errors && Array.isArray(result.errors)) {
            messageDiv.textContent = result.errors.map(e => e.msg).join(' | ');
            } else {
            messageDiv.textContent = result.message || 'Login fallido';
            }
            messageDiv.style.color = 'red';
            return;
        }
        
        // Guardar el token en localStorage
        const token = result.data ? result.data.token : result.token;
        const usernameFromResult = result.data ? result.data.username : result.username;
        const role = result.data ? result.data.role : result.role || 'user';
        
        if (token) {
            localStorage.setItem('token', token);
            localStorage.setItem('username', usernameFromResult);
            localStorage.setItem('role', role);
        }
        
        messageDiv.textContent = 'Login exitoso';
        messageDiv.style.color = 'green';
        // Redirigir al dashboard o página principal
        setTimeout(() => {
            window.location.href = '../dashboard.html'; // Redirect to dashboard
        }, 1000);
        } catch (err) {
        messageDiv.textContent = 'Error de conexión';
        messageDiv.style.color = 'red';
        }
    });
});
