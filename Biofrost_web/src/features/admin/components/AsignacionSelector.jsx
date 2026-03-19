import { useState, useEffect } from 'react';
import { Plus, X } from 'lucide-react';
import api from '../../../lib/axios';

export default function AsignacionSelector({ asignaciones, onChange }) {
    const [carreras, setCarreras] = useState([]);
    const [materias, setMaterias] = useState([]);
    const [grupos, setGrupos] = useState([]);

    useEffect(() => {
        fetchCatalogos();
    }, []);

    const fetchCatalogos = async () => {
        try {
            const [carrerasRes, materiasRes, gruposRes] = await Promise.all([
                api.get('/api/admin/carreras'),
                api.get('/api/admin/materias'),
                api.get('/api/admin/groups')
            ]);
            setCarreras(carrerasRes.data);
            setMaterias(materiasRes.data);
            setGrupos(gruposRes.data);
        } catch (err) {
            console.error('Error al cargar catálogos:', err);
        }
    };

    const addAsignacion = () => {
        onChange([...asignaciones, {
            carreraId: '',
            materiaId: '',
            gruposIds: []
        }]);
    };

    const removeAsignacion = (index) => {
        onChange(asignaciones.filter((_, i) => i !== index));
    };

    const updateAsignacion = (index, field, value) => {
        const updated = [...asignaciones];
        updated[index] = { ...updated[index], [field]: value };

        // Si cambia la carrera, resetear materia
        if (field === 'carreraId') {
            updated[index].materiaId = '';
        }

        onChange(updated);
    };

    const toggleGrupo = (index, grupoId) => {
        const updated = [...asignaciones];
        const gruposIds = updated[index].gruposIds || [];

        if (gruposIds.includes(grupoId)) {
            updated[index].gruposIds = gruposIds.filter(id => id !== grupoId);
        } else {
            updated[index].gruposIds = [...gruposIds, grupoId];
        }

        onChange(updated);
    };

    const getMateriasByCarrera = (carreraId) => {
        return materias.filter(m => m.carreraId === carreraId);
    };

    const getCarreraNombre = (carreraId) => {
        return carreras.find(c => c.id === carreraId)?.nombre || carreraId;
    };

    const getMateriaNombre = (materiaId) => {
        return materias.find(m => m.id === materiaId)?.nombre || materiaId;
    };

    return (
        <div style={styles.container}>
            <div style={styles.header}>
                <h3 style={styles.title}>Asignaturas</h3>
                <button onClick={addAsignacion} style={styles.addButton}>
                    <Plus size={16} />
                    Agregar Asignatura
                </button>
            </div>

            {asignaciones.length === 0 ? (
                <div style={styles.emptyMessage}>
                    No hay asignaturas. Haz clic en "Agregar Asignatura" para comenzar.
                </div>
            ) : (
                <div style={styles.asignacionesList}>
                    {asignaciones.map((asignacion, index) => (
                        <div key={index} style={styles.asignacionCard}>
                            <div style={styles.cardHeader}>
                                <span style={styles.cardNumber}>Asignatura {index + 1}</span>
                                <button
                                    onClick={() => removeAsignacion(index)}
                                    style={styles.removeButton}
                                    title="Eliminar asignación"
                                >
                                    <X size={16} />
                                </button>
                            </div>

                            {/* Carrera */}
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Carrera *</label>
                                <select
                                    value={asignacion.carreraId}
                                    onChange={(e) => updateAsignacion(index, 'carreraId', e.target.value)}
                                    style={styles.select}
                                >
                                    <option value="">Seleccionar carrera</option>
                                    {carreras.map(carrera => (
                                        <option key={carrera.id} value={carrera.id}>
                                            {carrera.nombre}
                                        </option>
                                    ))}
                                </select>
                            </div>

                            {/* Materia */}
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Asignatura *</label>
                                <select
                                    value={asignacion.materiaId}
                                    onChange={(e) => updateAsignacion(index, 'materiaId', e.target.value)}
                                    style={styles.select}
                                    disabled={!asignacion.carreraId}
                                >
                                    <option value="">Seleccionar asignatura</option>
                                    {getMateriasByCarrera(asignacion.carreraId).map(materia => (
                                        <option key={materia.id} value={materia.id}>
                                            {materia.nombre}
                                        </option>
                                    ))}
                                </select>
                            </div>

                            {/* Grupos */}
                            <div style={styles.formGroup}>
                                <label style={styles.label}>Grupos *</label>
                                <div style={styles.gruposGrid}>
                                    {grupos.map(grupo => (
                                        <label key={grupo.id} style={styles.checkboxLabel}>
                                            <input
                                                type="checkbox"
                                                checked={asignacion.gruposIds?.includes(grupo.id) || false}
                                                onChange={() => toggleGrupo(index, grupo.id)}
                                                style={styles.checkbox}
                                            />
                                            <span>{grupo.nombre}</span>
                                        </label>
                                    ))}
                                </div>
                            </div>

                            {/* Resumen */}
                            {asignacion.carreraId && asignacion.materiaId && asignacion.gruposIds?.length > 0 && (
                                <div style={styles.summary}>
                                    <strong>Resumen:</strong> {getMateriaNombre(asignacion.materiaId)} en {getCarreraNombre(asignacion.carreraId)} → Grupos: {asignacion.gruposIds.join(', ')}
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

const styles = {
    container: {
        marginBottom: '1.5rem'
    },
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '1rem'
    },
    title: {
        fontSize: '1.125rem',
        fontWeight: '600',
        color: '#1f2937'
    },
    addButton: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        padding: '0.5rem 1rem',
        backgroundColor: '#3b82f6',
        color: 'white',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        fontSize: '0.875rem',
        fontWeight: '500'
    },
    emptyMessage: {
        textAlign: 'center',
        padding: '2rem',
        color: '#9ca3af',
        fontStyle: 'italic',
        backgroundColor: '#f9fafb',
        borderRadius: '8px'
    },
    asignacionesList: {
        display: 'flex',
        flexDirection: 'column',
        gap: '1rem'
    },
    asignacionCard: {
        padding: '1.5rem',
        backgroundColor: '#f9fafb',
        borderRadius: '8px',
        border: '1px solid #e5e7eb'
    },
    cardHeader: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '1rem'
    },
    cardNumber: {
        fontSize: '0.875rem',
        fontWeight: '600',
        color: '#6b7280'
    },
    removeButton: {
        padding: '0.25rem',
        backgroundColor: 'transparent',
        border: 'none',
        cursor: 'pointer',
        color: '#ef4444',
        borderRadius: '4px'
    },
    formGroup: {
        marginBottom: '1rem'
    },
    label: {
        display: 'block',
        fontSize: '0.875rem',
        fontWeight: '500',
        color: '#374151',
        marginBottom: '0.5rem'
    },
    select: {
        width: '100%',
        padding: '0.75rem',
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '1rem',
        backgroundColor: 'white'
    },
    gruposGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(120px, 1fr))',
        gap: '0.75rem'
    },
    checkboxLabel: {
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        cursor: 'pointer',
        fontSize: '0.875rem',
        color: '#374151'
    },
    checkbox: {
        width: '16px',
        height: '16px',
        cursor: 'pointer'
    },
    summary: {
        marginTop: '1rem',
        padding: '0.75rem',
        backgroundColor: '#dbeafe',
        borderRadius: '6px',
        fontSize: '0.875rem',
        color: '#1e40af'
    }
};
