import { Code } from 'lucide-react';
import { motion } from 'framer-motion';

export function TeamSuggestions({ suggestions }) {
    if (!suggestions || suggestions.length === 0) {
        return null;
    }

    return (
        <div className="bg-white dark:bg-[#1a1d27] rounded-xl border border-gray-100 dark:border-slate-800 p-6 shadow-sm transition-colors duration-300">
            <div className="flex flex-col items-center justify-center text-center mb-6">
                <h3 className="text-lg font-bold text-gray-900 dark:text-white transition-colors">Encuentra a tu equipo</h3>
                <p className="text-sm text-gray-500 dark:text-slate-400 mt-1 transition-colors">Compañeros sin equipo en tu grupo</p>
            </div>

            <div className="space-y-4">
                {suggestions.map((student, index) => (
                    <motion.div
                        key={student.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: index * 0.1 }}
                        className="flex flex-col items-center p-4 hover:bg-gray-50 dark:hover:bg-slate-800/50 rounded-xl transition-all duration-200 border border-gray-50 dark:border-slate-800/50 hover:border-gray-100 dark:hover:border-slate-700 shadow-sm hover:shadow-md"
                    >
                        {student.fotoUrl ? (
                            <img
                                src={student.fotoUrl}
                                alt={student.nombreCompleto}
                                className="h-12 w-12 rounded-full object-cover mb-3 shadow-sm border border-gray-100"
                            />
                        ) : (
                            <div className="h-12 w-12 rounded-full bg-gradient-to-br from-indigo-100 to-blue-100 dark:from-indigo-900/40 dark:to-blue-900/40 flex items-center justify-center text-indigo-700 dark:text-indigo-300 font-bold uppercase mb-3 shadow-sm border border-transparent dark:border-indigo-800/30">
                                {student.nombreCompleto?.substring(0, 2) || 'US'}
                            </div>
                        )}
                        <div className="text-center">
                            <p className="text-sm font-semibold text-gray-900 dark:text-white transition-colors">{student.nombreCompleto}</p>
                            <div className="flex items-center justify-center mt-1.5">
                                <span className="flex items-center gap-1.5 text-xs text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30 px-2.5 py-1 rounded-full font-medium border border-blue-100/50 dark:border-blue-800/30">
                                    <Code size={12} />
                                    {student.matricula || 'Sin Matrícula'}
                                </span>
                            </div>
                        </div>
                    </motion.div>
                ))}
            </div>

            <button className="w-full mt-4 py-2 text-sm font-semibold text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-colors text-center hidden">
                Ver todos
            </button>
        </div>
    );
}
