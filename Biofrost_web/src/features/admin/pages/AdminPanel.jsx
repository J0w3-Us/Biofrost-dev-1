import { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/hooks/useAuth';
import { auth } from '../../../lib/firebase';
import { signOut } from 'firebase/auth';
import api from '../../../lib/axios';
import { Plus, Edit2, Trash2, X, Check, LogOut } from 'lucide-react';

export function AdminPanel() {
    const { userData } = useAuth();
    const navigate = useNavigate();
    const [grupos, setGrupos] = useState([]);
    const [carreras, setCarreras] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingGrupo, setEditingGrupo] = useState(null);
    const [error, setError] = useState('');
    const [showLogoutMenu, setShowLogoutMenu] = useState(false);
    const menuRef = useRef(null);

    const [activeTab, setActiveTab] = useState('grupos');

    // Form state
    const [formData, setFormData] = useState({
        nombre: '',
        carrera: 'DSM',
        turno: 'Matutino',
        cicloActivo: '2024-2'
    });

    const loadData = useCallback(async () => {
        try {
            setLoading(true);
            const [gruposRes, carrerasRes] = await Promise.all([
                api.get('/api/admin/groups'),
                api.get('/api/admin/carreras')
            ]);
            setGrupos(gruposRes.data || []);
            setCarreras(carrerasRes.data || []);
        } catch (err) {
            console.error('Error loading data:', err);
            setError('Error al cargar datos');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        const isAdmin = userData?.rol === 'SuperAdmin' || userData?.rol?.toLowerCase() === 'admin';
        if (!isAdmin) {
            navigate('/dashboard');
            return;
        }
        loadData();

        // Close menu when clicking outside
        const handleClickOutside = (event) => {
            if (menuRef.current && !menuRef.current.contains(event.target)) {
                setShowLogoutMenu(false);
            }
        };

        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [userData, loadData, navigate]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        try {
            if (editingGrupo) {
                await api.put(`/api/admin/groups/${editingGrupo.id}`, formData);
            } else {
                await api.post('/api/admin/groups', formData);
            }
            setShowModal(false);
            setEditingGrupo(null);
            setFormData({ nombre: '', carrera: 'DSM', turno: 'Matutino', cicloActivo: '2024-2' });
            loadData();
        } catch (err) {
            console.error('Error saving grupo:', err);
            setError(err.response?.data?.message || 'Error al guardar grupo');
        }
    };

    const handleEdit = (grupo) => {
        setEditingGrupo(grupo);
        setFormData({
            nombre: grupo.nombre,
            carrera: grupo.carrera,
            turno: grupo.turno,
            cicloActivo: grupo.cicloActivo
        });
        setShowModal(true);
    };

    const handleDelete = async (id) => {
        if (!confirm('¿Estás seguro de eliminar este grupo?')) return;

        try {
            await api.delete(`/api/admin/groups/${id}`);
            loadData();
        } catch (err) {
            console.error('Error deleting grupo:', err);
            setError('Error al eliminar grupo');
        }
    };

    const openNewModal = () => {
        setEditingGrupo(null);
        setFormData({ nombre: '', carrera: 'DSM', turno: 'Matutino', cicloActivo: '2024-2' });
        setShowModal(true);
    };

    const handleLogout = async () => {
        try {
            await signOut(auth);
            navigate('/login');
        } catch (error) {
            console.error('Error al cerrar sesión:', error);
        }
    };

    // Obtener iniciales del nombre
    const getInitials = () => {
        if (!userData?.nombre) return 'UI';
        const names = userData.nombre.split(' ');
        if (names.length >= 2) {
            return (names[0][0] + names[1][0]).toUpperCase();
        }
        return userData.nombre.substring(0, 2).toUpperCase();
    };

    if (loading) {
        return (
            <div style={styles.container}>
                <div style={styles.loading}>Cargando...</div>
            </div>
        );
    }

    return (
        <div style={styles.container}>
            {/* User Profile Header */}
            <div style={styles.userHeader}>
                <div style={styles.welcomeText}>
                    Bienvenido, <strong>{userData?.nombre || 'Uziel Isaac'}</strong>
                </div>
                <div
                    style={styles.avatarContainer}
                    ref={menuRef}
                    onClick={() => setShowLogoutMenu(!showLogoutMenu)}
                >
                    <div style={styles.avatar}>
                        {getInitials()}
                    </div>
                    {showLogoutMenu && (
                        <div style={styles.logoutMenu}>
                            <button onClick={handleLogout} style={styles.logoutButton}>
                                <LogOut size={16} />
                                Cerrar Sesión
                            </button>
                        </div>
                    )}
                </div>
            </div>

            <div style={styles.header}>
                <h1 style={styles.title}>Panel de Administración</h1>
                {activeTab === 'grupos' && (
                    <button onClick={openNewModal} style={styles.addButton}>
                        <Plus size={20} />
                        Nuevo Grupo
                    </button>
                )}
            </div>

            {/* Navigation Tabs */}
            <div style={styles.tabsContainer}>
                <button
                    onClick={() => setActiveTab('grupos')}
                    style={{
                        ...styles.tab,
                        ...(activeTab === 'grupos' ? styles.activeTab : {})
                    }}
                >
                    Grupos
                </button>
                <button
                    onClick={() => navigate('/admin/carreras')}
                    style={styles.tab}
                >
                    Carreras
                </button>
                <button
                    onClick={() => navigate('/admin/materias')}
                    style={styles.tab}
                >
                    Materias
                </button>
                <button
                    onClick={() => navigate('/admin/students')}
                    style={styles.tab}
                >
                    Alumnos
                </button>
                <button
                    onClick={() => navigate('/admin/teachers')}
                    style={styles.tab}
                >
                    Docentes
                </button>
            </div>

            {error && (
                <div style={styles.errorBanner}>
                    {error}
                    <button onClick={() => setError('')} style={styles.closeError}>
                        <X size={16} />
                    </button>
                </div>
            )}

            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Nombre</th>
                            <th style={styles.th}>Carrera</th>
                            <th style={styles.th}>Turno</th>
                            <th style={styles.th}>Ciclo Activo</th>
                            <th style={styles.th}>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        {grupos.length === 0 ? (
                            <tr>
                                <td colSpan="5" style={styles.emptyState}>
                                    No hay grupos creados. Haz clic en "Nuevo Grupo" para crear uno.
                                </td>
                            </tr>
                        ) : (
                            grupos.map(grupo => (
                                <tr key={grupo.id} style={styles.tr}>
                                    <td style={styles.td}>{grupo.nombre}</td>
                                    <td style={styles.td}>{grupo.carrera}</td>
                                    <td style={styles.td}>{grupo.turno}</td>
                                    <td style={styles.td}>{grupo.cicloActivo}</td>
                                    <td style={styles.td}>
                                        <div style={styles.actions}>
                                            <button
                                                onClick={() => handleEdit(grupo)}
                                                style={styles.editButton}
                                                title="Editar"
                                            >
                                                <Edit2 size={16} />
                                            </button>
                                            <button
                                                onClick={() => handleDelete(grupo.id)}
                                                style={styles.deleteButton}
                                                title="Eliminar"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Modal */}
            {showModal && (
                <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                    <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
                        <div style={styles.modalHeader}>
                            <h2 style={styles.modalTitle}>
                                {editingGrupo ? 'Editar Grupo' : 'Nuevo Grupo'}
                            </h2>
                            <button onClick={() => setShowModal(false)} style={styles.closeButton}>
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} style={styles.form}>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Nombre del Grupo</label>
                                <input
                                    type="text"
                                    value={formData.nombre}
                                    onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                                    placeholder="Ej: 5A, 6B"
                                    style={styles.input}
                                    required
                                />
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.label}>Carrera</label>
                                <select
                                    value={formData.carrera}
                                    onChange={(e) => setFormData({ ...formData, carrera: e.target.value })}
                                    style={styles.input}
                                    required
                                >
                                    <option value="DSM">Desarrollo de Software Multiplataforma</option>
                                    {carreras.filter(c => c.id !== 'DSM').map(c => (
                                        <option key={c.id} value={c.id}>{c.nombre}</option>
                                    ))}
                                </select>
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.label}>Turno</label>
                                <select
                                    value={formData.turno}
                                    onChange={(e) => setFormData({ ...formData, turno: e.target.value })}
                                    style={styles.input}
                                    required
                                >
                                    <option value="Matutino">Matutino</option>
                                    <option value="Vespertino">Vespertino</option>
                                </select>
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.label}>Ciclo Activo</label>
                                <input
                                    type="text"
                                    value={formData.cicloActivo}
                                    onChange={(e) => setFormData({ ...formData, cicloActivo: e.target.value })}
                                    placeholder="Ej: 2024-2"
                                    style={styles.input}
                                    required
                                />
                            </div>

                            <div style={styles.modalActions}>
                                <button
                                    type="button"
                                    onClick={() => setShowModal(false)}
                                    style={styles.cancelButton}
                                >
                                    Cancelar
                                </button>
                                <button type="submit" style={styles.submitButton}>
                                    <Check size={16} />
                                    {editingGrupo ? 'Guardar Cambios' : 'Crear Grupo'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}

const styles = {
    container: {
        padding: '2rem',
        maxWidth: '1200px',
        margin: '0 auto'
    },
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '2rem'
    },
    userHeader: {
        display: 'flex',
        justifyContent: 'flex-end',
        alignItems: 'center',
        gap: '1rem',
        marginBottom: '1rem'
    },
    welcomeText: {
        color: '#4b5563',
        fontSize: '0.95rem'
    },
    avatarContainer: {
        position: 'relative'
    },
    avatar: {
        width: '40px',
        height: '40px',
        borderRadius: '50%',
        backgroundColor: '#111827',
        color: 'white',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        fontWeight: 'bold',
        fontSize: '1rem',
        cursor: 'pointer',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
    },
    logoutMenu: {
        position: 'absolute',
        top: '100%',
        right: 0,
        marginTop: '0.5rem',
        backgroundColor: 'white',
        borderRadius: '8px',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
        padding: '0.5rem',
        minWidth: '150px',
        zIndex: 50
    },
    logoutButton: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        width: '100%',
        padding: '0.75rem 1rem',
        border: 'none',
        background: 'transparent',
        color: '#ef4444',
        cursor: 'pointer',
        fontSize: '0.9rem',
        borderRadius: '4px',
        fontWeight: '500',
        transition: 'background-color 0.2s'
    },
    title: {
        fontSize: '2rem',
        fontWeight: 'bold',
        color: '#111827'
    },
    addButton: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        padding: '0.75rem 1.5rem',
        backgroundColor: '#111827',
        color: 'white',
        border: 'none',
        borderRadius: '8px',
        cursor: 'pointer',
        fontSize: '1rem',
        fontWeight: '500'
    },
    tabsContainer: {
        display: 'flex',
        gap: '1rem',
        marginBottom: '2rem',
        borderBottom: '2px solid #e5e7eb'
    },
    tab: {
        padding: '0.75rem 1.5rem',
        backgroundColor: 'transparent',
        color: '#6b7280',
        border: 'none',
        borderBottom: '2px solid transparent',
        cursor: 'pointer',
        fontSize: '1rem',
        fontWeight: '500',
        marginBottom: '-2px',
        transition: 'all 0.2s'
    },
    activeTab: {
        color: '#111827',
        borderBottomColor: '#111827'
    },
    loading: {
        textAlign: 'center',
        padding: '3rem',
        fontSize: '1.125rem',
        color: '#6b7280'
    },
    errorBanner: {
        backgroundColor: '#fee2e2',
        color: '#991b1b',
        padding: '1rem',
        borderRadius: '8px',
        marginBottom: '1rem',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
    },
    closeError: {
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        color: '#991b1b'
    },
    tableContainer: {
        backgroundColor: 'white',
        borderRadius: '12px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
        overflow: 'hidden'
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse'
    },
    th: {
        padding: '1rem',
        textAlign: 'left',
        backgroundColor: '#f9fafb',
        fontWeight: '600',
        color: '#374151',
        borderBottom: '1px solid #e5e7eb'
    },
    tr: {
        borderBottom: '1px solid #e5e7eb'
    },
    td: {
        padding: '1rem',
        color: '#111827'
    },
    emptyState: {
        padding: '3rem',
        textAlign: 'center',
        color: '#6b7280'
    },
    actions: {
        display: 'flex',
        gap: '0.5rem'
    },
    editButton: {
        padding: '0.5rem',
        backgroundColor: '#dbeafe',
        color: '#1e40af',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer'
    },
    deleteButton: {
        padding: '0.5rem',
        backgroundColor: '#fee2e2',
        color: '#991b1b',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer'
    },
    modalOverlay: {
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000
    },
    modal: {
        backgroundColor: 'white',
        borderRadius: '12px',
        padding: '2rem',
        maxWidth: '500px',
        width: '90%',
        maxHeight: '90vh',
        overflow: 'auto'
    },
    modalHeader: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '1.5rem'
    },
    modalTitle: {
        fontSize: '1.5rem',
        fontWeight: 'bold',
        color: '#111827'
    },
    closeButton: {
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        color: '#6b7280'
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '1rem'
    },
    formGroup: {
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem'
    },
    label: {
        fontSize: '0.875rem',
        fontWeight: '500',
        color: '#374151'
    },
    input: {
        padding: '0.75rem',
        border: '1px solid #d1d5db',
        borderRadius: '8px',
        fontSize: '1rem',
        outline: 'none'
    },
    modalActions: {
        display: 'flex',
        gap: '1rem',
        marginTop: '1rem'
    },
    cancelButton: {
        flex: 1,
        padding: '0.75rem',
        backgroundColor: '#f3f4f6',
        color: '#374151',
        border: 'none',
        borderRadius: '8px',
        cursor: 'pointer',
        fontSize: '1rem',
        fontWeight: '500'
    },
    submitButton: {
        flex: 1,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '0.5rem',
        padding: '0.75rem',
        backgroundColor: '#111827',
        color: 'white',
        border: 'none',
        borderRadius: '8px',
        cursor: 'pointer',
        fontSize: '1rem',
        fontWeight: '500'
    }
};
