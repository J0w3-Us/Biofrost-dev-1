// arena.js - Lógica para la pantalla de Arena de combate

document.addEventListener('DOMContentLoaded', () => {
  // Cargar el sidebar
  fetch('/components/sidebar.html')
    .then(r => r.text())
    .then(html => {
      const sidebar = document.getElementById('sidebar');
      if (sidebar) sidebar.innerHTML = html;
    });

  // Cargar batallas activas
  loadActiveBattles();
});

async function loadActiveBattles() {
  const token = localStorage.getItem('token');
  if (!token) return;
  try {
    const res = await fetch(`${window.API.baseURL}/api/battle`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    if (!res.ok) throw new Error('Error al cargar batallas activas');
    const result = await res.json();
    const battles = Array.isArray(result.data) ? result.data : [];
    const list = document.getElementById('active-battles-list');
    if (!list) return;
    if (battles.length === 0) {
      list.innerHTML = '<p>No hay batallas activas.</p>';
      return;
    }
    list.innerHTML = battles.map(b => `
      <div class="battle-card retro-border">
        <h3>${b.battleName || 'Batalla sin nombre'}</h3>
        <p><strong>Héroes:</strong> ${(b.heroes || []).join(', ')}</p>
        <p><strong>Villanos:</strong> ${(b.villains || []).join(', ')}</p>
        <p><strong>Estado:</strong> ${b.status || 'En curso'}</p>
      </div>
    `).join('');
  } catch (err) {
    const list = document.getElementById('active-battles-list');
    if (list) list.innerHTML = '<p>Error al cargar batallas activas.</p>';
  }
}
