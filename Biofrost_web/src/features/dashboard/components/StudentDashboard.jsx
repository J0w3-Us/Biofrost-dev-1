import { useMemo } from 'react';
import { motion } from 'framer-motion';
import { Users, Star, Clock, CheckCircle, ExternalLink, Plus } from 'lucide-react';
import { StatCard } from './StatCard';
import { ProjectTimelineChart } from './ProjectTimelineChart';
import { RubricRadarChart } from './RubricRadarChart';
import { TeamSuggestions } from './TeamSuggestions';
import { ShowcaseCard } from '../../public/components/ShowcaseCard';

export function StudentDashboard({
    userData,
    project,
    suggestedStudents,
    onShowCreateModal,
    onProjectClick
}) {
    // Calcular el estado de la evaluación ("Aprobado" si >= 70)
    const isApproved = project && (project.calificacion ?? 0) >= 70;

    // Calcular si está "Listo para evaluar" (han pasado 2 días desde la creación)
    const isReadyToEvaluate = useMemo(() => {
        if (!project) return false;

        let createdDate;
        if (project.createdAt?._seconds) {
            createdDate = new Date(project.createdAt._seconds * 1000);
        } else if (typeof project.createdAt === 'string') {
            createdDate = new Date(project.createdAt);
        } else {
            createdDate = new Date();
        }

        const now = new Date();
        const diffTime = Math.abs(now - createdDate);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        return diffDays >= 2;
    }, [project]);

    const containerVariants = {
        hidden: { opacity: 0 },
        visible: { opacity: 1, transition: { staggerChildren: 0.1 } }
    };

    if (!project) {
        return (
            <motion.div
                variants={containerVariants}
                initial="hidden"
                animate="visible"
                className="bg-white dark:bg-[#1a1d27] rounded-2xl border border-gray-200 dark:border-slate-700/50 p-12 text-center shadow-sm"
            >
                <div className="w-20 h-20 bg-blue-50 dark:bg-blue-900/30 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-6">
                    <Star size={32} />
                </div>
                <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">¡Hola, {userData?.nombre?.split(' ')[0]}!</h2>
                <p className="text-gray-500 dark:text-slate-400 max-w-md mx-auto mb-8 text-lg">
                    Aún no formas parte de ningún proyecto integral. Comienza creando tu propio proyecto o únete al de un compañero.
                </p>
                <div className="flex flex-col items-center gap-6 mt-4">
                    <button
                        onClick={onShowCreateModal}
                        className="inline-flex items-center gap-2 bg-gray-900 text-white px-6 py-3 rounded-xl font-semibold hover:bg-gray-800 active:bg-gray-950 transition-all shadow-md hover:shadow-lg"
                    >
                        <Plus size={20} />
                        <span>Empezar mi Proyecto</span>
                    </button>
                    {suggestedStudents && suggestedStudents.length > 0 && (
                        <div className="w-full max-w-md mt-4">
                            <TeamSuggestions suggestions={suggestedStudents} />
                        </div>
                    )}
                </div>
            </motion.div>
        );
    }

    return (
        <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-6">

            {/* Header: Bienvenida y Estado Corto */}
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 bg-gradient-to-r from-gray-900 to-gray-800 p-8 rounded-2xl text-white shadow-lg overflow-hidden relative">
                <div className="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 rounded-full bg-white/5 blur-3xl pointer-events-none"></div>
                <div className="relative z-10">
                    <h2 className="text-3xl font-bold mb-2">Hola, {userData?.nombre?.split(' ')[0]} 👋</h2>
                    <p className="text-gray-300 text-lg">
                        Tu proyecto principal es <span className="font-semibold text-white">{project.titulo}</span>
                    </p>
                </div>
                <div className="flex items-center gap-3 relative z-10">
                    {isApproved ? (
                        <div className="flex items-center gap-2 bg-green-500/20 text-green-300 border border-green-500/30 px-4 py-2 rounded-full font-medium">
                            <CheckCircle size={18} />
                            <span>Aprobado</span>
                        </div>
                    ) : (
                        <div className="flex items-center gap-2 bg-blue-500/20 text-blue-300 border border-blue-500/30 px-4 py-2 rounded-full font-medium">
                            <Clock size={18} />
                            <span>En Revisión</span>
                        </div>
                    )}
                </div>
            </div>

            {/* Grid Bento Box */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

                {/* Main Content Area (2/3 width) */}
                <div className="lg:col-span-2 flex flex-col gap-6">

                    {/* Metrics Row */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                        <StatCard
                            title="Miembros"
                            value={`${project.miembrosIds?.length || 1}/5`}
                            subtitle={project.miembrosIds?.length === 5 ? "Equipo completo" : "Buscar compañeros"}
                            icon={Users}
                            color="blue"
                        />
                        <StatCard
                            title="Evaluación"
                            value={project.calificacion ? `${project.calificacion.toFixed(1)}%` : "S/N"}
                            subtitle={project.calificacion ? "Puntaje oficial" : "Aún sin calificar"}
                            icon={Star}
                            color={project.calificacion && project.calificacion >= 70 ? "green" : "amber"}
                        />
                        <StatCard
                            title="Listo para evaluar"
                            value={isReadyToEvaluate ? "Sí" : "No"}
                            subtitle={isReadyToEvaluate ? "Tiempo cumplido" : "Revisando detalles"}
                            icon={Clock}
                            color={isReadyToEvaluate ? "purple" : "gray"}
                        />
                    </div>

                    <ProjectTimelineChart project={project} />
                    <RubricRadarChart project={project} />

                </div>

                {/* Sidebar Content Area (1/3 width) */}
                <div className="lg:col-span-1 flex flex-col gap-6">

                    {/* Proyecto Card */}
                    <div className="flex flex-col gap-4">
                        <div className="flex items-center justify-between px-1">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white">Acceso Rápido</h3>
                            <button
                                onClick={onProjectClick}
                                className="text-blue-600 hover:text-blue-800 transition-colors bg-blue-50 p-2 rounded-lg"
                                title="Abrir Proyecto"
                            >
                                <ExternalLink size={18} />
                            </button>
                        </div>
                        <ShowcaseCard
                            project={{ ...project, coverUrl: project.videoUrl || project.thumbnailUrl || null }}
                            onClick={onProjectClick}
                        />
                    </div>

                    {/* Team Suggestions */}
                    <TeamSuggestions suggestions={suggestedStudents} />

                </div>
            </div>
        </motion.div>
    );
}
