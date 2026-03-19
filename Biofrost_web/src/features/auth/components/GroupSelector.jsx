import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../../lib/axios';

export function GroupSelector({ userData, onComplete }) {
    const [groups, setGroups] = useState([]);
    const [selectedGroup, setSelectedGroup] = useState('');
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        fetchGroups();
    }, []);

    const fetchGroups = async () => {
        try {
            const response = await api.get('/api/groups');
            setGroups(response.data);
        } catch (error) {
            console.error('Error fetching groups:', error);
            // Mock data for development
            setGroups([
                { id: '5a', nombre: '5A', turno: 'Matutino' },
                { id: '5b', nombre: '5B', turno: 'Vespertino' },
                { id: '6a', nombre: '6A', turno: 'Matutino' },
                { id: '6b', nombre: '6B', turno: 'Vespertino' },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!selectedGroup) return;

        setSubmitting(true);
        try {
            await api.put(`/api/users/${userData.userId}/group`, {
                grupoId: selectedGroup
            });
            onComplete?.();
            navigate('/dashboard');
        } catch (error) {
            console.error('Error updating group:', error);
        } finally {
            setSubmitting(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
            </div>
        );
    }

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
            <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full">
                <div className="text-center mb-8">
                    <h1 className="text-2xl font-bold text-gray-800">¡Bienvenido!</h1>
                    <p className="text-gray-600 mt-2">
                        {userData?.rol === 'Alumno'
                            ? 'Selecciona tu grupo para continuar'
                            : 'Selecciona los grupos que impartes'}
                    </p>
                    {userData?.matricula && (
                        <div className="mt-4 inline-flex items-center px-3 py-1 rounded-full bg-blue-100 text-blue-800 text-sm font-medium">
                            Matrícula: {userData.matricula}
                        </div>
                    )}
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-3">
                            {userData?.rol === 'Alumno' ? 'Tu grupo' : 'Grupos asignados'}
                        </label>
                        <div className="grid grid-cols-2 gap-3">
                            {groups.map((group) => (
                                <button
                                    key={group.id}
                                    type="button"
                                    onClick={() => setSelectedGroup(group.id)}
                                    className={`p-4 rounded-xl border-2 transition-all duration-200 ${selectedGroup === group.id
                                            ? 'border-blue-500 bg-blue-50 text-blue-700'
                                            : 'border-gray-200 hover:border-gray-300 text-gray-700'
                                        }`}
                                >
                                    <div className="text-lg font-bold">{group.nombre}</div>
                                    <div className="text-sm opacity-75">{group.turno}</div>
                                </button>
                            ))}
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={!selectedGroup || submitting}
                        className="w-full py-3 px-4 bg-blue-600 text-white font-medium rounded-xl hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {submitting ? 'Guardando...' : 'Continuar'}
                    </button>
                </form>
            </div>
        </div>
    );
}
