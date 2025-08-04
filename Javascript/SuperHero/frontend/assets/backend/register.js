// register.js - Lógica de registro con confirmación de contraseña

document.addEventListener('DOMContentLoaded', function() {
  const form = document.getElementById('register-form');
  if (!form) return;
  form.addEventListener('submit', async function(e) {
    e.preventDefault();
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    // const confirmPassword = document.getElementById('confirm-password').value;
    // const messageDiv = document.getElementById('register-message');

    // Validación de confirmación de contraseña (desactivada, solo referencia):
    // if (password !== confirmPassword) {
    //   messageDiv.textContent = 'Las contraseñas no coinciden.';
    //   messageDiv.style.color = 'red';
    //   return;
    // }
    const messageDiv = document.getElementById('register-message');
    // Validación frontend antes de enviar
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
      const response = await fetch(`${window.API.baseURL}/api/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      const result = await response.json();
      // Mostrar errores específicos si existen
      if (!result.success) {
        if (result.errors && Array.isArray(result.errors)) {
          messageDiv.textContent = result.errors.map(e => e.msg).join(' | ');
        } else {
          messageDiv.textContent = result.message || 'Registro fallido';
        }
        messageDiv.style.color = 'red';
        return;
      }
      messageDiv.textContent = result.message || 'Registro exitoso';
      messageDiv.style.color = 'green';
      window.location.href = '../auth/login.html';
    } catch (err) {
      messageDiv.textContent = 'Error de conexión';
      messageDiv.style.color = 'red';
    }
  });
});
