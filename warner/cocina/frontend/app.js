const API_URL = 'http://localhost:3000/api/recetas';
const grid = document.getElementById('recetas-grid');
const audio = document.getElementById('ambient-sound');
const audioToggle = document.getElementById('audio-toggle');
let isAudioPlaying = false;

// Configuración de Audio
audio.volume = 0.4; // Volumen suave

audioToggle.addEventListener('click', () => {
    if (isAudioPlaying) {
        audio.pause();
        audioToggle.textContent = '🔇';
        audioToggle.style.borderColor = '#666';
    } else {
        audio.play().catch(e => console.log("Interacción requerida para reproducir audio"));
        audioToggle.textContent = '🔊';
        audioToggle.style.borderColor = 'var(--color-accent)';
    }
    isAudioPlaying = !isAudioPlaying;
});

// Función principal para iniciar la app
async function initApp() {
    try {
        const recetas = await fetchRecetas();
        renderRecetas(recetas);
    } catch (error) {
        console.error('Error al cargar:', error);
        grid.innerHTML = `<p style="text-align:center; color:red;">Error al conectar con la cocina. Asegúrate que el backend esté corriendo.</p>`;
    }
}

// Obtener datos del backend
async function fetchRecetas() {
    const response = await fetch(API_URL);
    const data = await response.json();
    return data.data;
}

// Renderizar tarjetas con nueva estructura para Hover
function renderRecetas(recetas) {
    grid.innerHTML = '';

    recetas.forEach((receta, index) => {
        const card = document.createElement('article');
        card.className = 'card';
        card.style.animationDelay = `${index * 0.15}s`;

        const ingredientesHTML = receta.ingredientes
            .map(ing => `<span class="tag">${ing}</span>`)
            .join('');

        // Nueva estructura HTML para soportar el efecto de hover "reveal"
        card.innerHTML = `
            <img src="${receta.imagen}" alt="${receta.nombre}" class="card-image-bg">
            <div class="card-overlay"></div>
            
            <div class="card-content">
                <h3 class="card-title">${receta.nombre}</h3>
                
                <div class="card-details-hidden">
                    <div class="card-meta">
                        <span>⏱ ${receta.tiempo}</span>
                        <span>★ ${receta.dificultad}</span>
                    </div>
                    
                    <p class="card-desc">${receta.descripcion}</p>
                    
                    <div class="card-ingredients">
                        <span class="ing-title">Ingredientes Esenciales</span>
                        <div class="tags-container">
                            ${ingredientesHTML}
                        </div>
                    </div>
                </div>
            </div>
        `;

        grid.appendChild(card);

        setTimeout(() => {
            card.classList.add('visible');
        }, 100 + (index * 150));
    });
}

document.addEventListener('DOMContentLoaded', initApp);
