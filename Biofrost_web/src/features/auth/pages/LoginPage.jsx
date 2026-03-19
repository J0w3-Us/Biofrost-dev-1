import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import {
    signInWithEmailAndPassword,
    signInWithPopup
} from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { auth, googleProvider, db } from '../../../lib/firebase';
import { useAuth } from '../hooks/useAuth';

// Helper para auto-configurar admin
const checkAdminSetup = async (user) => {
    if (user.email === 'uzielisaac28@gmail.com') {
        try {
            const userDocRef = doc(db, 'users', user.uid);
            const userDocSnap = await getDoc(userDocRef);
            const existingData = userDocSnap.exists() ? userDocSnap.data() : {};

            await setDoc(userDocRef, {
                email: user.email,
                nombre: existingData.nombre || 'Admin',
                rol: 'admin',
                is_first_login: false,
                created_at: existingData.created_at || new Date().toISOString()
            }, { merge: true });
            console.log('🚀 Admin privileges granted automatically for:', user.email);
        } catch (e) {
            console.error('Error granting admin privileges:', e);
        }
    }
};
import { GraduationCap, User, UserCheck, AlertCircle, Eye, EyeOff, Sun, Moon } from 'lucide-react';
import { useTheme } from '../../../context/ThemeContext';

// Regex para detectar rol
const REGEX_ALUMNO = /^(\d{8})@alumno\.utmetropolitana\.edu\.mx$/;
const REGEX_DOCENTE = /^[a-zA-Z.]+@utmetropolitana\.edu\.mx$/;

// Detectar rol por correo
const detectarRol = (email) => {
    if (REGEX_ALUMNO.test(email)) return 'Alumno';
    if (REGEX_DOCENTE.test(email)) return 'Docente';
    return 'Invitado';
};

