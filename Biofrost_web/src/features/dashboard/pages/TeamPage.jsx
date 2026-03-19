import { useState, useEffect } from 'react';
import { Search, Mail, User, Plus, Users } from 'lucide-react';
import { motion } from 'framer-motion';
import { useAuth } from '../../auth/hooks/useAuth';
import { UserAvatar } from '../../../components/UserAvatar';
import api from '../../../lib/axios';
import { useNavigate, Link } from 'react-router-dom';

export function TeamPage() {
    const { userData } = useAuth();
    const navigate = useNavigate();
    const [students, setStudents] = useState([]);
    const [project, setProject] = useState(null);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');

    useEffect(() => {
        if (userData?.grupoId) {
            fetchData();
        }
    }, [userData]);

    const fetchData = async () => {
        setLoading(true);
        try {
            // 1. Fetch Classmates
            const studentsPromise = api.get(`/api/teams/available-students?groupId=${userData.grupoId}`);

            // 2. Fetch My Project (gracefully handle 404)
            const projectPromise = api.get(`/api/projects/my-project?userId=${userData.userId}`)
                .then(res => res.data)
                .catch(() => null);

            const [studentsRes, projectData] = await Promise.all([studentsPromise, projectPromise]);

            setStudents(studentsRes.data);

            // Normalize project data keys to lowercase to avoid case sensitivity issues
            if (projectData) {
                // Helper to normalize keys of an object
                const normalize = (obj) => {
                    if (!obj) return null;
                    const newObj = {};
                    Object.keys(obj).forEach(key => {
                        newObj[key.charAt(0).toLowerCase() + key.slice(1)] = obj[key];
                    });
                    return newObj;
                };

                const normalizedProject = normalize(projectData);
                // Also normalize members array if it exists as 'Members' or 'members'
                const rawMembers = projectData.Members || projectData.members || [];
                normalizedProject.members = rawMembers.map(normalize);

                setProject(normalizedProject);
            } else {
                setProject(null);
            }

        } catch (error) {
            console.error('Error fetching data:', error);
        } finally {
            setLoading(false);
        }
    };

    // Filter classmates: Remove current project members if project exists
    const availableStudents = students.filter(s => {
        // Remove if in my project
        if (project && project.miembrosIds?.includes(s.id)) return false;

        // Search filter
        return (
            s.nombreCompleto.toLowerCase().includes(searchQuery.toLowerCase()) ||
            s.matricula.toLowerCase().includes(searchQuery.toLowerCase())
        );
    });

    const containerVariants = {
        hidden: { opacity: 0 },
        visible: {
            opacity: 1,
            transition: { staggerChildren: 0.05 }
        }
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: { opacity: 1, y: 0 }
    };

    return (
        <div className="space-y-8 p-4 md:p-8 pb-24">

            {/* Header */}
            <div>
                <h1 className="text-3xl font-bold text-gray-900 dark:text-white tracking-tight">Mi Equipo</h1>
                <p className="text-gray-600 dark:text-slate-400">Gestiona tu equipo y encuentra compañeros.</p>
            </div>

            {/* MY TEAM SECTION */}
            <section className="shrink-0">
                <h2 className="text-xl font-bold text-gray-800 dark:text-white mb-4 flex items-center gap-2">
                    <Users className="text-blue-600" size={20} />
                    Mi Proyecto
                </h2>

                {loading ? (
                    <div className="h-32 bg-gray-100 dark:bg-slate-800 rounded-2xl animate-pulse" />
                ) : project ? (
                    <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="bg-white dark:bg-[#1a1d27] rounded-3xl p-6 border border-gray-200 dark:border-slate-700/50 shadow-sm"
                    >
                        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
                            <div>
                                <h3 className="text-2xl font-bold text-gray-900 dark:text-white break-words">{project.titulo}</h3>
                                <div className="flex flex-wrap gap-2 mt-2">
                                    <span className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-xs font-bold uppercase tracking-wider">
                                        {project.materia}
                                    </span>
                                    <span className="px-3 py-1 bg-gray-100 dark:bg-slate-800 text-gray-600 dark:text-slate-300 rounded-full text-xs font-bold uppercase tracking-wider">
                                        {project.estado}
                                    </span>
                                </div>
                            </div>
                            <button
                                onClick={() => navigate(`/project/${project.id}/editor`)}
                                className="w-full md:w-auto px-4 py-2 bg-blue-600 text-white rounded-xl font-bold text-sm hover:bg-blue-700 transition"
                            >
                                Ir al Proyecto
                            </button>
                        </div>

                        {/* Members Grid - Ensure it renders and has content */}
                        {project.members && project.members.length > 0 ? (
                            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                                {project.members.map(member => (
                                    <div key={member.id} className="flex items-center gap-4 p-4 rounded-2xl bg-gray-50 dark:bg-slate-800/50 border border-gray-100 dark:border-slate-700/50">
                                        <Link to={`/profile/${member.id}`} className="shrink-0 rounded-full hover:ring-2 hover:ring-blue-500 transition-all" title="Ver perfil">
                                            <UserAvatar src={member.fotoUrl} name={(member.nombre && member.nombre !== 'Usuario') ? member.nombre : member.email} size="md" className="w-12 h-12 border-2 border-white shadow-sm" />
                                        </Link>
                                        <div className="min-w-0">
                                            <p className="font-bold text-gray-900 dark:text-white truncate">
                                                {(member.nombre && member.nombre !== 'Usuario') ? member.nombre : (member.email || 'Miembro')}
                                            </p>
                                            <p className="text-xs text-gray-500 dark:text-slate-400 uppercase font-bold truncate">{member.rol}</p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="text-gray-500 dark:text-slate-400 italic p-4 bg-gray-50 dark:bg-slate-800/50 rounded-xl">
                                No se encontraron miembros en este proyecto.
                            </div>
                        )}
                    </motion.div>
                ) : (
                    // EMPTY STATE
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        className="bg-gradient-to-br from-blue-50 dark:from-blue-900/20 to-indigo-50 dark:to-indigo-900/20 border-2 border-dashed border-blue-200 dark:border-blue-700/50 rounded-3xl p-8 text-center"
                    >
                        <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center mx-auto mb-4 shadow-sm text-blue-500">
                            <Plus size={32} />
                        </div>
                        <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">No tienes proyecto activo</h3>
                        <p className="text-gray-600 dark:text-slate-400 mb-6 max-w-sm mx-auto">
                            Ve al apartado de "Mis Proyectos" para crear uno nuevo e invitar a tus compañeros.
                        </p>
                        <button
                            onClick={() => navigate('/projects')} // Navigate where Create Project Modal can be opened
                            className="px-6 py-3 bg-blue-600 text-white rounded-xl font-bold hover:shadow-lg hover:scale-105 transition-all"
                        >
                            Crear Proyecto
                        </button>
                    </motion.div>
                )}
            </section>

            <hr className="border-gray-200 dark:border-slate-700/50" />

            {/* CLASSMATES SECTION */}
            <section className="flex-1 min-h-0 flex flex-col">
                <div className="flex justify-between items-center mb-6">
                    <h2 className="text-xl font-bold text-gray-800 dark:text-white flex items-center gap-2">
                        <User className="text-gray-400" size={20} />
                        Compañeros de Clase ({availableStudents.length})
                    </h2>

                    {/* Search */}
                    <div className="bg-white dark:bg-[#1a1d27] p-2 rounded-xl border border-gray-200 dark:border-slate-700/50 shadow-sm w-full max-w-sm flex items-center">
                        <Search className="ml-2 text-gray-400" size={18} />
                        <input
                            type="text"
                            placeholder="Buscar compañero..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="w-full px-3 bg-transparent dark:text-white outline-none text-sm dark:placeholder:text-slate-500"
                        />
                    </div>
                </div>

                {/* Students Grid */}
                {loading ? (
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        {[1, 2, 3].map(i => <div key={i} className="h-40 bg-gray-100 dark:bg-slate-800 rounded-2xl animate-pulse" />)}
                    </div>
                ) : availableStudents.length > 0 ? (
                    <motion.div
                        variants={containerVariants}
                        initial="hidden"
                        animate="visible"
                        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 pb-10"
                    >
                        {availableStudents.map((student) => (
                            <motion.div
                                key={student.id}
                                variants={itemVariants}
                                whileHover={{ y: -4 }}
                                className="bg-white dark:bg-[#1a1d27] p-5 rounded-2xl border border-gray-100 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all group"
                            >
                                <div className="flex items-center gap-4 mb-4">
                                    <Link to={`/profile/${student.id}`} className="shrink-0 rounded-full hover:ring-2 hover:ring-blue-500 transition-all" title="Ver perfil">
                                        <UserAvatar src={student.fotoUrl} name={student.nombreCompleto} size="md" className="w-12 h-12 group-hover:bg-blue-100" />
                                    </Link>
                                    <div className="min-w-0">
                                        <h3 className="font-bold text-gray-900 dark:text-white truncate">{student.nombreCompleto}</h3>
                                        <p className="text-xs text-gray-500 dark:text-slate-400">{student.matricula}</p>
                                    </div>
                                </div>
                                <div className="flex justify-between items-center">
                                    <span className={`text-[10px] uppercase font-bold px-2 py-1 rounded-full ${student.hasProject ? 'bg-green-50 text-green-700' : 'bg-yellow-50 text-yellow-700'
                                        }`}>
                                        {student.hasProject ? 'En Proyecto' : 'Disponible'}
                                    </span>
                                    <button className="text-sm font-medium text-gray-400 dark:text-slate-500 hover:text-gray-900 dark:hover:text-white transition-colors">
                                        Contactar
                                    </button>
                                </div>
                            </motion.div>
                        ))}
                    </motion.div>
                ) : (
                    <div className="text-center py-10 text-gray-400">
                        No se encontraron compañeros con ese nombre.
                    </div>
                )}
            </section>
        </div>
    );
}
