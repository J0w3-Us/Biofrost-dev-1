import { useState, useEffect } from 'react';
import { Plus, Trash2, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api from '../../../lib/axios';

export default function CarrerasPanel() {
    const navigate = useNavigate();
    const [carreras, setCarreras] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [formData, setFormData] = useState({
        nombre: '',
        nivel: 'TSU'
    });

    useEffect(() => {
        fetchCarreras();
    }, []);

    const fetchCarreras = async () => {
        try {
            setLoading(true);
            const response = await api.get('/api/admin/carreras');
            setCarreras(response.data || []);
            setError('');
        } catch (err) {
            console.error('Error al cargar carreras:', err);
            setError('Error al cargar carreras');
            setCarreras([]);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        try {
            await api.post('/api/admin/carreras', formData);
            setShowModal(false);
            setFormData({ nombre: '', nivel: 'TSU' });
            fetchCarreras();
        } catch (err) {
            console.error('Error al crear carrera:', err);
            setError('Error al crear carrera');
        }
    };

    const handleDelete = async (id) => {
        if (!confirm('¿Estás seguro de eliminar esta carrera?')) return;

        try {
            await api.delete(`/api/admin/carreras/${id}`);
            fetchCarreras();
        } catch (err) {
            console.error('Error al eliminar carrera:', err);
            setError('Error al eliminar carrera');
        }
    };

    if (loading) return <div style={styles.loading}>Cargando...</div>;

    return (
        <div style={styles.container}>
            <div style={styles.header}>
                <div style={styles.headerLeft}>
                    <button
                        onClick={() => navigate('/admin')}
                        style={styles.backButton}
                        title="Volver al Panel Admin"
                    >
                        <ArrowLeft size={20} />
                    </button>
                    <h1 style={styles.title}>Gestión de Carreras</h1>
                </div>
                <button onClick={() => setShowModal(true)} style={styles.addButton}>
                    <Plus size={20} />
                    Nueva Carrera
                </button>
            </div>

            {error && <div style={styles.error}>{error}</div>}

            {/* Tabla de carreras */}
            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Nombre</th>
                            <th style={styles.th}>Nivel</th>
                            <th style={styles.th}>Estado</th>
                            <th style={styles.th}>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        {carreras.length === 0 ? (
                            <tr>
                                <td colSpan="4" style={styles.emptyMessage}>
                                    No hay carreras registradas. Haz clic en "Nueva Carrera" para agregar una.
                                </td>
                            </tr>
                        ) : (
                            carreras.map(carrera => (
                                <tr key={carrera.id} style={styles.tr}>
                                    <td style={styles.td}>{carrera.nombre}</td>
                                    <td style={styles.td}>{carrera.nivel}</td>
                                    <td style={styles.td}>
                                        <span style={carrera.activo ? styles.activeBadge : styles.inactiveBadge}>
                                            {carrera.activo ? 'Activa' : 'Inactiva'}
                                        </span>
                                    </td>
                                    <td style={styles.td}>
                                        <button
                                            onClick={() => handleDelete(carrera.id)}
                                            style={styles.deleteButton}
                                            title="Eliminar Carrera"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Modal para crear carrera */}
            {showModal && (
                <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                    <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
                        <h2 style={styles.modalTitle}>Nueva Carrera</h2>

                        <form onSubmit={handleSubmit}>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Nombre *</label>
                                <input
                                    type="text"
                                    value={formData.nombre}
                                    onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                                    style={styles.input}
                                    placeholder="Ej: Desarrollo de Software Multiplataforma"
                                    required
                                />
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.label}>Nivel *</label>
                                <select
                                    value={formData.nivel}
                                    onChange={(e) => setFormData({ ...formData, nivel: e.target.value })}
                                    style={styles.select}
                                    required
                                >
                                    <option value="TSU">TSU</option>
                                    <option value="Ingeniería">Ingeniería</option>
                                    <option value="Licenciatura">Licenciatura</option>
                                </select>
                            </div>

                            <div style={styles.modalActions}>
                                <button
                                    type="button"
                                    onClick={() => setShowModal(false)}
                                    style={styles.cancelButton}
                                >
                                    Cancelar
                                </button>
                                <button
                                    type="submit"
                                    style={styles.submitButton}
                                >
                                    Crear Carrera
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
        maxWidth: '1400px',
        margin: '0 auto'
    },
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '2rem'
    },
    headerLeft: {
        display: 'flex',
        alignItems: 'center',
        gap: '1rem'
    },
    backButton: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0.5rem',
        backgroundColor: '#f3f4f6',
        color: '#374151',
        border: 'none',
        borderRadius: '8px',
        cursor: 'pointer',
        transition: 'background-color 0.2s'
    },
    title: {
        fontSize: '2rem',
        fontWeight: 'bold',
        color: '#1a1a1a'
    },
    addButton: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        padding: '0.75rem 1.5rem',
        backgroundColor: '#3b82f6',
        color: 'white',
        border: 'none',
        borderRadius: '8px',
        cursor: 'pointer',
        fontSize: '1rem',
        fontWeight: '500'
    },
    loading: {
        textAlign: 'center',
        padding: '3rem',
        fontSize: '1.2rem',
        color: '#666'
    },
    error: {
        padding: '1rem',
        backgroundColor: '#fee2e2',
        color: '#dc2626',
        borderRadius: '8px',
        marginBottom: '1rem'
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
        borderBottom: '2px solid #e5e7eb'
    },
    tr: {
        borderBottom: '1px solid #e5e7eb',
        transition: 'background-color 0.2s'
    },
    td: {
        padding: '1rem',
        color: '#1f2937'
    },
    emptyMessage: {
        textAlign: 'center',
        padding: '3rem',
        color: '#9ca3af',
        fontStyle: 'italic'
    },
    activeBadge: {
        padding: '0.25rem 0.75rem',
        backgroundColor: '#d1fae5',
        color: '#065f46',
        borderRadius: '12px',
        fontSize: '0.875rem',
        fontWeight: '500'
    },
    inactiveBadge: {
        padding: '0.25rem 0.75rem',
        backgroundColor: '#fee2e2',
        color: '#991b1b',
        borderRadius: '12px',
        fontSize: '0.875rem',
        fontWeight: '500'
    },
    deleteButton: {
        padding: '0.5rem',
        backgroundColor: '#fee2e2',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        color: '#dc2626',
        transition: 'background-color 0.2s'
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
        width: '90%',
        maxWidth: '500px'
    },
    modalTitle: {
        fontSize: '1.5rem',
        fontWeight: 'bold',
        color: '#1a1a1a',
        marginBottom: '1.5rem'
    },
    formGroup: {
        marginBottom: '1.5rem'
    },
    label: {
        display: 'block',
        fontSize: '0.875rem',
        fontWeight: '500',
        color: '#374151',
        marginBottom: '0.5rem'
    },
    input: {
        width: '100%',
        padding: '0.75rem',
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '1rem'
    },
    select: {
        width: '100%',
        padding: '0.75rem',
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '1rem',
        backgroundColor: 'white'
    },
    modalActions: {
        display: 'flex',
        gap: '1rem',
        justifyContent: 'flex-end',
        marginTop: '1.5rem'
    },
    cancelButton: {
        padding: '0.75rem 1.5rem',
        backgroundColor: '#f3f4f6',
        color: '#374151',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        fontSize: '1rem',
        fontWeight: '500'
    },
    submitButton: {
        padding: '0.75rem 1.5rem',
        backgroundColor: '#3b82f6',
        color: 'white',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        fontSize: '1rem',
        fontWeight: '500'
    }
};