export function LoginPage() {
    const { isAuthenticated, loading, rol } = useAuth();
    const { isDark, toggleTheme } = useTheme();
    const styles = getStyles(isDark);
    const navigate = useNavigate();

    const [showPassword, setShowPassword] = useState(false);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const [detectedRole, setDetectedRole] = useState(null);
    const [error, setError] = useState('');
    const [submitting, setSubmitting] = useState(false);

    if (loading) return <div style={styles.loadingContainer}><div style={styles.spinner}></div></div>;

    // Redirect based on role
    // Only redirect if authenticated
    if (isAuthenticated) {
        if (rol === 'admin' || rol === 'SuperAdmin') {
            return <Navigate to="/admin" replace />;
        }
        if (rol === 'Alumno') {
            return <Navigate to="/projects" replace />;
        }
        return <Navigate to="/dashboard" replace />;
    }

    // Detectar rol y validar email
    const handleEmailChange = (e) => {
        const value = e.target.value;
        setEmail(value);
        setError('');

        if (value.includes('@')) {
            const rol = detectarRol(value);
            setDetectedRole(rol);
        } else {
            setDetectedRole(null);
        }
    };

    // Login con email/password
    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setSubmitting(true);

        try {
            const result = await signInWithEmailAndPassword(auth, email, password);
            await checkAdminSetup(result.user);
        } catch (err) {
            console.error('Login error:', err);
            if (err.code === 'auth/invalid-credential' || err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password') {
                setError('Correo o contraseña incorrectos. Si eres nuevo, utiliza la pestaña de Registrarse arriba.');
            } else if (err.code === 'auth/too-many-requests') {
                setError('Demasiados intentos fallidos. Espera unos minutos antes de intentar de nuevo.');
            } else {
                setError(err.message);
            }
        } finally {
            setSubmitting(false);
        }
    };



    // Login con Google
    const handleGoogleLogin = async () => {
        setError('');
        setSubmitting(true);

        try {
            const result = await signInWithPopup(auth, googleProvider);
            await checkAdminSetup(result.user);
            const userEmail = result.user.email;
            const rol = detectarRol(userEmail);

            if (rol === 'Invitado') {
                setError('Has ingresado como Invitado. Solo puedes ver la galería pública.');
            }
        } catch (err) {
            console.error('Google login error:', err);
            if (err.code !== 'auth/popup-closed-by-user') {
                setError('Error al iniciar sesión con Google');
            }
        } finally {
            setSubmitting(false);
        }
    };



    // Icono de rol
    const RoleIcon = ({ role, size = 20 }) => {
        if (role === 'Alumno') return <GraduationCap size={size} />;
        if (role === 'Docente') return <UserCheck size={size} />;
        return <User size={size} />;
    };

    return (
        <div style={styles.pageContainer}>

            {/* Theme Toggle Button */}
            <button
                onClick={toggleTheme}
                style={styles.themeToggleBtn}
                aria-label="Toggle theme"
            >
                {isDark ? <Sun size={20} color="#facc15" /> : <Moon size={20} color="#6b7280" />}
            </button>

            <div style={styles.cardContainer}>
                {/* Logo */}
                <div style={styles.logoSection}>
                    <div style={styles.logoIcon}>
                        <img src="/byfrost-icon.png" alt="Byfrost" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '16px' }} />
                    </div>
                    <h1 style={styles.title}>Byfrost®</h1>
                    <p style={styles.subtitle}>DSM Edition</p>
                </div>

                {/* Card */}
                <div style={styles.card}>
                    {/* Auth Tabs */}
                    <div style={styles.tabBar}>
                        <button style={styles.tabActive} disabled>
                            Iniciar Sesión
                        </button>
                        <button style={styles.tabInactive} onClick={() => navigate('/register')}>
                            Registrarse
                        </button>
                    </div>

                    <form onSubmit={handleLogin} style={styles.form}>
                        {/* Email */}
                        <div style={styles.inputGroup}>
                            <label style={styles.label}>Correo Electrónico</label>
                            <input
                                type="email"
                                value={email}
                                onChange={handleEmailChange}
                                placeholder="tu.correo@utmetropolitana.edu.mx"
                                style={styles.input}
                                required
                            />
                            {detectedRole && detectedRole !== 'Invitado' && (
                                <div style={{
                                    ...styles.rolBadge,
                                    backgroundColor: detectedRole === 'Alumno' ? '#dbeafe' : '#dcfce7',
                                    color: detectedRole === 'Alumno' ? '#1d4ed8' : '#15803d'
                                }}>
                                    <RoleIcon role={detectedRole} size={16} />
                                    <span style={{ marginLeft: '8px' }}>Rol detectado: {detectedRole}</span>
                                </div>
                            )}
                        </div>

                        {/* Password */}
                        <div style={styles.inputGroup}>
                            <label style={styles.label}>Contraseña</label>
                            <div style={styles.passwordWrapper}>
                                <input
                                    type={showPassword ? 'text' : 'password'}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    placeholder="••••••••"
                                    style={{ ...styles.input, paddingRight: '48px' }}
                                    required
                                    minLength={6}
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    style={styles.passwordToggle}
                                    tabIndex={-1}
                                    aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
                                >
                                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                </button>
                            </div>
                        </div>

                        {/* Error */}
                        {error && (
                            <div style={styles.error}>
                                <AlertCircle size={16} style={{ flexShrink: 0 }} />
                                <span style={{ marginLeft: '8px' }}>{error}</span>
                            </div>
                        )}

                        {/* Submit Login */}
                        <button
                            type="submit"
                            disabled={submitting}
                            style={{
                                ...styles.primaryBtn,
                                opacity: submitting ? 0.7 : 1,
                            }}
                        >
                            {submitting ? 'Procesando...' : 'Iniciar Sesión'}
                        </button>
                    </form>

                    {/* Divider */}
                    <div style={styles.divider}>
                        <div style={styles.dividerLine}></div>
                        <span style={styles.dividerText}>o</span>
                        <div style={styles.dividerLine}></div>
                    </div>

                    {/* Google */}
                    <button
                        type="button"
                        onClick={handleGoogleLogin}
                        disabled={submitting}
                        style={styles.googleBtn}
                    >
                        <svg viewBox="0 0 24 24" width="20" height="20" style={{ marginRight: '10px' }}>
                            <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                            <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                            <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                            <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                        </svg>
                        Continuar con Google
                    </button>
                </div>
            </div>

            {/* Footer */}
            <p style={styles.footer}>Universidad Tecnológica Metropolitana</p>
        </div>
    );
}

