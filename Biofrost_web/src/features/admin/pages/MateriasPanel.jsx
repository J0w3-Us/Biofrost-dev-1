import { useState, useEffect } from 'react';
import { Pencil, Trash2, Plus, X, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api from '../../../lib/axios';

export default function MateriasPanel() {
    const navigate = useNavigate();
    const [materias, setMaterias] = useState([]);
    const [carreras, setCarreras] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [editingMateria, setEditingMateria] = useState(null);
    const [filterCarrera, setFilterCarrera] = useState('');

    // Form state
    const [formData, setFormData] = useState({
        nombre: '',
        clave: '',
        carreraId: '',
        cuatrimestre: 1,
        esAltaPrioridad: false
    });

    useEffect(() => {
        fetchData();
    }, [filterCarrera]);

    const fetchData = async () => {
        try {
            setLoading(true);
            const [materiasRes, carrerasRes] = await Promise.all([
                api.get(`/api/admin/materias${filterCarrera ? `?carreraId=${filterCarrera}` : ''}`),
                api.get('/api/admin/carreras')
            ]);
            setMaterias(materiasRes.data);
            setCarreras(carrerasRes.data);
        } catch (err) {
            setError('Error al cargar datos');
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingMateria) {
                await api.put(`/api/admin/materias/${editingMateria.id}`, formData);
            } else {
                await api.post('/api/admin/materias', formData);
            }
            setShowModal(false);
            resetForm();
            fetchData();
        } catch (err) {
            setError('Error al guardar materia');
            console.error(err);
        }
    };

    const handleEdit = (materia) => {
        setEditingMateria(materia);
        setFormData({
            nombre: materia.nombre,
            clave: materia.clave,
            carreraId: materia.carreraId,
            cuatrimestre: materia.cuatrimestre,
            esAltaPrioridad: materia.esAltaPrioridad || false
        });
        setShowModal(true);
    };

    const handleDelete = async (id) => {
        if (!confirm('¿Estás seguro de eliminar esta materia?')) return;
        try {
            await api.delete(`/api/admin/materias/${id}`);
            fetchData();
        } catch (err) {
            setError('Error al eliminar materia');
            console.error(err);
        }
    };

    const resetForm = () => {
        setFormData({ nombre: '', clave: '', carreraId: '', cuatrimestre: 1, esAltaPrioridad: false });
        setEditingMateria(null);
    };

    const getCarreraNombre = (carreraId) => {
        const carrera = carreras.find(c => c.id === carreraId);
        return carrera?.nombre || carreraId;
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
                    <h1 style={styles.title}>Gestión de Materias</h1>
                </div>
                <button onClick={() => setShowModal(true)} style={styles.addButton}>
                    <Plus size={20} />
                    Nueva Materia
                </button>
            </div>

            {error && <div style={styles.error}>{error}</div>}

            {/* Filtro por carrera */}
            <div style={styles.filterSection}>
                <label style={styles.filterLabel}>Filtrar por carrera:</label>
                <select
                    value={filterCarrera}
                    onChange={(e) => setFilterCarrera(e.target.value)}
                    style={styles.filterSelect}
                >
                    <option value="">Todas las carreras</option>
                    {carreras.map(carrera => (
                        <option key={carrera.id} value={carrera.id}>{carrera.nombre}</option>
                    ))}
                </select>
            </div>

            {/* Tabla de materias */}
            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Nombre</th>
                            <th style={styles.th}>Clave</th>
                            <th style={styles.th}>Carrera</th>
                            <th style={styles.th}>Cuatrimestre</th>
                            <th style={styles.th}>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        {materias.length === 0 ? (
                            <tr>
                                <td colSpan="5" style={styles.emptyMessage}>
                                    No hay materias registradas
                                </td>
                            </tr>
                        ) : (
                            materias.map(materia => (
                                <tr key={materia.id} style={styles.tr}>
                                    <td style={styles.td}>
                                        {materia.nombre}
                                        {materia.esAltaPrioridad && (
                                            <span style={styles.priorityBadge}>⭐ Prioritaria</span>
                                        )}
                                    </td>
                                    <td style={styles.td}>{materia.clave}</td>
                                    <td style={styles.td}>{getCarreraNombre(materia.carreraId)}</td>
                                    <td style={styles.td}>{materia.cuatrimestre}</td>
                                    <td style={styles.td}>
                                        <div style={styles.actions}>
                                            <button
                                                onClick={() => handleEdit(materia)}
                                                style={styles.editButton}
                                                title="Editar"
                                            >
                                                <Pencil size={16} />
                                            </button>
                                            <button
                                                onClick={() => handleDelete(materia.id)}
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

            {/* Modal para crear/editar */}
            {showModal && (
                <div style={styles.modalOverlay}>
                    <div style={styles.modal}>
                        <div style={styles.modalHeader}>
                            <h2 style={styles.modalTitle}>
                                {editingMateria ? 'Editar Materia' : 'Nueva Materia'}
                            </h2>
                            <button
                                onClick={() => {
                                    setShowModal(false);
                                    resetForm();
                                }}
                                style={styles.closeButton}
                            >
                                <X size={24} />
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} style={styles.form}>
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Nombre *</label>
                                <input
                                    type="text"
                                    value={formData.nombre}
                                    onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                                    style={styles.input}
                                    required
                                    placeholder="Ej: Proyecto Integrador I"
                                />
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.label}>Clave</label>
                                <input
                                    type="text"
                                    value={formData.clave}
                                    onChange={(e) => setFormData({ ...formData, clave: e.target.value })}
                                    style={styles.input}
                                    placeholder="Ej: PI1"
                                />
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.label}>Carrera *</label>
                                <select
                                    value={formData.carreraId}
                                    onChange={(e) => setFormData({ ...formData, carreraId: e.target.value })}
                                    style={styles.select}
                                    required
                                >
                                    <option value="">Seleccionar carrera</option>
                                    {carreras.map(carrera => (
                                        <option key={carrera.id} value={carrera.id}>{carrera.nombre}</option>
                                    ))}
                                </select>
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.label}>Cuatrimestre *</label>
                                <input
                                    type="number"
                                    min="1"
                                    max="10"
                                    value={formData.cuatrimestre}
                                    onChange={(e) => setFormData({ ...formData, cuatrimestre: parseInt(e.target.value) })}
                                    style={styles.input}
                                    required
                                />
                            </div>

                            <div style={styles.formGroup}>
                                <label style={styles.checkboxLabel}>
                                    <input
                                        type="checkbox"
                                        checked={formData.esAltaPrioridad}
                                        onChange={(e) => setFormData({ ...formData, esAltaPrioridad: e.target.checked })}
                                        style={styles.checkbox}
                                    />
                                    Alta Prioridad (Materia Integradora)
                                </label>
                            </div>

                            <div style={styles.modalActions}>
                                <button
                                    type="button"
                                    onClick={() => {
                                        setShowModal(false);
                                        resetForm();
                                    }}
                                    style={styles.cancelButton}
                                >
                                    Cancelar
                                </button>
                                <button type="submit" style={styles.submitButton}>
                                    {editingMateria ? 'Actualizar' : 'Crear'}
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
        fontWeight: '500',
        transition: 'background-color 0.2s'
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
    filterSection: {
        marginBottom: '1.5rem',
        display: 'flex',
        alignItems: 'center',
        gap: '1rem'
    },
    filterLabel: {
        fontSize: '1rem',
        fontWeight: '500',
        color: '#374151'
    },
    filterSelect: {
        padding: '0.5rem 1rem',
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '1rem',
        minWidth: '200px'
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
    actions: {
        display: 'flex',
        gap: '0.5rem'
    },
    editButton: {
        padding: '0.5rem',
        backgroundColor: '#f3f4f6',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        color: '#3b82f6',
        transition: 'background-color 0.2s'
    },
    deleteButton: {
        padding: '0.5rem',
        backgroundColor: '#f3f4f6',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        color: '#ef4444',
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
        maxWidth: '500px',
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
        color: '#1a1a1a'
    },
    closeButton: {
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        color: '#6b7280',
        padding: '0.25rem'
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '1.25rem'
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
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '1rem'
    },
    select: {
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
        marginTop: '1rem'
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
    },
    priorityBadge: {
        marginLeft: '0.5rem',
        padding: '0.2rem 0.5rem',
        backgroundColor: '#fffbeb',
        color: '#d97706',
        fontSize: '0.75rem',
        borderRadius: '4px',
        border: '1px solid #fcd34d'
    },
    checkboxLabel: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        cursor: 'pointer',
        fontSize: '0.9rem',
        color: '#374151'
    },
    checkbox: {
        width: '16px',
        height: '16px',
        cursor: 'pointer'
    }
};
