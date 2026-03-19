import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, LayoutGrid, Search } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import api from '../../../lib/axios';

// Components
import { CreateProjectForm } from '../../projects/components/CreateProjectForm';
import { ProjectCard } from '../../projects/components/ProjectCard';
import { ProjectDetailsModal } from '../../projects/components/ProjectDetailsModal';
import { StudentDashboard } from '../components/StudentDashboard';
import { TeacherDashboard } from '../components/TeacherDashboard';
import { GuestDashboard } from '../components/GuestDashboard';

export function DashboardPage() {
    const { userData } = useAuth();
    const [projects, setProjects] = useState([]);
    const [groupName, setGroupName] = useState(null);
    const [loading, setLoading] = useState(true);
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [selectedProject, setSelectedProject] = useState(null);
    const [searchQuery, setSearchQuery] = useState('');

    // Animation Variants
    const containerVariants = {
        hidden: { opacity: 0 },
        visible: {
            opacity: 1,
            transition: {
                staggerChildren: 0.1
            }
        }
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { type: "spring", stiffness: 300, damping: 24 }
        }
    };

    const [suggestedStudents, setSuggestedStudents] = useState([]);

    useEffect(() => {
        if (userData?.rol === 'admin' || userData?.rol === 'SuperAdmin') window.location.href = '/admin';
        if (userData) {
            Promise.all([
                fetchProjects(),
                userData.grupoId ? fetchGroupDetails() : Promise.resolve(),
                userData.rol === 'Alumno' ? fetchSuggestions() : Promise.resolve()
            ]);
        } else {
            setLoading(false);
        }
    }, [userData]);

    // Normalize keys from PascalCase (C# backend) to camelCase
    const normalizePascal = (obj) => {
        if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return obj;
        const newObj = {};
        Object.entries(obj).forEach(([key, value]) => {
            const camelKey = key.charAt(0).toLowerCase() + key.slice(1);
            newObj[camelKey] = value;
        });
        return newObj;
    };

    const fetchGroupDetails = async () => {
        try {
            const response = await api.get(`/api/admin/groups/${userData.grupoId}`);
            setGroupName(response.data.nombre);
        } catch (error) { console.error('Error fetching group:', error); }
    };

    const fetchProjects = async () => {
        try {
            let projectsData = [];

            if (userData?.rol === 'Alumno') {
                try {
                    const response = await api.get(`/api/projects/my-project?userId=${userData.userId}`);
                    if (response.data) {
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

                        const textBlock = rawCanvas.find(b => (b.type === 'text' || b.Type === 'text') && (b.content || b.Content)?.trim());
                        let extractedDescription = 'Sin descripción disponible. Navega a los detalles para ver más.';
                        if (textBlock && (textBlock.content || textBlock.Content)) {
                            extractedDescription = (textBlock.content || textBlock.Content)
                                .replace(/<[^>]+>/g, '')
                                .replace(/&nbsp;/g, ' ')
                                .trim();
                        }
                        const imageBlock = rawCanvas.find(b => (b.type === 'image' || b.Type === 'image') && (b.content || b.Content));

                        const normalized = {
                            ...rawProject,
                            liderNombre: liderObj.nombre || 'Desconocido',
                            liderFotoUrl: liderObj.fotoUrl || null,
                            thumbnailUrl: rawProject.thumbnailUrl || (imageBlock ? (imageBlock.content || imageBlock.Content) : null),
                            canvas: rawCanvas.map(normalize),
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
            } else if (userData?.rol === 'Docente') {
                const response = await api.get(`/api/projects/teacher/${userData.userId}`);
                // Normalize PascalCase keys from backend to camelCase for ShowcaseCard
                projectsData = (response.data || []).map(p => ({
                    ...normalizePascal(p),
                    // Ensure canvas is normalized too (if present)
                    canvas: (p.CanvasBlocks || p.canvasBlocks || []).map(b => normalizePascal(b)),
                }));
            } else if (userData?.grupoId) {
                const response = await api.get(`/api/projects/group/${userData.grupoId}`);
                // Normalize PascalCase keys from backend to camelCase for ShowcaseCard
                projectsData = (response.data || []).map(p => ({
                    ...normalizePascal(p),
                    canvas: (p.CanvasBlocks || p.canvasBlocks || []).map(b => normalizePascal(b)),
                }));
            }

            setProjects(projectsData || []);
        } catch (error) {
            console.error('Error fetching projects:', error);
            setProjects([]);
        }
        finally { setLoading(false); }
    };

    const fetchSuggestions = async () => {
        if (userData?.rol !== 'Alumno') return;
        try {
            // Reusing the endpoint from TeamPage
            const response = await api.get(`/api/teams/available-students?groupId=${userData.grupoId}`);
            // Randomize or take first 4 excluding self is handled by backend usually or we filter here
            setSuggestedStudents(response.data.filter(s => s.id !== userData.userId).slice(0, 4));
        } catch (error) { console.error('Error fetching suggestions:', error); }
    };

    const filteredProjects = projects.filter(p =>
        (p.titulo?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
        (p.liderNombre?.toLowerCase() || '').includes(searchQuery.toLowerCase())
    );

    return (
        <div className="h-full">
            <main className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* Header Section */}
                <div className="mb-10">
                    <h1 className="text-3xl font-bold text-gray-900 dark:text-white tracking-tight mb-2">
                        Dashboard
                    </h1>
                    <p className="text-gray-600 dark:text-slate-400 text-base max-w-2xl">
                        Gestión integral de proyectos integradores.
                    </p>
                </div>

                {loading ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="h-64 bg-gray-100 dark:bg-slate-800 rounded-xl animate-pulse" />
                        ))}
                    </div>
                ) : userData?.rol === 'Alumno' ? (
                    <StudentDashboard
                        userData={userData}
                        project={projects[0]}
                        suggestedStudents={suggestedStudents}
                        onShowCreateModal={() => setShowCreateModal(true)}
                        onProjectClick={() => setSelectedProject(projects[0])}
                    />
                ) : userData?.rol === 'Docente' ? (
                    <TeacherDashboard
                        userData={userData}
                        projects={projects}
                        groupName={groupName}
                        searchQuery={searchQuery}
                        onProjectClick={(project) => setSelectedProject(project)}
                    />
                ) : (
                    <GuestDashboard userData={userData} />
                )}
            </main>

            {/* Modals */}
            <AnimatePresence>
                {showCreateModal && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
                        onClick={() => setShowCreateModal(false)}
                    >
                        <motion.div
                            initial={{ scale: 0.95, opacity: 0, y: 10 }}
                            animate={{ scale: 1, opacity: 1, y: 0 }}
                            exit={{ scale: 0.95, opacity: 0, y: 10 }}
                            onClick={e => e.stopPropagation()}
                            className="bg-white dark:bg-[#1a1d27] w-full max-w-2xl rounded-xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col"
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
                        className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
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
