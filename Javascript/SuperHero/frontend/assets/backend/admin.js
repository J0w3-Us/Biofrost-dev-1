// admin.js - Lógica para panel de administración

async function loadComponents() {
    await Promise.all([
        loadComponent('/components/header.html', 'header-container'),
        loadComponent('/components/sidebar.html', 'sidebar-container'),
        loadComponent('/components/footer.html', 'footer-container'),
        loadComponent('/components/modals.html', 'modal-container')
    ]);
}

async function fetchUsers() {
    try {
        const response = await api.get('/api/user');
        return response.data;
    } catch (error) {
        showError('Error al cargar usuarios');
        return [];
    }
}

function renderUsers(users) {
    const list = document.getElementById('admin-users-list');
    list.innerHTML = '';
    users.forEach(user => {
        const card = `
            <div class="card user-card retro-border">
                <h2>${user.nickname || user.username}</h2>
                <p>Email: ${user.email}</p>
                <p>Rol: ${user.role}</p>
                <button class="primary-btn" onclick="openEditUserModal('${user._id}', '${user.role}')">Editar rol</button>
                <button class="danger-btn" onclick="openDeleteUserModal('${user._id}')">Eliminar</button>
            </div>
        `;
        list.innerHTML += card;
    });
}

function openEditUserModal(userId, currentRole) {
    openModal({
        title: 'Editar rol de usuario',
        content: `
            <form id="edit-user-role-form">
                <select name="role">
                    <option value="user" ${currentRole === 'user' ? 'selected' : ''}>Usuario</option>
                    <option value="admin" ${currentRole === 'admin' ? 'selected' : ''}>Admin</option>
                </select>
                <button type="submit" class="primary-btn">Guardar</button>
            </form>
        `
    });
    document.getElementById('edit-user-role-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        const form = e.target;
        try {
            await api.put(`/api/user/${userId}/role`, { role: form.role.value });
            closeModal();
            loadUsers();
        } catch (error) {
            showError('Error al actualizar rol');
        }
    });
}

function openDeleteUserModal(userId) {
    openModal({
        title: 'Eliminar usuario',
        content: `
            <p>¿Seguro que deseas eliminar este usuario?</p>
            <button id="confirm-delete-user-btn" class="danger-btn">Eliminar</button>
        `
    });
    document.getElementById('confirm-delete-user-btn').addEventListener('click', async function() {
        try {
            await api.delete(`/api/user/${userId}`);
            closeModal();
            loadUsers();
        } catch (error) {
            showError('Error al eliminar usuario');
        }
    });
}

async function loadUsers() {
    const users = await fetchUsers();
    renderUsers(users);
}

async function init() {
    await loadComponents();
    loadUsers();
}

document.addEventListener('DOMContentLoaded', init);
