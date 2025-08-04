// BattleForm.js - Componente de formulario para crear batallas

document.addEventListener('DOMContentLoaded', () => {
  const section = document.getElementById('battle-form-section');
  if (!section) return;

  section.innerHTML = `
    <form id="battle-form" class="retro-border">
      <h2>Crear nueva batalla</h2>
      <label>Nombre de la batalla:
        <input type="text" id="battleName" required maxlength="40" autocomplete="off" />
      </label>
      <div class="select-group">
        <label>Héroes (elige 3):
          <select id="heroes-select" multiple size="5" required></select>
        </label>
        <label>Villanos (elige 3):
          <select id="villains-select" multiple size="5" required></select>
        </label>
      </div>
      <button type="submit" class="retro-button">Iniciar batalla</button>
    </form>
    <div id="battle-form-msg"></div>
  `;

  // Cargar personajes
  loadCharacters();

  // Validación y envío
  document.getElementById('battle-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const battleName = document.getElementById('battleName').value.trim();
    const heroes = Array.from(document.getElementById('heroes-select').selectedOptions).map(opt => opt.value);
    const villains = Array.from(document.getElementById('villains-select').selectedOptions).map(opt => opt.value);
    const msg = document.getElementById('battle-form-msg');
    msg.textContent = '';

    if (!battleName) {
      msg.textContent = 'El nombre de la batalla es obligatorio.';
      return;
    }
    if (heroes.length !== 3 || villains.length !== 3) {
      msg.textContent = 'Debes seleccionar exactamente 3 héroes y 3 villanos.';
      return;
    }
    if (new Set(heroes).size !== 3 || new Set(villains).size !== 3) {
      msg.textContent = 'No se permiten personajes repetidos.';
      return;
    }

    try {
      const token = localStorage.getItem('token');
      if (!token) throw new Error('No authentication token found');
      const res = await fetch(`${window.API.baseURL}/api/battle`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          battleName,
          heroes,
          villains
        })
      });
      const result = await res.json();
      if (!res.ok) throw new Error(result.message || 'Error al crear la batalla');
      msg.textContent = '¡Batalla creada exitosamente!';
      msg.style.color = 'limegreen';
      document.getElementById('battle-form').reset();
    } catch (err) {
      msg.textContent = err.message;
      msg.style.color = 'red';
    }
  });
});

async function loadCharacters() {
  const token = localStorage.getItem('token');
  if (!token) return;
  try {
    const [heroesRes, villainsRes] = await Promise.all([
      fetch(`${window.API.baseURL}/api/hero`, { headers: { 'Authorization': `Bearer ${token}` } }),
      fetch(`${window.API.baseURL}/api/villain`, { headers: { 'Authorization': `Bearer ${token}` } })
    ]);
    const heroesData = await heroesRes.json();
    const villainsData = await villainsRes.json();
    const heroes = Array.isArray(heroesData.data) ? heroesData.data : [];
    const villains = Array.isArray(villainsData.data) ? villainsData.data : [];
    const heroesSelect = document.getElementById('heroes-select');
    const villainsSelect = document.getElementById('villains-select');
    heroesSelect.innerHTML = heroes.map(h => `<option value="${h.name}">${h.name}${h.alias ? ' (' + h.alias + ')' : ''}</option>`).join('');
    villainsSelect.innerHTML = villains.map(v => `<option value="${v.name}">${v.name}${v.alias ? ' (' + v.alias + ')' : ''}</option>`).join('');
  } catch (err) {
    document.getElementById('battle-form-msg').textContent = 'Error cargando personajes.';
  }
}
