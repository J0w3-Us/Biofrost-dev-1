import { useMemo } from 'react';
import {
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer
} from 'recharts';

export function ProjectTimelineChart({ project }) {
    const data = useMemo(() => {
        if (!project) return [];

        const totalPoints = project.puntosTotales || 0;
        if (totalPoints === 0) return [];

        let createdDate;

        // Handle _seconds from timestamp or direct ISO strings
        if (project.createdAt?._seconds) {
            createdDate = new Date(project.createdAt._seconds * 1000);
        } else if (typeof project.createdAt === 'string') {
            createdDate = new Date(project.createdAt);
        } else {
            createdDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 7 days ago backfill
        }

        const startDate = createdDate;
        const endDate = new Date();
        const daysDiff = Math.max(1, Math.floor((endDate - startDate) / (1000 * 60 * 60 * 24)));

        // Generate simulated data points
        const points = [];
        let currentPoints = 0;

        // Decide how many data points to show (e.g., max 7 or 14 for readability)
        const numPoints = Math.min(daysDiff + 1, 10);

        for (let i = 0; i < numPoints; i++) {
            const isLast = i === numPoints - 1;

            if (isLast) {
                currentPoints = totalPoints;
            } else {
                // Add a random portion of the remaining points
                const progress = (i + 1) / numPoints;
                const expectedPoints = totalPoints * progress;
                const variance = totalPoints * 0.1 * (Math.random() - 0.5); // +/- 5% variance
                currentPoints = Math.max(currentPoints, Math.round(expectedPoints + variance));
            }

            const pointDate = new Date(startDate.getTime() + (endDate.getTime() - startDate.getTime()) * (i / (numPoints - 1)));

            points.push({
                date: pointDate.toLocaleDateString('es-ES', { month: 'short', day: 'numeric' }),
                puntos: currentPoints
            });
        }

        return points;
    }, [project]);

    if (!project || (project.puntosTotales || 0) === 0) {
        return (
            <div className="bg-white dark:bg-[#1a1d27] rounded-xl border border-gray-100 dark:border-slate-700/50 p-6 flex flex-col items-center justify-center h-64 shadow-sm">
                <div className="w-16 h-16 bg-blue-50 dark:bg-blue-900/30 rounded-full flex items-center justify-center mb-4">
                    <span className="text-2xl">📈</span>
                </div>
                <h3 className="text-lg font-medium text-gray-900 dark:text-white">Aún no hay votos</h3>
                <p className="text-sm text-gray-500 dark:text-slate-400 text-center max-w-xs mt-1">
                    Cuando tu proyecto reciba evaluaciones, verás aquí su crecimiento.
                </p>
            </div>
        );
    }

    return (
        <div className="bg-white dark:bg-[#1a1d27] rounded-xl border border-gray-100 dark:border-slate-700/50 p-6 shadow-sm">
            <div className="mb-6">
                <h3 className="text-lg font-bold text-gray-900 dark:text-white">Rendimiento del Proyecto</h3>
                <p className="text-sm text-gray-500 dark:text-slate-400">Evolución de puntos</p>
            </div>

            <div className="h-64 w-full">
                <ResponsiveContainer width="100%" height="100%">
                    <AreaChart
                        data={data}
                        margin={{ top: 10, right: 10, left: 0, bottom: 0 }}
                    >
                        <defs>
                            <linearGradient id="colorPuntos" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                            </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                        <XAxis
                            dataKey="date"
                            axisLine={false}
                            tickLine={false}
                            tick={{ fill: '#6b7280', fontSize: 12 }}
                            dy={10}
                        />
                        <YAxis
                            axisLine={false}
                            tickLine={false}
                            tick={{ fill: '#6b7280', fontSize: 12 }}
                            dx={-10}
                        />
                        <Tooltip
                            contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                            labelStyle={{ color: '#6b7280', marginBottom: '4px' }}
                            itemStyle={{ color: '#111827', fontWeight: 'bold' }}
                        />
                        <Area
                            type="monotone"
                            dataKey="puntos"
                            stroke="#3b82f6"
                            strokeWidth={3}
                            fillOpacity={1}
                            fill="url(#colorPuntos)"
                            animationDuration={1500}
                        />
                    </AreaChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
}
