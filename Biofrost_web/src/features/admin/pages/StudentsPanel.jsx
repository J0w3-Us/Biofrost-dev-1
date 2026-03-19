import { useState, useEffect } from 'react';
import { Pencil, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api from '../../../lib/axios';

export default function StudentsPanel() {
    const navigate = useNavigate();
    const [students, setStudents] = useState([]);
    const [grupos, setGrupos] = useState([]);
    const [carreras, setCarreras] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [filterGrupo, setFilterGrupo] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [selectedStudent, setSelectedStudent] = useState(null);
    const [newGrupoId, setNewGrupoId] = useState('');

    useEffect(() => {
        fetchData();
    }, [filterGrupo]);

    const fetchData = async () => {
        try {
            setLoading(true);
            const [studentsRes, gruposRes, carrerasRes] = await Promise.all([
                api.get(`/api/admin/users/students${filterGrupo ? `?grupoId=${filterGrupo}` : ''}`),
                api.get('/api/admin/groups'),
                api.get('/api/admin/carreras')
            ]);
            setStudents(studentsRes.data);
            setGrupos(gruposRes.data);
            setCarreras(carrerasRes.data);
        } catch (err) {
            setError('Error al cargar datos');
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleChangeGroup = async () => {
        if (!selectedStudent || !newGrupoId) return;

        try {
            await api.put(`/api/admin/users/students/${selectedStudent.id}`, {
                grupoId: newGrupoId
            });
            setShowModal(false);
            setSelectedStudent(null);
            fetchData();
        } catch (err) {
            setError('Error al cambiar grupo');
            console.error(err);
        }
    };

    const openEditModal = (student) => {
        setSelectedStudent(student);
        setNewGrupoId(student.grupoId);
        setShowModal(true);
    };

    if (loading) return <div style={styles.loading}>Cargando...</div>;

    const getGrupoNombre = (id) => grupos.find(g => g.id === id)?.nombre || id || 'Sin Grupo';
    const getCarreraNombre = (id) => carreras.find(c => c.id === id)?.nombre || id || 'Sin Carrera';

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
                    <h1 style={styles.title}>Gestión de Alumnos</h1>
                </div>
            </div>

            {error && <div style={styles.error}>{error}</div>}

            {/* Filtro por grupo */}
            <div style={styles.filterSection}>
                <label style={styles.filterLabel}>Filtrar por grupo:</label>
                <select
                    value={filterGrupo}
                    onChange={(e) => setFilterGrupo(e.target.value)}
                    style={styles.filterSelect}
                >
                    <option value="">Todos los grupos</option>
                    {grupos.map(grupo => (
                        <option key={grupo.id} value={grupo.id}>{grupo.nombre}</option>
                    ))}
                </select>
            </div>

            {/* Tabla de alumnos */}
            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Matrícula</th>
                            <th style={styles.th}>Nombre</th>
                            <th style={styles.th}>Email</th>
                            <th style={styles.th}>Grupo</th>
                            <th style={styles.th}>Carrera</th>
                            <th style={styles.th}>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        {students.length === 0 ? (
                            <tr>
                                <td colSpan="6" style={styles.emptyMessage}>
                                    No hay alumnos registrados
                                </td>
                            </tr>
                        ) : (
                            students.map(student => (
                                <tr key={student.id} style={styles.tr}>
                                    <td style={styles.td}>{student.matricula}</td>
                                    <td style={styles.td}>{student.nombre}</td>
                                    <td style={styles.td}>{student.email}</td>
                                    <td style={styles.td}>{getGrupoNombre(student.grupoId)}</td>
                                    <td style={styles.td}>{getCarreraNombre(student.carreraId)}</td>
                                    <td style={styles.td}>
                                        <button
                                            onClick={() => openEditModal(student)}
                                            style={styles.editButton}
                                            title="Cambiar Grupo"
                                        >
                                            <Pencil size={16} />
                                        </button>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Modal para cambiar grupo */}
            {showModal && selectedStudent && (
                <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                    <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
                        <h2 style={styles.modalTitle}>Cambiar Grupo</h2>

                        <div style={styles.studentInfo}>
                            <p><strong>Alumno:</strong> {selectedStudent.nombre}</p>
                            <p><strong>Matrícula:</strong> {selectedStudent.matricula}</p>
                            <p><strong>Grupo actual:</strong> {selectedStudent.grupoId}</p>
                        </div>

                        <div style={styles.formGroup}>
                            <label style={styles.label}>Nuevo Grupo</label>
                            <select
                                value={newGrupoId}
                                onChange={(e) => setNewGrupoId(e.target.value)}
                                style={styles.select}
                            >
                                {grupos.map(grupo => (
                                    <option key={grupo.id} value={grupo.id}>{grupo.nombre}</option>
                                ))}
                            </select>
                        </div>

                        <div style={styles.warning}>
                            ⚠️ <strong>Importante:</strong> Esto afectará los filtros de maestros y compañeros para nuevos proyectos. Los proyectos existentes NO se verán afectados.
                        </div>

                        <div style={styles.modalActions}>
                            <button
                                onClick={() => setShowModal(false)}
                                style={styles.cancelButton}
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={handleChangeGroup}
                                style={styles.submitButton}
                                disabled={newGrupoId === selectedStudent.grupoId}
                            >
                                Confirmar Cambio
                            </button>
                        </div>
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
    editButton: {
        padding: '0.5rem',
        backgroundColor: '#f3f4f6',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        color: '#3b82f6',
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
    studentInfo: {
        backgroundColor: '#f9fafb',
        padding: '1rem',
        borderRadius: '8px',
        marginBottom: '1.5rem'
    },
    formGroup: {
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem',
        marginBottom: '1rem'
    },
    label: {
        fontSize: '0.875rem',
        fontWeight: '500',
        color: '#374151'
    },
    select: {
        padding: '0.75rem',
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '1rem',
        backgroundColor: 'white'
    },
    warning: {
        padding: '1rem',
        backgroundColor: '#fef3c7',
        border: '1px solid #fbbf24',
        borderRadius: '8px',
        fontSize: '0.875rem',
        color: '#92400e',
        marginBottom: '1.5rem'
    },
    modalActions: {
        display: 'flex',
        gap: '1rem',
        justifyContent: 'flex-end'
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
