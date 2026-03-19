import { useMemo } from 'react';
import { Radar, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, ResponsiveContainer, Tooltip } from 'recharts';
import { Trophy, Info } from 'lucide-react';

const CustomTooltip = ({ active, payload }) => {
    if (active && payload && payload.length) {
        return (
            <div className="bg-white dark:bg-[#1a1d27] p-3 rounded-lg shadow-xl border border-gray-200 dark:border-slate-700/50">
                <p className="font-semibold text-gray-900 dark:text-white capitalize">
                    {payload[0].payload.subject}
                </p>
                <p className="text-blue-600 dark:text-blue-400 font-bold">
                    {payload[0].value}% <span className="text-xs text-gray-500 font-normal">de puntuación máxima</span>
                </p>
            </div>
        );
    }
    return null;
};

export function RubricRadarChart({ project }) {
    const { hasVotes, data, highestCriterium } = useMemo(() => {
        if (!project || !project.votantes) {
            return { hasVotes: false, data: [], highestCriterium: null };
        }

        const votersCount = Object.keys(project.votantes).length;
        if (votersCount === 0) {
            return { hasVotes: false, data: [], highestCriterium: null };
        }

        const maxPoints = votersCount * 5; // 5 estrellas máximo por criterio por evaluador

        // Mapeo seguro en caso de que algún punto sea indefinido o nulo
        const getPct = (points) => {
            if (!points || maxPoints === 0) return 0;
            return Number(((points / maxPoints) * 100).toFixed(1));
        };

        const chartData = [
            { subject: 'UI/UX', A: getPct(project.puntosUIUX), fullMark: 100 },
            { subject: 'Innovación', A: getPct(project.puntosInovacion), fullMark: 100 },
            { subject: 'Presentación', A: getPct(project.puntosPresentacion), fullMark: 100 },
            { subject: 'Impacto', A: getPct(project.puntosImpacto), fullMark: 100 },
        ];

        // Encontrar el valor más alto
        const max = chartData.reduce((prev, current) => (prev.A > current.A) ? prev : current);

        return {
            hasVotes: true,
            data: chartData,
            highestCriterium: max.A > 0 ? max : null
        };
    }, [project]);

    if (!hasVotes) {
        return (
            <div className="bg-white dark:bg-[#1a1d27] rounded-2xl border border-gray-200 dark:border-slate-700/50 p-6 shadow-sm flex flex-col items-center justify-center text-center h-full min-h-[300px]">
                <div className="w-16 h-16 bg-gray-50 dark:bg-slate-800 rounded-full flex items-center justify-center mb-4 text-gray-400">
                    <Info size={28} />
                </div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Sin Evaluaciones</h3>
                <p className="text-gray-500 dark:text-slate-400 text-sm max-w-[250px]">
                    Tu proyecto no ha recibido votos estructurados. ¡Comparte tu proyecto para obtener feedback!
                </p>
            </div>
        );
    }

    return (
        <div className="bg-white dark:bg-[#1a1d27] rounded-2xl border border-gray-200 dark:border-slate-700/50 p-6 shadow-sm flex flex-col h-full min-h-[350px]">
            <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-bold text-gray-900 dark:text-white">Análisis de Desempeño</h3>
                {highestCriterium && (
                    <div className="flex items-center gap-1.5 bg-amber-50 dark:bg-amber-900/20 text-amber-600 dark:text-amber-500 px-3 py-1 rounded-full text-xs font-semibold border border-amber-200 dark:border-amber-800/50">
                        <Trophy size={14} />
                        <span>Destaca en {highestCriterium.subject}</span>
                    </div>
                )}
            </div>
            
            <p className="text-sm text-gray-500 dark:text-slate-400 mb-6">
                Porcentaje de aprobación basado en la evaluación de la rúbrica.
            </p>

            <div className="flex-1 w-full relative min-h-[250px] -mt-4">
                <ResponsiveContainer width="100%" height="100%">
                    <RadarChart cx="50%" cy="50%" outerRadius="70%" data={data}>
                        <PolarGrid stroke="#334155" strokeDasharray="3 3" opacity={0.3} />
                        <PolarAngleAxis 
                            dataKey="subject" 
                            tick={{ fill: '#64748b', fontSize: 12, fontWeight: 500 }} 
                        />
                        <PolarRadiusAxis 
                            angle={30} 
                            domain={[0, 100]} 
                            tick={{ fill: '#94a3b8', fontSize: 10 }}
                            tickCount={5}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Radar
                            name="Puntuación"
                            dataKey="A"
                            stroke="#3b82f6"
                            fill="#3b82f6"
                            fillOpacity={0.4}
                            animationBegin={200}
                            animationDuration={1500}
                            animationEasing="ease-out"
                        />
                    </RadarChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
}