// Estilos inline para garantizar renderizado correcto
const getStyles = (isDark) => ({
    pageContainer: {
        minHeight: '100vh',
        width: '100vw',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'transparent',
        padding: '20px',
        fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        position: 'relative',
        zIndex: 1,
        boxSizing: 'border-box',
        color: isDark ? '#f9fafb' : '#111827'
    },
    themeToggleBtn: {
        position: 'absolute',
        top: '20px',
        right: '20px',
        zIndex: 20,
        background: isDark ? 'rgba(31, 41, 55, 0.4)' : 'rgba(255, 255, 255, 0.4)',
        backdropFilter: 'blur(8px)',
        border: isDark ? '1px solid rgba(75, 85, 99, 0.5)' : '1px solid rgba(255, 255, 255, 0.5)',
        borderRadius: '50%',
        width: '44px',
        height: '44px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        transition: 'all 0.3s ease',
        boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
    },
    cardContainer: {
        width: '100%',
        maxWidth: '420px',
        position: 'relative',
        zIndex: 10,
        margin: '0 auto'
    },
    logoSection: {
        textAlign: 'center',
        marginBottom: '24px'
    },
    logoIcon: {
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: '68px',
        height: '68px',
        backgroundColor: '#ffffff',
        borderRadius: '18px',
        marginBottom: '16px',
        boxShadow: '0 4px 16px rgba(0, 0, 0, 0.12)',
        padding: '4px',
        overflow: 'hidden'
    },
    logoText: {
        fontSize: '24px',
        fontWeight: '800',
        color: '#fff'
    },
    title: {
        fontSize: '28px',
        fontWeight: '700',
        color: '#ffffff',
        margin: '0',
        letterSpacing: '-0.5px',
        textShadow: '0 2px 12px rgba(0,0,0,0.5)'
    },
    subtitle: {
        fontSize: '14px',
        color: 'rgba(255,255,255,0.75)',
        margin: '6px 0 0 0',
        textShadow: '0 1px 8px rgba(0,0,0,0.4)'
    },
    card: {
        backgroundColor: isDark ? '#1f2937' : '#fff',
        borderRadius: '20px',
        boxShadow: isDark ? '0 4px 24px rgba(0, 0, 0, 0.4)' : '0 4px 24px rgba(0, 0, 0, 0.06)',
        border: isDark ? '1px solid #374151' : '1px solid #e5e7eb',
        padding: '32px',
        transition: 'background-color 0.3s, border-color 0.3s, box-shadow 0.3s'
    },
    cardTitle: {
        fontSize: '20px',
        fontWeight: '600',
        color: isDark ? '#f9fafb' : '#111827',
        margin: '0 0 4px 0',
        textAlign: 'center'
    },
    cardSubtitle: {
        fontSize: '14px',
        color: isDark ? '#9ca3af' : '#6b7280',
        margin: '0 0 24px 0',
        textAlign: 'center'
    },
    tabBar: {
        display: 'flex',
        borderBottom: isDark ? '1px solid #374151' : '1px solid #e5e7eb',
        marginBottom: '24px',
        gap: '0px',
    },
    tabActive: {
        flex: 1,
        background: 'none',
        border: 'none',
        borderBottom: isDark ? '2.5px solid #f9fafb' : '2.5px solid #111827',
        padding: '12px 8px',
        fontSize: '15px',
        fontWeight: '600',
        color: isDark ? '#f9fafb' : '#111827',
        cursor: 'default',
        transition: 'all 0.2s',
        marginBottom: '-1px',
    },
    tabInactive: {
        flex: 1,
        background: 'none',
        border: 'none',
        borderBottom: '2.5px solid transparent',
        padding: '12px 8px',
        fontSize: '15px',
        fontWeight: '500',
        color: isDark ? '#6b7280' : '#9ca3af',
        cursor: 'pointer',
        transition: 'all 0.2s',
        marginBottom: '-1px',
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '16px'
    },
    inputGroup: {
        display: 'flex',
        flexDirection: 'column',
        gap: '6px'
    },
    label: {
        fontSize: '14px',
        fontWeight: '500',
        color: isDark ? '#d1d5db' : '#374151'
    },
    input: {
        width: '100%',
        padding: '14px 16px',
        fontSize: '15px',
        border: isDark ? '1.5px solid #4b5563' : '1.5px solid #e5e7eb',
        borderRadius: '12px',
        outline: 'none',
        transition: 'border-color 0.2s, box-shadow 0.2s, background-color 0.3s, color 0.3s',
        boxSizing: 'border-box',
        backgroundColor: isDark ? '#374151' : '#fafafa',
        color: isDark ? '#f9fafb' : '#111827'
    },
    inputCompact: {
        width: '100%',
        padding: '10px 14px',
        fontSize: '14px',
        border: isDark ? '1.5px solid #4b5563' : '1.5px solid #e5e7eb',
        borderRadius: '10px',
        outline: 'none',
        transition: 'border-color 0.2s, box-shadow 0.2s, background-color 0.3s, color 0.3s',
        boxSizing: 'border-box',
        backgroundColor: isDark ? '#374151' : '#fafafa',
        color: isDark ? '#f9fafb' : '#111827'
    },
    passwordWrapper: {
        position: 'relative',
        width: '100%'
    },
    passwordToggle: {
        position: 'absolute',
        right: '12px',
        top: '50%',
        transform: 'translateY(-50%)',
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        color: '#9ca3af',
        padding: '4px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '6px',
        transition: 'color 0.2s'
    },
    select: {
        width: '100%',
        padding: '14px 16px',
        fontSize: '15px',
        border: isDark ? '1.5px solid #4b5563' : '1.5px solid #e5e7eb',
        borderRadius: '12px',
        outline: 'none',
        boxSizing: 'border-box',
        backgroundColor: isDark ? '#374151' : '#fafafa',
        color: isDark ? '#f9fafb' : '#111827',
        cursor: 'pointer',
        transition: 'border-color 0.2s, background-color 0.3s, color 0.3s'
    },
    selectCompact: {
        width: '100%',
        padding: '10px 14px',
        fontSize: '14px',
        border: isDark ? '1.5px solid #4b5563' : '1.5px solid #e5e7eb',
        borderRadius: '10px',
        outline: 'none',
        boxSizing: 'border-box',
        backgroundColor: isDark ? '#374151' : '#fafafa',
        color: isDark ? '#f9fafb' : '#111827',
        cursor: 'pointer',
        transition: 'border-color 0.2s, background-color 0.3s, color 0.3s'
    },
    rolBadge: {
        display: 'flex',
        alignItems: 'center',
        marginTop: '8px',
        padding: '10px 14px',
        borderRadius: '10px',
        fontSize: '14px',
        fontWeight: '500'
    },
    rolBadgeLarge: {
        padding: '16px',
        borderRadius: '12px',
        border: '1px solid',
        marginBottom: '20px'
    },
    rolBadgeHeader: {
        display: 'flex',
        alignItems: 'center'
    },
    rolBadgeEmail: {
        fontSize: '13px',
        color: isDark ? '#d1d5db' : '#374151',
        margin: '8px 0 0 0'
    },
    rolBadgeMatricula: {
        fontSize: '12px',
        color: isDark ? '#9ca3af' : '#4b5563',
        margin: '4px 0 0 0',
        fontWeight: '500'
    },
    divider: {
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        margin: '4px 0'
    },
    dividerLine: {
        flex: 1,
        height: '1px',
        backgroundColor: isDark ? '#374151' : '#e5e7eb'
    },
    dividerText: {
        fontSize: '13px',
        color: '#9ca3af',
        fontWeight: '500',
        textTransform: 'lowercase'
    },
    error: {
        display: 'flex',
        alignItems: 'center',
        padding: '12px 16px',
        backgroundColor: isDark ? 'rgba(239, 68, 68, 0.1)' : '#fef2f2',
        border: isDark ? '1px solid rgba(239, 68, 68, 0.3)' : '1px solid #fecaca',
        borderRadius: '10px',
        color: isDark ? '#fca5a5' : '#dc2626',
        fontSize: '14px'
    },
    primaryBtn: {
        width: '100%',
        padding: '14px',
        backgroundColor: isDark ? '#3b82f6' : '#111827',
        color: '#fff',
        fontSize: '15px',
        fontWeight: '600',
        border: 'none',
        borderRadius: '12px',
        cursor: 'pointer',
        transition: 'transform 0.1s, box-shadow 0.2s, background-color 0.3s',
        boxShadow: isDark ? '0 2px 8px rgba(59, 130, 246, 0.25)' : '0 2px 8px rgba(17, 24, 39, 0.15)'
    },
    googleBtn: {
        width: '100%',
        padding: '14px',
        backgroundColor: isDark ? '#374151' : '#fff',
        color: isDark ? '#f9fafb' : '#374151',
        fontSize: '15px',
        fontWeight: '500',
        border: isDark ? '1.5px solid #4b5563' : '1.5px solid #e5e7eb',
        borderRadius: '12px',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'background-color 0.2s, border-color 0.3s, color 0.3s'
    },
    backBtn: {
        display: 'flex',
        alignItems: 'center',
        padding: '8px 0',
        marginBottom: '16px',
        color: isDark ? '#d1d5db' : '#6b7280',
        fontSize: '14px',
        background: 'none',
        border: 'none',
        cursor: 'pointer'
    },
    footer: {
        textAlign: 'center',
        fontSize: '12px',
        color: isDark ? '#6b7280' : '#9ca3af',
        marginTop: '24px'
    },
    loadingContainer: {
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f9fafb',
        gap: '16px'
    },
    spinner: {
        width: '40px',
        height: '40px',
        border: '3px solid #e5e7eb',
        borderTopColor: '#111827',
        borderRadius: '50%',
        animation: 'spin 0.8s linear infinite'
    },
    loadingText: {
        fontSize: '14px',
        color: '#6b7280'
    },
    helperText: {
        fontSize: '13px',
        color: isDark ? '#9ca3af' : '#9ca3af',
        margin: '0 0 8px 0'
    },
    gruposGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '8px'
    },
    grupoChip: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '10px',
        border: '1.5px solid',
        borderRadius: '8px',
        fontSize: '14px',
        fontWeight: '500',
        cursor: 'pointer',
        transition: 'all 0.15s'
    }
});
