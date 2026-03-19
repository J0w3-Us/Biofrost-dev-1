import { useState, useEffect } from 'react';
import { useAuth } from '../../auth/hooks/useAuth';
import api from '../../../lib/axios';
import { EvaluationPanel } from '../components/EvaluationPanel';
import { BookOpen, Users, ChevronRight } from 'lucide-react';

export function EvaluationsPage() {
    const { userData } = useAuth();
    const [project, setProject] = useState(null);
    const [teacherProjects, setTeacherProjects] = useState([]);
    const [selectedProject, setSelectedProject] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!userData) return;
        if (userData.rol === 'Alumno') {
            fetchStudentProject();
        } else if (userData.rol === 'Docente') {
            fetchTeacherProjects();
        }
    }, [userData]);

    const fetchStudentProject = async () => {
        try {
            const { data } = await api.get(`/api/projects/my-project?userId=${userData.userId}`);
            setProject(data);
        } catch (error) {
            console.log("No project found for student");
        } finally {
            setLoading(false);
        }
    };

    const fetchTeacherProjects = async () => {
        try {
            const { data } = await api.get(`/api/projects/teacher/${userData.userId}`);
            const uniqueProjects = [...new Map(data.map(p => [p.id, p])).values()];
            setTeacherProjects(uniqueProjects);
        } catch (error) {
            console.error("Error fetching teacher projects", error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) return (
        <div className="p-8">
            <div className="animate-pulse h-32 bg-gray-100 dark:bg-slate-800 rounded-3xl" />
        </div>
    );

    // --- STUDENT VIEW ---
    if (userData?.rol === 'Alumno') {
        if (!project) {
            return (
                <div className="flex flex-col items-center justify-center h-full text-center p-8">
                    <div className="w-16 h-16 bg-blue-50 dark:bg-blue-900/30 text-blue-500 rounded-full flex items-center justify-center mb-4">
                        <BookOpen size={32} />
                    </div>
                    <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Sin Proyecto Asignado</h2>
                    <p className="text-gray-500 dark:text-slate-400 mt-2">Necesitas unirte a un proyecto para ver sus evaluaciones.</p>
                </div>
            );
        }
        return (
            <div className="max-w-4xl mx-auto p-6">
                <div className="mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Evaluaciones del Proyecto</h1>
                    <p className="text-gray-600 dark:text-slate-400 mt-1">Revisa las calificaciones y comentarios de tus profesores.</p>
                </div>
                <EvaluationPanel projectId={project.id} />
            </div>
        );
    }

    // --- TEACHER VIEW ---
    if (userData?.rol === 'Docente') {
        if (selectedProject) {
            return (
                <div className="h-full flex flex-col p-6 max-w-5xl mx-auto">
                    <button
                        onClick={() => setSelectedProject(null)}
                        className="self-start mb-6 text-sm font-bold text-gray-500 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white flex items-center gap-1 transition-colors"
                    >
                        ← Volver a la lista
                    </button>
                    <div className="mb-6">
                        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{selectedProject.titulo}</h1>
                        <span className="px-3 py-1 bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 rounded-full text-xs font-bold uppercase">
                            {selectedProject.materia}
                        </span>
                    </div>
                    <EvaluationPanel projectId={selectedProject.id} />
                </div>
            );
        }

        return (
            <div className="p-6 max-w-5xl mx-auto">
                <div className="mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Evaluaciones</h1>
                    <p className="text-gray-600 dark:text-slate-400 mt-1">Selecciona un proyecto para evaluar.</p>
                </div>

                {teacherProjects.length === 0 ? (
                    <div className="text-center py-12 bg-gray-50 dark:bg-slate-800/50 rounded-3xl border border-dashed border-gray-200 dark:border-slate-700">
                        <p className="text-gray-500 dark:text-slate-400">No hay proyectos disponibles en tus grupos asignados.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {teacherProjects.map(p => (
                            <div
                                key={p.id}
                                onClick={() => setSelectedProject(p)}
                                className="bg-white dark:bg-[#1a1d27] p-6 rounded-2xl border border-gray-100 dark:border-slate-700/50 shadow-sm hover:shadow-md dark:hover:border-slate-600 transition-all cursor-pointer group"
                            >
                                <div className="flex justify-between items-start mb-4">
                                    <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400">
                                        <BookOpen size={20} />
                                    </div>
                                    <ChevronRight className="text-gray-300 dark:text-slate-600 group-hover:text-blue-500 transition-colors" />
                                </div>
                                <h3 className="font-bold text-gray-900 dark:text-white mb-2 line-clamp-1">{p.titulo}</h3>
                                <p className="text-xs text-gray-500 dark:text-slate-400 font-bold uppercase mb-4">{p.materia}</p>
                                <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-slate-400">
                                    <Users size={16} />
                                    <span>{p.membersCount || 0} miembros</span>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        );
    }

    return null;
}
