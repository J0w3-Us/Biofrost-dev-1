// utils.js - Funciones auxiliares

window.Utils = {
    formatDate: function(dateStr) {
        if (!dateStr) return 'Fecha desconocida';
        const date = new Date(dateStr);
        return date.toLocaleDateString('es-MX', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    capitalize: function(str) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
    },

    showMessage: function(message, type = 'info') {
        console.log(`[${type.toUpperCase()}] ${message}`);
        
        // Crear notificación visual
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem 1.5rem;
            background: ${type === 'error' ? '#ff5722' : type === 'success' ? '#4caf50' : '#2196f3'};
            color: white;
            border-radius: 8px;
            z-index: 10000;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            font-family: 'Segoe UI', sans-serif;
            max-width: 300px;
            animation: slideIn 0.3s ease-out;
        `;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease-in';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    },

    showError: function(message) {
        this.showMessage(message, 'error');
    },

    showSuccess: function(message) {
        this.showMessage(message, 'success');
    },

    loadComponent: async function(componentPath, containerId) {
        try {
            const response = await fetch(componentPath);
            if (!response.ok) throw new Error(`No se pudo cargar ${componentPath}`);
            
            const html = await response.text();
            const container = document.getElementById(containerId);
            
            if (container) {
                container.innerHTML = html;
            }
        } catch (error) {
            console.error(`Error cargando componente ${componentPath}:`, error);
        }
    }
};

// Para compatibilidad con código existente
function formatDate(dateStr) {
    return window.Utils.formatDate(dateStr);
}

function capitalize(str) {
    return window.Utils.capitalize(str);
}

function showMessage(message, type = 'info') {
    return window.Utils.showMessage(message, type);
}

function showError(message) {
    return window.Utils.showError(message);
}

function showSuccess(message) {
    return window.Utils.showSuccess(message);
}

async function loadComponent(componentPath, containerId) {
    return window.Utils.loadComponent(componentPath, containerId);
}

// Agregar estilos CSS para las notificaciones
if (!document.querySelector('#notification-styles')) {
    const style = document.createElement('style');
    style.id = 'notification-styles';
    style.textContent = `
        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        @keyframes slideOut {
            from { transform: translateX(0); opacity: 1; }
            to { transform: translateX(100%); opacity: 0; }
        }
    `;
    document.head.appendChild(style);
}
