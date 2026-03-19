import { useState, useEffect } from 'react';
import { Users, FolderOpen, Plus, Settings, BookOpen, Trash2 } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import api from '../../../lib/axios';

export function AdminPage() {
    const { userData, logout } = useAuth();
    const [activeTab, setActiveTab] = useState('grupos');
    const [groups, setGroups] = useState([]);
    const [materias, setMaterias] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [showMateriaModal, setShowMateriaModal] = useState(false);

    // Form state - Grupos
    const [form, setForm] = useState({
        nombre: '',
        turno: 'Matutino',
        cicloActivo: '2026-1'
    });

    // Form state - Materias
    const [materiaForm, setMateriaForm] = useState({
        nombre: '',
        clave: '',
        cuatrimestre: 5
    });

    const isAdmin = userData?.rol === 'SuperAdmin' || userData?.rol?.toLowerCase() === 'admin' || userData?.rol === 'Docente';

    useEffect(() => {
        if (isAdmin) {
            fetchGroups();
            fetchMaterias();
        } else {
            setLoading(false);
        }
    }, [isAdmin]);

    const fetchGroups = async () => {
        try {
            const response = await api.get('/api/admin/groups');
            setGroups(response.data || []);
        } catch (error) {
            console.error('Error fetching groups:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchMaterias = async () => {
        try {
            const response = await api.get('/api/admin/materias');
            setMaterias(response.data || []);
        } catch (error) {
            console.error('Error fetching materias:', error);
        }
    };

    const handleCreateGroup = async (e) => {
        e.preventDefault();
        try {
            await api.post('/api/admin/groups', {
                nombre: form.nombre,
                turno: form.turno,
                cicloActivo: form.cicloActivo,
                docenteId: userData?.id || 'admin'
            });
            setShowCreateModal(false);
            setForm({ nombre: '', turno: 'Matutino', cicloActivo: '2026-1' });
            fetchGroups();
        } catch (error) {
            console.error('Error creating group:', error);
        }
    };

    const handleCreateMateria = async (e) => {
        e.preventDefault();
        try {
            await api.post('/api/admin/materias', materiaForm);
            setShowMateriaModal(false);
            setMateriaForm({ nombre: '', clave: '', cuatrimestre: 5 });
            fetchMaterias();
        } catch (error) {
            console.error('Error creating materia:', error);
        }
    };

    const handleDeleteMateria = async (id) => {
        if (!confirm('¿Eliminar esta materia?')) return;
        try {
            await api.delete(`/api/admin/materias/${id}`);
            fetchMaterias();
        } catch (error) {
            console.error('Error deleting materia:', error);
        }
    };

    if (!isAdmin) {
        return (
            <div style={styles.accessDenied}>
                <Settings size={48} style={{ opacity: 0.5 }} />
                <h1 style={{ fontSize: '24px', marginTop: '16px' }}>Acceso Denegado</h1>
                <p style={{ color: '#64748b' }}>No tienes permisos para acceder a esta sección.</p>
            </div>
        );
    }

    return (
        <div style={styles.container}>
            {/* Header */}
            <header style={styles.header}>
                <div style={styles.headerInner}>
                    <div style={styles.headerLeft}>
                        <Settings size={24} style={{ color: '#4f46e5' }} />
                        <h1 style={styles.title}>Panel de Administración</h1>
                    </div>
                    <div style={styles.headerRight}>
                        <a href="/dashboard" style={styles.backLink}>← Volver al Dashboard</a>
                        <button onClick={logout} style={styles.logoutBtn}>Cerrar sesión</button>
                    </div>
                </div>
            </header>

            {/* Tabs */}
            <div style={styles.tabsContainer}>
                <button
                    style={{ ...styles.tab, ...(activeTab === 'grupos' ? styles.tabActive : {}) }}
                    onClick={() => setActiveTab('grupos')}
                >
                    <Users size={18} /> Grupos
                </button>
                <button
                    style={{ ...styles.tab, ...(activeTab === 'materias' ? styles.tabActive : {}) }}
                    onClick={() => setActiveTab('materias')}
                >
                    <BookOpen size={18} /> Materias
                </button>
            </div>

            {/* Content */}
            <main style={styles.main}>
                {/* Stats */}
                <div style={styles.stats}>
                    <div style={styles.statCard}>
                        <div style={{ ...styles.statIcon, background: '#dbeafe' }}>
                            <Users size={24} style={{ color: '#3b82f6' }} />
                        </div>
                        <div>
                            <p style={styles.statNumber}>{groups.length}</p>
                            <p style={styles.statLabel}>Grupos Activos</p>
                        </div>
                    </div>
                    <div style={styles.statCard}>
                        <div style={{ ...styles.statIcon, background: '#dcfce7' }}>
                            <BookOpen size={24} style={{ color: '#22c55e' }} />
                        </div>
                        <div>
                            <p style={styles.statNumber}>{materias.length}</p>
                            <p style={styles.statLabel}>Materias</p>
                        </div>
                    </div>
                </div>

                {/* GRUPOS TAB */}
                {activeTab === 'grupos' && (
                    <div style={styles.section}>
                        <div style={styles.sectionHeader}>
                            <h2 style={styles.sectionTitle}>Grupos</h2>
                            <button onClick={() => setShowCreateModal(true)} style={styles.addButton}>
                                <Plus size={16} /> Nuevo Grupo
                            </button>
                        </div>

                        {loading ? (
                            <p style={styles.loading}>Cargando...</p>
                        ) : groups.length === 0 ? (
                            <p style={styles.empty}>No hay grupos creados.</p>
                        ) : (
                            <div style={styles.list}>
                                {groups.map(group => (
                                    <div key={group.id} style={styles.listItem}>
                                        <div style={styles.listItemLeft}>
                                            <div style={styles.listIcon}>
                                                <FolderOpen size={20} style={{ color: '#3b82f6' }} />
                                            </div>
                                            <div>
                                                <p style={styles.listTitle}>{group.nombre}</p>
                                                <p style={styles.listMeta}>{group.carrera} · {group.turno} · {group.cicloActivo}</p>
                                            </div>
                                        </div>
                                        <span style={group.isActive ? styles.badgeActive : styles.badgeInactive}>
                                            {group.isActive ? 'Activo' : 'Inactivo'}
                                        </span>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                )}

                {/* MATERIAS TAB */}
                {activeTab === 'materias' && (
                    <div style={styles.section}>
                        <div style={styles.sectionHeader}>
                            <h2 style={styles.sectionTitle}>Materias del Programa</h2>
                            <button onClick={() => setShowMateriaModal(true)} style={styles.addButton}>
                                <Plus size={16} /> Nueva Materia
                            </button>
                        </div>

                        {materias.length === 0 ? (
                            <p style={styles.empty}>No hay materias creadas.</p>
                        ) : (
                            <div style={styles.list}>
                                {materias.map(materia => (
                                    <div key={materia.id} style={styles.listItem}>
                                        <div style={styles.listItemLeft}>
                                            <div style={{ ...styles.listIcon, background: '#dcfce7' }}>
                                                <BookOpen size={20} style={{ color: '#22c55e' }} />
                                            </div>
                                            <div>
                                                <p style={styles.listTitle}>{materia.nombre}</p>
                                                <p style={styles.listMeta}>Clave: {materia.clave} · Cuatrimestre: {materia.cuatrimestre}</p>
                                            </div>
                                        </div>
                                        <button onClick={() => handleDeleteMateria(materia.id)} style={styles.deleteBtn}>
                                            <Trash2 size={14} />
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                )}
            </main>

            {/* Create Group Modal */}
            {showCreateModal && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modal}>
                        <h3 style={styles.modalTitle}>Crear Nuevo Grupo</h3>
                        <form onSubmit={handleCreateGroup}>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Nombre del Grupo</label>
                                <input
                                    type="text"
                                    value={form.nombre}
                                    onChange={e => setForm({ ...form, nombre: e.target.value })}
                                    placeholder="Ej: 5A"
                                    style={styles.input}
                                    required
                                />
                            </div>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Turno</label>
                                <select
                                    value={form.turno}
                                    onChange={e => setForm({ ...form, turno: e.target.value })}
                                    style={styles.input}
                                >
                                    <option>Matutino</option>
                                    <option>Vespertino</option>
                                </select>
                            </div>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Ciclo Activo</label>
                                <input
                                    type="text"
                                    value={form.cicloActivo}
                                    onChange={e => setForm({ ...form, cicloActivo: e.target.value })}
                                    placeholder="Ej: 2026-1"
                                    style={styles.input}
                                    required
                                />
                            </div>
                            <div style={styles.modalActions}>
                                <button type="button" onClick={() => setShowCreateModal(false)} style={styles.cancelBtn}>
                                    Cancelar
                                </button>
                                <button type="submit" style={styles.submitBtn}>
                                    Crear Grupo
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Create Materia Modal */}
            {showMateriaModal && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modal}>
                        <h3 style={styles.modalTitle}>Crear Nueva Materia</h3>
                        <form onSubmit={handleCreateMateria}>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Nombre de la Materia</label>
                                <input
                                    type="text"
                                    value={materiaForm.nombre}
                                    onChange={e => setMateriaForm({ ...materiaForm, nombre: e.target.value })}
                                    placeholder="Ej: Integradora II"
                                    style={styles.input}
                                    required
                                />
                            </div>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Clave</label>
                                <input
                                    type="text"
                                    value={materiaForm.clave}
                                    onChange={e => setMateriaForm({ ...materiaForm, clave: e.target.value })}
                                    placeholder="Ej: DSM-501"
                                    style={styles.input}
                                    required
                                />
                            </div>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Cuatrimestre</label>
                                <input
                                    type="number"
                                    value={materiaForm.cuatrimestre}
                                    onChange={e => setMateriaForm({ ...materiaForm, cuatrimestre: parseInt(e.target.value) })}
                                    min="1"
                                    max="10"
                                    style={styles.input}
                                    required
                                />
                            </div>
                            <div style={styles.modalActions}>
                                <button type="button" onClick={() => setShowMateriaModal(false)} style={styles.cancelBtn}>
                                    Cancelar
                                </button>
                                <button type="submit" style={styles.submitBtn}>
                                    Crear Materia
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
        minHeight: '100vh',
        background: '#f8fafc',
        fontFamily: "'Inter', -apple-system, sans-serif"
    },
    header: {
        background: 'white',
        borderBottom: '1px solid #e2e8f0',
        padding: '16px 24px'
    },
    headerInner: {
        maxWidth: '1200px',
        margin: '0 auto',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
    },
    headerLeft: {
        display: 'flex',
        alignItems: 'center',
        gap: '12px'
    },
    title: {
        fontSize: '20px',
        fontWeight: '700',
        color: '#1e293b',
        margin: 0
    },
    headerRight: {
        display: 'flex',
        alignItems: 'center',
        gap: '16px'
    },
    backLink: {
        color: '#4f46e5',
        textDecoration: 'none',
        fontWeight: '500'
    },
    logoutBtn: {
        background: 'none',
        border: 'none',
        color: '#64748b',
        cursor: 'pointer'
    },
    tabsContainer: {
        maxWidth: '1200px',
        margin: '0 auto',
        padding: '16px 24px',
        display: 'flex',
        gap: '8px'
    },
    tab: {
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        padding: '10px 20px',
        border: 'none',
        background: 'white',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: '500',
        color: '#64748b',
        borderRadius: '8px',
        transition: 'all 0.2s'
    },
    tabActive: {
        background: '#4f46e5',
        color: 'white'
    },
    main: {
        maxWidth: '1200px',
        margin: '0 auto',
        padding: '0 24px 40px'
    },
    stats: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '16px',
        marginBottom: '24px'
    },
    statCard: {
        background: 'white',
        padding: '20px',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        display: 'flex',
        alignItems: 'center',
        gap: '16px'
    },
    statIcon: {
        width: '48px',
        height: '48px',
        borderRadius: '10px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
    },
    statNumber: {
        fontSize: '24px',
        fontWeight: '700',
        color: '#1e293b',
        margin: 0
    },
    statLabel: {
        fontSize: '14px',
        color: '#64748b',
        margin: 0
    },
    section: {
        background: 'white',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        overflow: 'hidden'
    },
    sectionHeader: {
        padding: '16px 20px',
        borderBottom: '1px solid #e2e8f0',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
    },
    sectionTitle: {
        fontSize: '18px',
        fontWeight: '600',
        color: '#1e293b',
        margin: 0
    },
    addButton: {
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
        padding: '8px 16px',
        background: '#4f46e5',
        color: 'white',
        border: 'none',
        borderRadius: '8px',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: '500'
    },
    list: {
        display: 'flex',
        flexDirection: 'column'
    },
    listItem: {
        padding: '16px 20px',
        borderBottom: '1px solid #f1f5f9',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
    },
    listItemLeft: {
        display: 'flex',
        alignItems: 'center',
        gap: '12px'
    },
    listIcon: {
        width: '40px',
        height: '40px',
        background: '#dbeafe',
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
    },
    listTitle: {
        fontSize: '15px',
        fontWeight: '600',
        color: '#1e293b',
        margin: 0
    },
    listMeta: {
        fontSize: '13px',
        color: '#64748b',
        margin: '2px 0 0'
    },
    badgeActive: {
        padding: '4px 10px',
        background: '#dcfce7',
        color: '#15803d',
        borderRadius: '20px',
        fontSize: '12px',
        fontWeight: '500'
    },
    badgeInactive: {
        padding: '4px 10px',
        background: '#f1f5f9',
        color: '#64748b',
        borderRadius: '20px',
        fontSize: '12px',
        fontWeight: '500'
    },
    deleteBtn: {
        padding: '8px',
        background: '#fee2e2',
        color: '#dc2626',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer'
    },
    loading: {
        padding: '40px',
        textAlign: 'center',
        color: '#64748b'
    },
    empty: {
        padding: '40px',
        textAlign: 'center',
        color: '#94a3b8'
    },
    modalOverlay: {
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 50
    },
    modal: {
        background: 'white',
        borderRadius: '16px',
        padding: '24px',
        width: '100%',
        maxWidth: '400px'
    },
    modalTitle: {
        fontSize: '20px',
        fontWeight: '700',
        color: '#1e293b',
        marginBottom: '20px'
    },
    formGroup: {
        marginBottom: '16px'
    },
    label: {
        display: 'block',
        fontSize: '14px',
        fontWeight: '500',
        color: '#374151',
        marginBottom: '6px'
    },
    input: {
        width: '100%',
        padding: '10px 14px',
        border: '1px solid #d1d5db',
        borderRadius: '8px',
        fontSize: '14px',
        boxSizing: 'border-box'
    },
    modalActions: {
        display: 'flex',
        gap: '12px',
        marginTop: '24px'
    },
    cancelBtn: {
        flex: 1,
        padding: '10px',
        border: '1px solid #d1d5db',
        background: 'white',
        color: '#374151',
        borderRadius: '8px',
        cursor: 'pointer',
        fontWeight: '500'
    },
    submitBtn: {
        flex: 1,
        padding: '10px',
        border: 'none',
        background: '#4f46e5',
        color: 'white',
        borderRadius: '8px',
        cursor: 'pointer',
        fontWeight: '500'
    },
    accessDenied: {
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#f8fafc',
        textAlign: 'center'
    }
};

export default AdminPage;

