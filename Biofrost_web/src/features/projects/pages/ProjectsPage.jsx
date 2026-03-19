import { useState, useEffect, useCallback } from 'react';
import { LayoutGrid, Plus, Search } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../../auth/hooks/useAuth';
import api from '../../../lib/axios';
import { ProjectCard } from '../components/ProjectCard';
import { ShowcaseCard } from '../../public/components/ShowcaseCard';
import { CreateProjectForm } from '../components/CreateProjectForm';
import { ProjectDetailsModal } from '../components/ProjectDetailsModal';
import { UserAvatar } from '../../../components/UserAvatar';
import { Link } from 'react-router-dom';
import { User, Mail, GraduationCap } from 'lucide-react';

export function ProjectsPage() {
    const { userData } = useAuth();
    const [projects, setProjects] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [selectedProject, setSelectedProject] = useState(null);

    const fetchProjects = useCallback(async () => {
        try {
            let projectsData = [];

            if (userData?.rol === 'Alumno') {
                // Alumno solo ve su proyecto activo
                try {
                    const response = await api.get(`/api/projects/my-project?userId=${userData.userId}`);
                    if (response.data) {
                        // Helper para normalizar propiedades PascalCase a camelCase
                        const normalize = (obj) => {
                            if (!obj) return null;
                            const newObj = {};
                            Object.entries(obj).forEach(([key, value]) => {
                                newObj[key.charAt(0).toLowerCase() + key.slice(1)] = value;
                            });
                            return newObj;
                        };

                        const rawProject = normalize(response.data);
                        const rawMembers = (rawProject.members || rawProject.miembros || []).map(normalize);
                        const rawCanvas = rawProject.canvasBlocks || rawProject.canvas || [];

                        const liderObj = rawMembers.find(m => m.id === rawProject.liderId) || {};

                        // Extraer texto y thumb igual que en endpoints públicos (manejando posible PascalCase en CanvasBlocks)
                        const textBlock = rawCanvas.find(b => (b.type === 'text' || b.Type === 'text') && (b.content || b.Content)?.trim());
                        let extractedDescription = 'Sin descripción disponible. Navega a los detalles para ver más.';
                        if (textBlock && (textBlock.content || textBlock.Content)) {
                            extractedDescription = (textBlock.content || textBlock.Content)
                                .replace(/<[^>]+>/g, '') // remove HTML tags
                                .replace(/&nbsp;/g, ' ')
                                .trim();
                        }
                        const imageBlock = rawCanvas.find(b => (b.type === 'image' || b.Type === 'image') && (b.content || b.Content));

                        const normalized = {
                            ...rawProject,
                            liderNombre: liderObj.nombre || 'Desconocido',
                            liderFotoUrl: liderObj.fotoUrl || null,
                            thumbnailUrl: rawProject.thumbnailUrl || (imageBlock ? (imageBlock.content || imageBlock.Content) : null),
                            canvas: rawCanvas.map(normalize), // normalizar los bloques también por si Showcase los itera por .content 
                            descripcion: extractedDescription,
                            miembros: rawMembers,
                            puntosTotales: rawProject.puntosTotales || 0,
                            calificacion: rawProject.calificacion || null
                        };
                        projectsData = [normalized];
                    }
                } catch (e) {
                    if (e.response?.status !== 404) console.error('Error fetching my project:', e);
                    projectsData = [];
                }
            } else {
                // Admin/Docente ve todo el grupo
                const response = await api.get(`/api/projects/group/${userData.grupoId}`);
                projectsData = response.data;
            }

            setProjects(projectsData);
        } catch (error) {
            console.error('Error fetching projects:', error);
            setProjects([]);
        } finally {
            setLoading(false);
        }
    }, [userData]);

    useEffect(() => {
        if (userData?.grupoId) {
            fetchProjects();
        }
    }, [userData, fetchProjects]);

    const filteredProjects = projects.filter(p =>
        (p.titulo || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
        (p.liderNombre || '').toLowerCase().includes(searchQuery.toLowerCase())
    );

    const isAlumno = userData?.rol === 'Alumno';
    const alumnoProject = isAlumno && projects.length > 0 ? projects[0] : null;

    return (
        <div className="h-full">
            <main className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* Header Section */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-10">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900 dark:text-white tracking-tight mb-2">Mis Proyectos</h1>
                        <p className="text-gray-600 dark:text-slate-400 text-base max-w-2xl">Administra y colabora en tus proyectos.</p>
                    </div>
                    {isAlumno && !alumnoProject && !loading && (
                        <button
                            onClick={() => setShowCreateModal(true)}
                            className="bg-gray-900 text-white px-4 py-2.5 rounded-lg text-sm font-semibold flex items-center gap-2 shadow-sm hover:bg-gray-800 active:bg-gray-950 transition-all"
                        >
                            <Plus size={16} />
                            Nuevo Proyecto
                        </button>
                    )}
                </div>

                {/* Content */}
                <div className="flex-1 overflow-y-auto min-h-0">
                    {/* Search - Solo para Docente/Admin */}
                    {!isAlumno && (
                        <div className="bg-white dark:bg-[#1a1d27] p-4 rounded-lg border border-gray-200 dark:border-slate-700/50 shadow-sm mb-6">
                            <div className="relative">
                                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                <input
                                    type="text"
                                    placeholder="Buscar proyectos..."
                                    value={searchQuery}
                                    onChange={(e) => setSearchQuery(e.target.value)}
                                    className="w-full pl-10 pr-4 py-2.5 bg-gray-50 dark:bg-slate-800 dark:text-white border-0 rounded-lg focus:ring-2 focus:ring-gray-200 dark:focus:ring-slate-600 focus:bg-white dark:focus:bg-slate-700 outline-none transition-all placeholder:text-gray-400 dark:placeholder:text-slate-500"
                                />
                            </div>
                        </div>
                    )}

                    {loading ? (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                            {[1, 2, 3].map(i => (
                                <div key={i} className="h-64 bg-gray-100 dark:bg-slate-800 rounded-2xl animate-pulse" />
                            ))}
                        </div>
                    ) : isAlumno ? (
                        /* VISTA ALUMNO */
                        alumnoProject ? (
                            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 pb-6">
                                {/* Proyecto Principal (Hero) */}
                                <div className="lg:col-span-2 flex flex-col">
                                    <motion.div
                                        layoutId={alumnoProject.id}
                                        initial={{ opacity: 0, scale: 0.95 }}
                                        animate={{ opacity: 1, scale: 1 }}
                                        transition={{ duration: 0.3 }}
                                        className="h-full"
                                    >
                                        <ShowcaseCard
                                            project={{ ...alumnoProject, coverUrl: alumnoProject.videoUrl || alumnoProject.thumbnailUrl || null }}
                                            onClick={() => setSelectedProject(alumnoProject)}
                                        />
                                    </motion.div>
                                </div>

                                {/* Sidebar: Perfil y Equipo */}
                                <div className="lg:col-span-1 flex flex-col gap-6">
                                    {/* Mini Perfil */}
                                    <motion.div
                                        initial={{ opacity: 0, x: 20 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        transition={{ duration: 0.3, delay: 0.1 }}
                                        className="bg-white dark:bg-[#1a1d27] rounded-2xl border border-gray-200 dark:border-slate-700/50 p-6 shadow-sm flex flex-col items-center text-center"
                                    >
                                        <UserAvatar
                                            src={userData?.fotoUrl}
                                            name={userData?.nombre}
                                            size="xl"
                                            className="mb-4 ring-4 ring-gray-100"
                                        />
                                        <h3 className="text-xl font-bold text-gray-900 dark:text-white mt-3">{userData?.nombre}</h3>
                                        <p className="text-sm text-gray-500 dark:text-slate-400 mb-6">{userData?.carrera || 'Alumno'}</p>

                                        <div className="w-full space-y-3 mb-8">
                                            <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-slate-300 bg-gray-50 dark:bg-slate-800 p-3 rounded-lg border border-gray-100 dark:border-slate-700 text-left">
                                                <Mail size={16} className="text-gray-400 shrink-0" />
                                                <span className="truncate">{userData?.email}</span>
                                            </div>
                                            <div className="flex items-center gap-3 text-sm text-gray-600 dark:text-slate-300 bg-gray-50 dark:bg-slate-800 p-3 rounded-lg border border-gray-100 dark:border-slate-700 text-left">
                                                <GraduationCap size={16} className="text-gray-400 shrink-0" />
                                                <span className="truncate">Matrícula: {userData?.matricula || 'N/D'}</span>
                                            </div>
                                        </div>

                                        <Link
                                            to="/profile"
                                            className="w-full py-2.5 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-600 text-gray-700 dark:text-slate-200 font-semibold rounded-xl shadow-sm hover:bg-gray-50 dark:hover:bg-slate-700 hover:border-gray-300 transition-all text-sm mt-auto"
                                        >
                                            Ver Perfil Completo
                                        </Link>
                                    </motion.div>

                                    {/* Equipo */}
                                    <motion.div
                                        initial={{ opacity: 0, x: 20 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        transition={{ duration: 0.3, delay: 0.2 }}
                                        className="bg-white dark:bg-[#1a1d27] rounded-2xl border border-gray-200 dark:border-slate-700/50 p-6 shadow-sm flex-1"
                                    >
                                        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-5 flex items-center gap-2">
                                            <User size={20} className="text-blue-500" />
                                            Mi Equipo
                                        </h3>
                                        <div className="space-y-4">
                                            {(alumnoProject.miembros || []).map(member => (
                                                <div key={member.id} className="flex items-center gap-3 p-3 rounded-xl hover:bg-gray-50 dark:hover:bg-slate-700/50 border border-transparent hover:border-gray-100 dark:hover:border-slate-600 transition-all">
                                                    <Link to={`/profile/${member.id}`} className="shrink-0 rounded-full hover:ring-2 hover:ring-blue-500 transition-all" title="Ver perfil">
                                                        <UserAvatar src={member.fotoUrl} name={(member.nombre && member.nombre !== 'Usuario') ? member.nombre : member.email} size="md" className="ring-2 ring-white shadow-sm" />
                                                    </Link>
                                                    <div className="flex-1 min-w-0 text-left">
                                                        <Link to={`/profile/${member.id}`} className="hover:text-blue-600 transition-colors">
                                                            <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                                                                {(member.nombre && member.nombre !== 'Usuario') ? member.nombre : (member.email || 'Miembro')}
                                                                {member.id === userData.userId && " (Tú)"}
                                                            </p>
                                                        </Link>
                                                        <p className="text-xs text-blue-600 font-medium inline-block bg-blue-50 px-2 py-0.5 rounded-full mt-1">
                                                            {member.rol || 'Miembro'}
                                                        </p>
                                                    </div>
                                                </div>
                                            ))}
                                            {(!alumnoProject.miembros || alumnoProject.miembros.length === 0) && (
                                                <p className="text-sm text-gray-500 dark:text-slate-400 text-center py-6 bg-gray-50 dark:bg-slate-800 rounded-xl border border-dashed border-gray-200 dark:border-slate-600">
                                                    No hay otros miembros en el equipo aún.
                                                </p>
                                            )}
                                        </div>
                                    </motion.div>
                                </div>
                            </div>
                        ) : (
                            // Empty State Alumno
                            <div className="h-full flex flex-col items-center justify-center text-center p-8 bg-white dark:bg-[#1a1d27] rounded-3xl border border-gray-200 dark:border-slate-700/50 shadow-sm max-w-2xl mx-auto my-10 relative overflow-hidden">
                                <div className="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 rounded-full bg-blue-50 dark:bg-blue-900/10 blur-3xl pointer-events-none"></div>

                                <div className="relative z-10 flex flex-col items-center">
                                    <div className="w-24 h-24 bg-blue-50 dark:bg-blue-900/20 text-blue-600 rounded-full flex items-center justify-center mb-8 shadow-sm border border-blue-100 dark:border-blue-800">
                                        <LayoutGrid size={40} />
                                    </div>
                                    <h3 className="text-3xl font-bold text-gray-900 dark:text-white mb-3 tracking-tight">Aún no tienes un proyecto</h3>
                                    <p className="text-gray-500 dark:text-slate-400 mb-10 max-w-md text-lg leading-relaxed">
                                        El proyecto integrador es tu oportunidad para brillar. Agrega a tu equipo, documenta tu progreso y logra una calificación de excelencia.
                                    </p>
                                    <button
                                        onClick={() => setShowCreateModal(true)}
                                        className="bg-gray-900 dark:bg-white dark:text-black text-white px-8 py-4 rounded-xl font-semibold flex items-center gap-2 shadow-md hover:shadow-xl hover:-translate-y-1 hover:bg-gray-800 dark:hover:bg-gray-100 active:bg-gray-950 transition-all text-lg group"
                                    >
                                        <Plus size={24} className="group-hover:rotate-90 transition-transform" />
                                        Empezar mi Proyecto
                                    </button>
                                </div>
                            </div>
                        )
                    ) : (
                        // VISTA DOCENTE / ADMIN (Listado normal)
                        filteredProjects.length > 0 ? (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 pb-6">
                                {filteredProjects.map(project => (
                                    <motion.div
                                        key={project.id}
                                        layoutId={project.id}
                                        initial={{ opacity: 0, scale: 0.9 }}
                                        animate={{ opacity: 1, scale: 1 }}
                                        transition={{ duration: 0.2 }}
                                        className="h-full"
                                    >
                                        <ProjectCard
                                            project={project}
                                            onClick={() => setSelectedProject(project)}
                                        />
                                    </motion.div>
                                ))}
                            </div>
                        ) : (
                            <div className="h-full flex flex-col items-center justify-center text-center p-12 bg-white dark:bg-[#1a1d27] rounded-3xl border border-dashed border-gray-300 dark:border-slate-600">
                                <div className="w-16 h-16 bg-blue-50 dark:bg-blue-900/30 text-blue-500 rounded-full flex items-center justify-center mb-4">
                                    <Search size={24} />
                                </div>
                                <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-1">No se encontraron proyectos</h3>
                                <p className="text-gray-500 dark:text-slate-400">
                                    Intenta con otros términos en tu búsqueda.
                                </p>
                            </div>
                        )
                    )}
                </div>
            </main>

            {/* Modals */}
            <AnimatePresence>
                {showCreateModal && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="fixed inset-0 bg-gray-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4"
                        onClick={() => setShowCreateModal(false)}
                    >
                        <motion.div
                            initial={{ scale: 0.95, opacity: 0, y: 10 }}
                            animate={{ scale: 1, opacity: 1, y: 0 }}
                            exit={{ scale: 0.95, opacity: 0, y: 10 }}
                            onClick={e => e.stopPropagation()}
                            className="bg-white dark:bg-[#1a1d27] w-full max-w-lg rounded-2xl shadow-2xl border border-gray-100 dark:border-slate-700/50 overflow-hidden max-h-[85vh] flex flex-col"
                        >
                            <CreateProjectForm
                                onClose={() => setShowCreateModal(false)}
                                onSuccess={() => {
                                    setShowCreateModal(false);
                                    fetchProjects();
                                }}
                            />
                        </motion.div>
                    </motion.div>
                )}

                {selectedProject && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="fixed inset-0 bg-gray-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4"
                        onClick={() => setSelectedProject(null)}
                    >
                        <motion.div
                            initial={{ scale: 0.95, opacity: 0, y: 10 }}
                            animate={{ scale: 1, opacity: 1, y: 0 }}
                            exit={{ scale: 0.95, opacity: 0, y: 10 }}
                            onClick={e => e.stopPropagation()}
                            className="bg-black dark:bg-black w-[95vw] md:w-[95vw] lg:w-[95vw] xl:w-[95vw] 2xl:w-[95vw] max-w-none rounded-2xl shadow-2xl border border-gray-100 dark:border-slate-700/50 overflow-hidden h-[95vh] flex flex-col"
                        >
                            <ProjectDetailsModal
                                project={selectedProject}
                                onClose={() => setSelectedProject(null)}
                                onUpdate={fetchProjects}
                            />
                        </motion.div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}
