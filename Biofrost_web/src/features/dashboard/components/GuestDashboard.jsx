import { motion } from 'framer-motion';
import { Rocket, Sparkles, Image, Trophy } from 'lucide-react';
import { Link } from 'react-router-dom';

export function GuestDashboard({ userData }) {
    const containerVariants = {
        hidden: { opacity: 0 },
        visible: { opacity: 1, transition: { staggerChildren: 0.1 } }
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 24 } }
    };

    return (
        <motion.div variants={containerVariants} initial="hidden" animate="visible" className="space-y-8">
            {/* Hero Section */}
            <motion.div variants={itemVariants} className="bg-gradient-to-br from-indigo-900 via-purple-900 to-slate-900 rounded-3xl p-8 sm:p-12 text-white relative overflow-hidden shadow-2xl">
                <div className="absolute right-0 top-0 w-full h-full opacity-10 pointer-events-none mix-blend-overlay"></div>
                <div className="absolute -right-32 -top-32 w-96 h-96 bg-purple-500/20 rounded-full blur-[100px] pointer-events-none" />
                <div className="absolute -left-32 -bottom-32 w-96 h-96 bg-blue-500/20 rounded-full blur-[100px] pointer-events-none" />

                <div className="relative z-10 max-w-2xl">
                    <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-white/20 text-sm font-medium text-purple-200 mb-6 backdrop-blur-md">
                        <Sparkles size={16} />
                        <span>Bienvenido a Byfrost</span>
                    </div>

                    <h2 className="text-4xl sm:text-5xl font-extrabold mb-6 leading-tight">
                        Hola, {userData?.nombre?.split(' ')[0] || 'Invitado'} 👋
                    </h2>
                    <p className="text-xl text-purple-100/90 leading-relaxed mb-8">
                        Estás explorando Byfrost como invitado. Descubre los proyectos más innovadores creados por estudiantes, explora la galería y mira quiénes lideran el ranking global.
                    </p>

                    <div className="flex flex-wrap gap-4">
                        <Link to="/showcase" className="inline-flex items-center gap-2 bg-white text-indigo-950 px-6 py-3.5 rounded-xl font-bold hover:bg-indigo-50 hover:scale-105 active:scale-95 transition-all shadow-[0_0_20px_rgba(255,255,255,0.3)]">
                            <Rocket size={20} />
                            <span>Explorar Galería</span>
                        </Link>
                        <Link to="/ranking" className="inline-flex items-center gap-2 bg-white/10 text-white border border-white/20 px-6 py-3.5 rounded-xl font-bold hover:bg-white/20 hover:scale-105 active:scale-95 transition-all backdrop-blur-md">
                            <Trophy size={20} />
                            <span>Ver Ranking</span>
                        </Link>
                    </div>
                </div>
            </motion.div>

            {/* Quick Links Grid */}
            <motion.div variants={itemVariants} className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Link to="/showcase" className="group bg-white dark:bg-[#1a1d27] rounded-3xl p-8 border border-gray-100 dark:border-slate-800 hover:border-indigo-500/30 flex flex-col gap-4 transition-all hover:shadow-xl hover:-translate-y-1">
                    <div className="w-16 h-16 rounded-2xl bg-indigo-50 dark:bg-indigo-500/10 flex items-center justify-center text-indigo-600 dark:text-indigo-400 group-hover:scale-110 group-hover:bg-indigo-600 group-hover:text-white transition-all duration-300">
                        <Image size={32} strokeWidth={1.5} />
                    </div>
                    <div>
                        <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Galería de Proyectos</h3>
                        <p className="text-gray-500 dark:text-slate-400 leading-relaxed">Explora el repositorio completo de proyectos integradores, filtra por categorías y encuentra inspiración para tus propias ideas.</p>
                    </div>
                </Link>

                <Link to="/ranking" className="group bg-white dark:bg-[#1a1d27] rounded-3xl p-8 border border-gray-100 dark:border-slate-800 hover:border-purple-500/30 flex flex-col gap-4 transition-all hover:shadow-xl hover:-translate-y-1">
                    <div className="w-16 h-16 rounded-2xl bg-purple-50 dark:bg-purple-500/10 flex items-center justify-center text-purple-600 dark:text-purple-400 group-hover:scale-110 group-hover:bg-purple-600 group-hover:text-white transition-all duration-300">
                        <Trophy size={32} strokeWidth={1.5} />
                    </div>
                    <div>
                        <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Ranking Global</h3>
                        <p className="text-gray-500 dark:text-slate-400 leading-relaxed">Descubre cuáles son los proyectos mejor valorados de la plataforma y el trabajo sobresaliente de nuestros estudiantes.</p>
                    </div>
                </Link>
            </motion.div>
        </motion.div>
    );
}
