// profile.js - Lógica para perfil de usuario

async function loadComponents() {
    await Promise.all([
        loadComponent('/components/header.html', 'header-container'),
        loadComponent('/components/sidebar.html', 'sidebar-container'),
        loadComponent('/components/footer.html', 'footer-container'),
        loadComponent('/components/modals.html', 'modal-container')
    ]);
}

async function fetchProfile() {
    try {
        const response = await api.get('/api/user/me');
        return response.data;
    } catch (error) {
        showError('Error al cargar perfil');
        return null;
    }
}

function renderProfile(profile) {
    const container = document.getElementById('profile-container');
    if (!profile) {
        container.innerHTML = '<p>No se pudo cargar el perfil.</p>';
        return;
    }
    container.innerHTML = `
        <div class="profile-card retro-border">
            <img src="${profile.avatar || '/assets/images/ui/avatar-default.png'}" alt="Avatar" class="profile-avatar">
            <h2>${profile.nickname || profile.username}</h2>
            <p>Email: ${profile.email}</p>
            <p>Rol: ${profile.role}</p>
        </div>
    `;
}

function openEditProfileModal(profile) {
    openModal({
        title: 'Editar perfil',
        content: `
            <form id="edit-profile-form">
                <input type="email" name="email" value="${profile.email}" placeholder="Email" required>
                <input type="text" name="nickname" value="${profile.nickname || ''}" placeholder="Nickname">
                <input type="url" name="avatar" value="${profile.avatar || ''}" placeholder="Avatar URL">
                <input type="password" name="currentPassword" placeholder="Contraseña actual" required>
                <input type="password" name="newPassword" placeholder="Nueva contraseña">
                <button type="submit" class="primary-btn">Guardar</button>
            </form>
        `
    });
    document.getElementById('edit-profile-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        const form = e.target;
        const data = {
            email: form.email.value,
            nickname: form.nickname.value,
            avatar: form.avatar.value,
            currentPassword: form.currentPassword.value,
            newPassword: form.newPassword.value
        };
        try {
            await api.put('/api/user/me', data);
            closeModal();
            loadProfile();
        } catch (error) {
            showError('Error al actualizar perfil');
        }
    });
}

async function loadProfile() {
    const profile = await fetchProfile();
    renderProfile(profile);
    document.getElementById('edit-profile-btn').onclick = () => openEditProfileModal(profile);
}

async function init() {
    await loadComponents();
    loadProfile();
}

document.addEventListener('DOMContentLoaded', init);
