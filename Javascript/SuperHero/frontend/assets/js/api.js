// api.js - Llamadas a la API

window.API = {
    baseURL: '',
    
    async request(endpoint, options = {}) {
        const headers = options.headers || {};
        const token = window.Auth ? window.Auth.getToken() : localStorage.getItem('token');
        
        if (token) {
            headers['Authorization'] = 'Bearer ' + token;
        }
        
        if (options.body && typeof options.body === 'object') {
            headers['Content-Type'] = 'application/json';
            options.body = JSON.stringify(options.body);
        }
        
        const config = {
            ...options,
            headers
        };
        
        try {
            const response = await fetch(this.baseURL + endpoint, config);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return await response.json();
            }
            
            return await response.text();
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    },

    get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    },

    post(endpoint, data) {
        return this.request(endpoint, { 
            method: 'POST', 
            body: data 
        });
    },

    put(endpoint, data) {
        return this.request(endpoint, { 
            method: 'PUT', 
            body: data 
        });
    },

    delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }
};

// Para compatibilidad con código existente
async function apiFetch(endpoint, options = {}) {
    return window.API.request(endpoint, options);
}

const api = {
    get: (endpoint) => window.API.get(endpoint),
    post: (endpoint, data) => window.API.post(endpoint, data),
    put: (endpoint, data) => window.API.put(endpoint, data),
    delete: (endpoint) => window.API.delete(endpoint)
};
