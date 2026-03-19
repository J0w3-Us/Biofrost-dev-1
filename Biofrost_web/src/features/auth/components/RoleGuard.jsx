import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export function RoleGuard({ allowedRoles }) {
    const { userData, loading } = useAuth();

    if (loading) {
        return <div className="min-h-screen flex items-center justify-center bg-gray-50">
            <div className="w-8 h-8 border-2 border-gray-400 border-t-gray-900 rounded-full animate-spin"></div>
        </div>;
    }

    if (!userData || !allowedRoles.includes(userData.rol)) {
        // Redirect unauthorized users to dashboard or login
        return <Navigate to="/dashboard" replace />;
    }

    return <Outlet />;
}
