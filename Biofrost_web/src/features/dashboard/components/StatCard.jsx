import { motion } from 'framer-motion';

export function StatCard({ title, value, subtitle, icon: Icon, color = 'blue' }) {
    const colorClasses = {
        blue: 'bg-blue-50 text-blue-600',
        green: 'bg-green-50 text-green-600',
        amber: 'bg-amber-50 text-amber-600',
        purple: 'bg-purple-50 text-purple-600',
        gray: 'bg-gray-50 text-gray-600'
    };

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
            className="bg-white dark:bg-[#1a1d27] rounded-xl border border-gray-100 dark:border-slate-700/50 p-5 shadow-sm hover:shadow-md transition-shadow"
        >
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-sm font-medium text-gray-500 dark:text-slate-400 mb-1">{title}</p>
                    <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{value}</h3>
                    {subtitle && (
                        <p className="text-xs text-gray-400 dark:text-slate-500 mt-1">{subtitle}</p>
                    )}
                </div>
                {Icon && (
                    <div className={`p-3 rounded-lg ${colorClasses[color] || colorClasses.blue}`}>
                        <Icon size={20} />
                    </div>
                )}
            </div>
        </motion.div>
    );
}

