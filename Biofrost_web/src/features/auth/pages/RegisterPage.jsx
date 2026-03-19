import { useState, useEffect } from 'react';
import { Navigate, useNavigate, Link } from 'react-router-dom';
import {
    createUserWithEmailAndPassword,
} from 'firebase/auth';
import { auth } from '../../../lib/firebase';
import { useAuth } from '../hooks/useAuth';

import api from '../../../lib/axios';
import { GraduationCap, User, UserCheck, AlertCircle, Check, Eye, EyeOff, Sun, Moon, ArrowRight, ArrowLeft } from 'lucide-react';
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

// Extraer matrícula del correo de alumno
const extraerMatricula = (email) => {
    const match = email.match(REGEX_ALUMNO);
    return match ? match[1] : null;
};

export function RegisterPage() {
    const { isAuthenticated, loading, rol, refreshUserData } = useAuth();
    const { isDark, toggleTheme } = useTheme();
    const styles = getStyles(isDark);
    const navigate = useNavigate();

    const [step, setStep] = useState(1); // 1: credentials, 2: profile details
    const [showPassword, setShowPassword] = useState(false);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const [nombre, setNombre] = useState('');
    const [apellidoPaterno, setApellidoPaterno] = useState('');
    const [apellidoMaterno, setApellidoMaterno] = useState('');
    // Alumno
    const [grupo, setGrupo] = useState('');
    const [carrera, setCarrera] = useState('');
    // Docente
    const [carreraDocente, setCarreraDocente] = useState('');
    const [materiaDocente, setMateriaDocente] = useState('');
    const [gruposDocente, setGruposDocente] = useState([]);
    const [profesion, setProfesion] = useState('');

    // Opciones en cascadas Docente
    const [materiasDisponiblesDocente, setMateriasDisponiblesDocente] = useState([]);
    const [gruposDisponiblesDocente, setGruposDisponiblesDocente] = useState([]);
    const [loadingMaterias, setLoadingMaterias] = useState(false);
    // Invitado
    const [organizacion, setOrganizacion] = useState('');

    const [detectedRole, setDetectedRole] = useState(null);
    const [error, setError] = useState('');
    const [submitting, setSubmitting] = useState(false);

    // Catálogos dinámicos
    const [gruposDisponibles, setGruposDisponibles] = useState([]);
    const [carrerasDisponibles, setCarrerasDisponibles] = useState([]);

    // Cargar catálogos
    useEffect(() => {
        const fetchData = async () => {
            try {
                const [groupsRes, carrerasRes] = await Promise.all([
                    api.get('/api/admin/groups'),
                    api.get('/api/admin/carreras')
                ]);

                setGruposDisponibles(groupsRes.data || []);
                setCarrerasDisponibles(carrerasRes.data || []);

            } catch (err) {
                console.error('Error loading catalogs:', err);
                // Fallbacks mejorados para desarrollo
                setGruposDisponibles([
                    { id: '5A', nombre: '5A' },
                    { id: '5B', nombre: '5B' },
                    { id: '5C', nombre: '5C' },
                    { id: '6A', nombre: '6A' },
                    { id: '6B', nombre: '6B' },
                    { id: '6C', nombre: '6C' }
                ]);
                setCarrerasDisponibles([
                    { id: 'dsm', nombre: 'Desarrollo de Software Multiplataforma' },
                    { id: 'evn', nombre: 'Entornos Virtuales y Negocios Digitales' },
                    { id: 'ric', nombre: 'Redes Inteligentes y Ciberseguridad' }
                ]);
            }
        };
        fetchData();
    }, []);

    // Cargar Materias Disponibles cuando el Docente selecciona una Carrera
    useEffect(() => {
        if (detectedRole === 'Docente' && carreraDocente) {
            setLoadingMaterias(true);
            api.get(`/api/admin/materias/available?carreraId=${carreraDocente}`)
                .then(res => {
                    setMateriasDisponiblesDocente(res.data || []);
                    setMateriaDocente('');
                    setGruposDocente([]);
                    setGruposDisponiblesDocente([]);
                })
                .catch(err => console.error("Error fetching materias", err))
                .finally(() => setLoadingMaterias(false));
        }
    }, [carreraDocente, detectedRole]);

    // Filtrar Grupos Libres cuando el Docente selecciona una Materia
    useEffect(() => {
        if (materiaDocente) {
            const mat = materiasDisponiblesDocente.find(m => m.materia.id === materiaDocente);
            if (mat) {
                setGruposDisponiblesDocente(mat.gruposDisponibles || []);
            } else {
                setGruposDisponiblesDocente([]);
            }
            setGruposDocente([]); // Reset grupos seleccionados si cambia la materia
        }
    }, [materiaDocente, materiasDisponiblesDocente]);

    if (loading) return <div style={styles.loadingContainer}><div style={styles.spinner}></div></div>;

    // Redirect based on role only if auth is complete and fully registered
    if (isAuthenticated && step !== 2) {
        if (rol === 'admin' || rol === 'SuperAdmin') return <Navigate to="/admin" replace />;
        if (rol === 'Alumno') return <Navigate to="/projects" replace />;
        return <Navigate to="/dashboard" replace />;
    }

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

    const handleContinueToProfile = (e) => {
        e.preventDefault();
        setError('');

        if (!email || !email.includes('@')) {
            setError('Ingresa un correo válido');
            return;
        }

        if (!password || password.length < 6) {
            setError('La contraseña debe tener al menos 6 caracteres');
            return;
        }

        setStep(2);
    };

    const handleRegistroFinal = async (e) => {
        e.preventDefault();
        setError('');
        setSubmitting(true);

        // Validaciones generales
        if (!nombre.trim()) { setError('Nombre requerido'); setSubmitting(false); return; }

        // Validaciones por rol
        if (detectedRole === 'Alumno') {
            if (!grupo) { setError('Selecciona tu grupo'); setSubmitting(false); return; }
            if (!carrera) { setError('Selecciona tu carrera'); setSubmitting(false); return; }
        }

        if (detectedRole === 'Docente') {
            if (!profesion) { setError('Indica tu profesión'); setSubmitting(false); return; }
            if (!carreraDocente) { setError('Selecciona una carrera impartida'); setSubmitting(false); return; }
            if (!materiaDocente) { setError('Selecciona la materia que impartes'); setSubmitting(false); return; }
            if (gruposDocente.length === 0) { setError('Selecciona al menos un grupo'); setSubmitting(false); return; }
        }

        if (detectedRole === 'Invitado') {
            if (!organizacion) { setError('Indica tu organización o empresa'); setSubmitting(false); return; }
        }

        try {
            // 1. Firebase Auth - Crear Usuario
            const userCredential = await createUserWithEmailAndPassword(auth, email, password);

            // Transformar nombres a formato Título
            const toTitleCase = (str) => {
                if (!str) return '';
                return str.toLowerCase().split(' ').map(word => {
                    return word.charAt(0).toUpperCase() + word.slice(1);
                }).join(' ');
            };

            const nombreFinal = toTitleCase(nombre.trim());
            const apellidoPaternoFinal = toTitleCase(apellidoPaterno.trim());
            const apellidoMaternoFinal = toTitleCase(apellidoMaterno.trim());

            // 2. Backend Register
            const payload = {
                firebaseUid: userCredential.user.uid,
                email: email,
                nombre: nombreFinal,
                apellidoPaterno: apellidoPaternoFinal,
                apellidoMaterno: apellidoMaternoFinal,
                rol: detectedRole,
                matricula: detectedRole === 'Alumno' ? extraerMatricula(email) : null,
                grupoId: grupo || null,
                carreraId: carrera || null,
                profesion: profesion || null,
                asignaciones: detectedRole === 'Docente' ? [{
                    carreraId: carreraDocente,
                    materiaId: materiaDocente,
                    gruposIds: gruposDocente
                }] : null,
                organizacion: organizacion || null
            };

            await api.post('/api/auth/register', payload);

            // 3. RECUPERAR DATOS FINALES
            const finalUser = await refreshUserData();

            // Navegación explícita al completar la creación
            if (finalUser?.rol === 'admin' || finalUser?.rol === 'SuperAdmin') {
                navigate('/admin', { replace: true });
            } else if (finalUser?.rol === 'Alumno') {
                navigate('/projects', { replace: true });
            } else {
                navigate('/dashboard', { replace: true });
            }

        } catch (err) {
            console.error('Registro error:', err);
            if (err.code === 'auth/email-already-in-use') {
                setStep(1);
                setError('Este correo ya está registrado en el sistema. Intenta iniciar sesión.');
            } else {
                setError(err.message || 'Error al registrar usuario');
            }
        } finally {
            setSubmitting(false);
        }
    };

    const toggleGrupoDocente = (g) => {
        setGruposDocente(prev =>
            prev.includes(g) ? prev.filter(x => x !== g) : [...prev, g]
        );
    };

    const RoleIcon = ({ role, size = 20 }) => {
        if (role === 'Alumno') return <GraduationCap size={size} />;
        if (role === 'Docente') return <UserCheck size={size} />;
        return <User size={size} />;
    };

    return (
        <div style={styles.pageContainer}>

            <button
                onClick={toggleTheme}
                style={styles.themeToggleBtn}
                aria-label="Toggle theme"
            >
                {isDark ? <Sun size={20} color="#facc15" /> : <Moon size={20} color="#6b7280" />}
            </button>

            <div style={styles.cardContainer}>

                {/* Logo - same as LoginPage */}
                <div style={styles.logoSection}>
                    <div style={styles.logoIcon}>
                        <img src="/byfrost-icon.png" alt="Byfrost" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '16px' }} />
                    </div>
                    <h1 style={styles.title}>Byfrost®</h1>
                    <p style={styles.subtitle}>DSM Edition</p>
                </div>

                {step === 1 && (
                    <div style={{ ...styles.card, padding: '32px' }}>
                        {/* Auth Tabs */}
                        <div style={styles.tabBar}>
                            <button style={styles.tabInactive} onClick={() => navigate('/login')}>
                                Iniciar Sesión
                            </button>
                            <button style={styles.tabActive} disabled>
                                Registrarse
                            </button>
                        </div>


                        <form onSubmit={handleContinueToProfile} style={styles.form}>
                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Correo Institucional / Profesional</label>
                                <input
                                    type="email"
                                    value={email}
                                    onChange={handleEmailChange}
                                    placeholder="tu.correo@utmetropolitana.edu.mx"
                                    style={styles.input}
                                    required
                                />
                                {detectedRole && (
                                    <div style={{
                                        ...styles.rolBadge,
                                        backgroundColor: detectedRole === 'Alumno' ? '#dbeafe' : (detectedRole === 'Docente' ? '#dcfce7' : '#f3f4f6'),
                                        color: detectedRole === 'Alumno' ? '#1d4ed8' : (detectedRole === 'Docente' ? '#15803d' : '#4b5563')
                                    }}>
                                        <RoleIcon role={detectedRole} size={16} />
                                        <span style={{ marginLeft: '8px' }}>Rol detectado: {detectedRole}</span>
                                    </div>
                                )}
                            </div>

                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Crea una Contraseña</label>
                                <div style={styles.passwordWrapper}>
                                    <input
                                        type={showPassword ? 'text' : 'password'}
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        placeholder="Min. 6 caracteres"
                                        style={{ ...styles.input, paddingRight: '48px' }}
                                        required
                                        minLength={6}
                                    />
                                    <button
                                        type="button"
                                        onClick={() => setShowPassword(!showPassword)}
                                        style={styles.passwordToggle}
                                        tabIndex={-1}
                                    >
                                        {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                    </button>
                                </div>
                            </div>

                            {error && (
                                <div style={styles.error}>
                                    <AlertCircle size={16} style={{ flexShrink: 0 }} />
                                    <span style={{ marginLeft: '8px' }}>{error}</span>
                                </div>
                            )}

                            <button type="submit" style={styles.primaryBtn} disabled={!email || !password || password.length < 6}>
                                Continuar
                                <ArrowRight size={18} style={{ marginLeft: '8px' }} />
                            </button>

                            <p style={styles.loginHint}>
                                ¿Ya tienes cuenta? <Link to="/login" style={styles.loginLink}>Inicia Sesión aquí</Link>
                            </p>
                        </form>
                    </div>
                )}

                {step === 2 && (
                    <div style={{ ...styles.card, padding: '24px' }}>
                        <button
                            type="button"
                            onClick={() => setStep(1)}
                            style={styles.backBtn}
                        >
                            <ArrowLeft size={18} />
                            <span style={{ marginLeft: '6px' }}>Volver a datos de acceso</span>
                        </button>

                        <h2 style={styles.cardTitle}>Completa tu Perfil</h2>
                        <p style={styles.cardSubtitle}>
                            {detectedRole === 'Alumno'
                                ? 'Verifica y completa tus datos para finalizar'
                                : 'Completa tus datos para configurar tu cuenta'}
                        </p>

                        <div style={{
                            ...styles.rolBadgeLarge,
                            backgroundColor: detectedRole === 'Alumno' ? '#eff6ff' : (detectedRole === 'Docente' ? '#f0fdf4' : '#f9fafb'),
                            borderColor: detectedRole === 'Alumno' ? '#bfdbfe' : (detectedRole === 'Docente' ? '#bbf7d0' : '#e5e7eb')
                        }}>
                            <div style={styles.rolBadgeHeader}>
                                <RoleIcon role={detectedRole} size={24} />
                                <span style={{
                                    marginLeft: '10px',
                                    fontWeight: '600',
                                    color: detectedRole === 'Alumno' ? '#1d4ed8' : (detectedRole === 'Docente' ? '#15803d' : '#374151')
                                }}>
                                    {detectedRole}
                                </span>
                            </div>
                            <p style={styles.rolBadgeEmail}>{email}</p>
                            {detectedRole === 'Alumno' && (
                                <p style={styles.rolBadgeMatricula}>Matrícula: {extraerMatricula(email)}</p>
                            )}
                        </div>

                        <form onSubmit={handleRegistroFinal} style={{ ...styles.form, gap: '12px' }}>
                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Nombre(s) <span style={{ color: '#ef4444' }}>*</span></label>
                                <input
                                    type="text"
                                    value={nombre}
                                    onChange={(e) => setNombre(e.target.value)}
                                    placeholder="Juan Carlos"
                                    style={styles.inputCompact}
                                    required
                                />
                            </div>

                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Apellido Paterno <span style={{ color: '#ef4444' }}>*</span></label>
                                <input
                                    type="text"
                                    value={apellidoPaterno}
                                    onChange={(e) => setApellidoPaterno(e.target.value)}
                                    placeholder="Pérez"
                                    style={styles.inputCompact}
                                    required
                                />
                            </div>

                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Apellido Materno <span style={{ color: '#ef4444' }}>*</span></label>
                                <input
                                    type="text"
                                    value={apellidoMaterno}
                                    onChange={(e) => setApellidoMaterno(e.target.value)}
                                    placeholder="García"
                                    style={styles.inputCompact}
                                    required
                                />
                            </div>

                            {detectedRole === 'Alumno' && (
                                <>
                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Tu Carrera</label>
                                        <select
                                            value={carrera}
                                            onChange={(e) => setCarrera(e.target.value)}
                                            style={styles.selectCompact}
                                            required
                                        >
                                            <option value="">Selecciona tu carrera...</option>
                                            {carrerasDisponibles.map(c => (
                                                <option key={c.id} value={c.id}>{c.nombre}</option>
                                            ))}
                                        </select>
                                    </div>

                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Tu Grupo</label>
                                        <select
                                            value={grupo}
                                            onChange={(e) => setGrupo(e.target.value)}
                                            style={styles.selectCompact}
                                            required
                                        >
                                            <option value="">Selecciona tu grupo...</option>
                                            {gruposDisponibles.map(g => (
                                                <option key={g.id} value={g.id}>{g.nombre}</option>
                                            ))}
                                        </select>
                                    </div>
                                </>
                            )}

                            {detectedRole === 'Docente' && (
                                <>
                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Profesión / Título</label>
                                        <input
                                            type="text"
                                            value={profesion}
                                            onChange={(e) => setProfesion(e.target.value)}
                                            placeholder="Ej. Ing. en Sistemas"
                                            style={styles.inputCompact}
                                            required
                                        />
                                    </div>

                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Carrera en la que impartes</label>
                                        <select
                                            value={carreraDocente}
                                            onChange={(e) => setCarreraDocente(e.target.value)}
                                            style={styles.selectCompact}
                                            required
                                        >
                                            <option value="">Selecciona tu carrera...</option>
                                            {carrerasDisponibles.map(c => (
                                                <option key={c.id} value={c.id}>{c.nombre}</option>
                                            ))}
                                        </select>
                                    </div>

                                    {carreraDocente && (
                                        <div style={styles.inputGroup}>
                                            <label style={styles.label}>Materia Asignada {loadingMaterias && "(Cargando...)"}</label>
                                            <select
                                                value={materiaDocente}
                                                onChange={(e) => setMateriaDocente(e.target.value)}
                                                style={styles.selectCompact}
                                                required
                                                disabled={loadingMaterias || materiasDisponiblesDocente.length === 0}
                                            >
                                                <option value="">Selecciona una materia...</option>
                                                {materiasDisponiblesDocente.map(item => (
                                                    <option key={item.materia.id} value={item.materia.id}>
                                                        {item.materia.nombre} ({item.materia.clave})
                                                    </option>
                                                ))}
                                            </select>
                                        </div>
                                    )}

                                    {materiaDocente && gruposDisponiblesDocente.length > 0 && (
                                        <div style={styles.inputGroup}>
                                            <label style={styles.label}>Grupos Disponibles</label>
                                            <div style={styles.gruposGrid}>
                                                {gruposDisponiblesDocente.map(g => (
                                                    <button
                                                        key={g.id}
                                                        type="button"
                                                        onClick={() => toggleGrupoDocente(g.id)}
                                                        style={{
                                                            ...styles.grupoChip,
                                                            backgroundColor: gruposDocente.includes(g.id) ? '#111827' : '#f3f4f6',
                                                            color: gruposDocente.includes(g.id) ? '#fff' : '#374151',
                                                            borderColor: gruposDocente.includes(g.id) ? '#111827' : '#d1d5db'
                                                        }}
                                                    >
                                                        {g.nombre}
                                                        {gruposDocente.includes(g.id) && <Check size={14} style={{ marginLeft: '4px' }} />}
                                                    </button>
                                                ))}
                                            </div>
                                        </div>
                                    )}
                                </>
                            )}

                            {detectedRole === 'Invitado' && (
                                <div style={styles.inputGroup}>
                                    <label style={styles.label}>Organización / Empresa</label>
                                    <input
                                        type="text"
                                        value={organizacion}
                                        onChange={(e) => setOrganizacion(e.target.value)}
                                        placeholder="Ej. Independiente"
                                        style={styles.input}
                                        required
                                    />
                                </div>
                            )}

                            {error && (
                                <div style={styles.error}>
                                    <AlertCircle size={16} style={{ flexShrink: 0 }} />
                                    <span style={{ marginLeft: '8px' }}>{error}</span>
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={submitting}
                                style={{
                                    ...styles.primaryBtn,
                                    opacity: submitting ? 0.7 : 1
                                }}
                            >
                                {submitting ? 'Creando cuenta...' : 'Finalizar Registro'}
                            </button>
                        </form>
                    </div>
                )}

                <p style={styles.footer}>Universidad Tecnológica Metropolitana</p>
            </div>
        </div>
    );
}

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
        color: '#ffffff',  // Siempre blanco — legible sobre el edificio oscuro
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
        cursor: 'pointer'
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
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'transform 0.1s, box-shadow 0.2s, background-color 0.3s',
        boxShadow: isDark ? '0 2px 8px rgba(59, 130, 246, 0.25)' : '0 2px 8px rgba(17, 24, 39, 0.15)'
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
    header: {
        display: 'flex',
        marginBottom: '16px'
    },
    backBtnText: {
        display: 'flex',
        alignItems: 'center',
        textDecoration: 'none',
        color: isDark ? '#9ca3af' : '#6b7280',
        fontSize: '14px',
        fontWeight: '500'
    },
    loginHint: {
        textAlign: 'center',
        fontSize: '14px',
        color: isDark ? '#9ca3af' : '#6b7280',
        marginTop: '8px',
        marginBottom: '0'
    },
    loginLink: {
        color: isDark ? '#60a5fa' : '#2563eb',
        textDecoration: 'none',
        fontWeight: '600'
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
        background: 'transparent'
    },
    spinner: {
        width: '40px',
        height: '40px',
        border: '3px solid #e5e7eb',
        borderTopColor: '#111827',
        borderRadius: '50%',
        animation: 'spin 0.8s linear infinite'
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
