import { Outlet, useLocation } from 'react-router-dom';
import { CityBackground } from '../../../components/ui/CityBackground';
import { useTheme } from '../../../context/ThemeContext';

export function AuthLayout() {
    const { isDark } = useTheme();
    const location = useLocation();
    
    // Determinamos si estamos en la ruta de registro para animar la cámara
    const isRegister = location.pathname === '/register';

    return (
        <div style={{ position: 'relative', width: '100vw', height: '100vh', overflow: 'hidden' }}>
            {/* El fondo 3D se renderiza una vez a nivel de Layout */}
            <CityBackground isDark={isDark} isRegister={isRegister} />
            
            {/* El contenido de Login o Register se superpone */}
            <div style={{ position: 'absolute', inset: 0, zIndex: 10, overflowY: 'auto' }}>
                <Outlet />
            </div>
        </div>
    );
}
