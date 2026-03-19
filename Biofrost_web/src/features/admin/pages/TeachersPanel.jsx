import { useState, useEffect } from 'react';
import { Pencil, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api from '../../../lib/axios';
import AsignacionSelector from '../components/AsignacionSelector';

export default function TeachersPanel() {
    const navigate = useNavigate();
    const [teachers, setTeachers] = useState([]);
    const [materias, setMaterias] = useState([]);
    const [grupos, setGrupos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [selectedTeacher, setSelectedTeacher] = useState(null);
    const [asignaciones, setAsignaciones] = useState([]);

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            setLoading(true);
            const [teachersRes, materiasRes, gruposRes] = await Promise.all([
                api.get('/api/admin/users/teachers'),
                api.get('/api/admin/materias'),
                api.get('/api/admin/groups')
            ]);
            setTeachers(teachersRes.data);
            setMaterias(materiasRes.data);
            setGrupos(gruposRes.data);
        } catch (err) {
            setError('Error al cargar datos');
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateAssignments = async () => {
        if (!selectedTeacher) return;

        try {
            await api.put(`/api/admin/users/teachers/${selectedTeacher.id}`, {
                asignaciones
            });
            setShowModal(false);
            setSelectedTeacher(null);
            fetchData();
        } catch (err) {
            setError('Error al actualizar asignaciones');
            console.error(err);
        }
    };

    const openEditModal = (teacher) => {
        setSelectedTeacher(teacher);
        setAsignaciones(teacher.asignaciones || []);
        setShowModal(true);
    };

    const getMateriaNombre = (id) => materias.find(m => m.id === id)?.nombre || id || 'Sin Materia';
    const getGrupoNombre = (id) => grupos.find(g => g.id === id)?.nombre || id;

    const formatAsignaciones = (asignaciones) => {
        if (!asignaciones || asignaciones.length === 0) {
            return <span style={{ color: '#9ca3af', fontStyle: 'italic' }}>Sin asignaciones</span>;
        }

        return (
            <div style={styles.asignacionesList}>
                {asignaciones.map((asig, idx) => (
                    <div key={idx} style={styles.asignacionBadge}>
                        {getMateriaNombre(asig.materiaId)} → {asig.gruposIds.map(gid => getGrupoNombre(gid)).join(', ')}
                    </div>
                ))}
            </div>
        );
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
                    <h1 style={styles.title}>Gestión de Docentes</h1>
                </div>
            </div>

            {error && <div style={styles.error}>{error}</div>}

            {/* Tabla de docentes */}
            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Nombre</th>
                            <th style={styles.th}>Email</th>
                            <th style={styles.th}>Profesión</th>
                            <th style={styles.th}>Asignaturas</th>
                            <th style={styles.th}>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        {teachers.length === 0 ? (
                            <tr>
                                <td colSpan="5" style={styles.emptyMessage}>
                                    No hay docentes registrados
                                </td>
                            </tr>
                        ) : (
                            teachers.map(teacher => (
                                <tr key={teacher.id} style={styles.tr}>
                                    <td style={styles.td}>{teacher.nombre}</td>
                                    <td style={styles.td}>{teacher.email}</td>
                                    <td style={styles.td}>{teacher.profesion}</td>
                                    <td style={styles.td}>{formatAsignaciones(teacher.asignaciones)}</td>
                                    <td style={styles.td}>
                                        <button
                                            onClick={() => openEditModal(teacher)}
                                            style={styles.editButton}
                                            title="Editar Asignaciones"
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

            {/* Modal para editar asignaciones */}
            {showModal && selectedTeacher && (
                <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                    <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
                        <h2 style={styles.modalTitle}>Editar Asignaciones</h2>

                        <div style={styles.teacherInfo}>
                            <p><strong>Docente:</strong> {selectedTeacher.nombre}</p>
                            <p><strong>Email:</strong> {selectedTeacher.email}</p>
                            <p><strong>Profesión:</strong> {selectedTeacher.profesion}</p>
                        </div>

                        <AsignacionSelector
                            asignaciones={asignaciones}
                            onChange={setAsignaciones}
                        />

                        <div style={styles.modalActions}>
                            <button
                                onClick={() => setShowModal(false)}
                                style={styles.cancelButton}
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={handleUpdateAssignments}
                                style={styles.submitButton}
                            >
                                Guardar Cambios
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
    asignacionesList: {
        display: 'flex',
        flexDirection: 'column',
        gap: '0.25rem'
    },
    asignacionBadge: {
        fontSize: '0.875rem',
        color: '#1f2937',
        padding: '0.25rem 0'
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
        maxWidth: '700px',
        maxHeight: '90vh',
        overflow: 'auto'
    },
    modalTitle: {
        fontSize: '1.5rem',
        fontWeight: 'bold',
        color: '#1a1a1a',
        marginBottom: '1.5rem'
    },
    teacherInfo: {
        backgroundColor: '#f9fafb',
        padding: '1rem',
        borderRadius: '8px',
        marginBottom: '1.5rem'
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
