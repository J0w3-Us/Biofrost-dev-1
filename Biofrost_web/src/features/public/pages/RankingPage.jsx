import { useState, useEffect } from 'react';
import { Trophy, Medal, Star, Crown } from 'lucide-react';
import api from '../../../lib/axios';

export function RankingPage() {
    const [projects, setProjects] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchRanking();
    }, []);

    const fetchRanking = async () => {
        try {
            const response = await api.get('/api/projects/public');
            // Sort by Total Points Descending
            const sorted = response.data.sort((a, b) => (b.puntosTotales || 0) - (a.puntosTotales || 0));
            setProjects(sorted);
        } catch (error) {
            console.error('Error fetching ranking:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-cyan-600"></div>
        </div>
    );

    const top3 = projects.slice(0, 3);
    const rest = projects.slice(3, 20); // Top 20

    return (
        <div className="min-h-screen bg-gray-50 font-sans text-gray-900 pb-20">

            {/* Header */}
            <div className="bg-slate-950 text-white py-12 relative overflow-hidden">
                <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-10"></div>
                <div className="max-w-5xl mx-auto px-4 relative z-10 text-center">
                    <div className="inline-flex items-center gap-2 bg-cyan-950/40 backdrop-blur-sm px-4 py-1.5 rounded-full border border-cyan-900/50 mb-4">
                        <Trophy size={16} className="text-cyan-400" />
                        <span className="text-sm font-semibold tracking-wide uppercase text-cyan-100">Leaderboard Oficial</span>
                    </div>
                    <h1 className="text-4xl md:text-6xl font-black mb-4 tracking-tight">
                        Ranking de Proyectos
                    </h1>
                    <p className="text-slate-300 text-lg max-w-2xl mx-auto">
                        Los mejores proyectos del ciclo escolar, votados por la comunidad y evaluados por expertos.
                    </p>
                </div>
            </div>

            <div className="max-w-5xl mx-auto px-4 -mt-10 relative z-20">

                {/* PODIUM (Top 3) */}
                {top3.length > 0 && (
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-12 items-end">
                        {/* 2nd Place */}
                        {top3[1] && (
                            <div className="bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden order-2 md:order-1 transform md:translate-y-4">
                                <div className="bg-gray-200 py-2 text-center font-bold text-gray-700 flex items-center justify-center gap-2">
                                    <Medal size={20} /> #2 Lugar
                                </div>
                                <div className="p-6 text-center">
                                    <div className="w-20 h-20 mx-auto bg-gray-100 rounded-full mb-4 flex items-center justify-center text-2xl font-bold text-gray-400 border-4 border-gray-200">
                                        2
                                    </div>
                                    <h3 className="font-bold text-lg mb-1 truncate">{top3[1].titulo}</h3>
                                    <p className="text-sm text-gray-500 mb-3">{top3[1].liderNombre}</p>
                                    <div className="inline-flex items-center gap-1 bg-yellow-50 text-yellow-700 px-3 py-1 rounded-full font-bold text-sm">
                                        <Star size={14} fill="currentColor" />
                                        {top3[1].puntosTotales} pts
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* 1st Place */}
                        {top3[0] && (
                            <div className="bg-white rounded-2xl shadow-2xl border-2 border-yellow-400 overflow-hidden order-1 md:order-2 transform scale-105 z-10">
                                <div className="bg-gradient-to-r from-yellow-400 to-orange-400 py-3 text-center font-bold text-white flex items-center justify-center gap-2">
                                    <Crown size={24} /> #1 Campeón
                                </div>
                                <div className="p-8 text-center bg-gradient-to-b from-yellow-50 to-white">
                                    <div className="w-24 h-24 mx-auto bg-yellow-100 rounded-full mb-4 flex items-center justify-center text-4xl font-black text-yellow-600 border-4 border-yellow-400 shadow-inner">
                                        1
                                    </div>
                                    <h3 className="font-black text-xl mb-1 truncate text-gray-900">{top3[0].titulo}</h3>
                                    <p className="text-sm text-gray-600 mb-4 font-medium">{top3[0].liderNombre}</p>
                                    <div className="inline-flex items-center gap-1 bg-yellow-400 text-yellow-900 px-5 py-2 rounded-full font-bold text-lg shadow-lg shadow-yellow-200">
                                        <Trophy size={18} fill="currentColor" />
                                        {top3[0].puntosTotales} pts
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* 3rd Place */}
                        {top3[2] && (
                            <div className="bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden order-3 md:order-3 transform md:translate-y-8">
                                <div className="bg-orange-100 py-2 text-center font-bold text-orange-800 flex items-center justify-center gap-2">
                                    <Medal size={20} /> #3 Lugar
                                </div>
                                <div className="p-6 text-center">
                                    <div className="w-20 h-20 mx-auto bg-orange-50 rounded-full mb-4 flex items-center justify-center text-2xl font-bold text-orange-400 border-4 border-orange-200">
                                        3
                                    </div>
                                    <h3 className="font-bold text-lg mb-1 truncate">{top3[2].titulo}</h3>
                                    <p className="text-sm text-gray-500 mb-3">{top3[2].liderNombre}</p>
                                    <div className="inline-flex items-center gap-1 bg-yellow-50 text-yellow-700 px-3 py-1 rounded-full font-bold text-sm">
                                        <Star size={14} fill="currentColor" />
                                        {top3[2].puntosTotales} pts
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                )}

                {/* Remaining List */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full text-left">
                            <thead className="bg-gray-50 border-b border-gray-100">
                                <tr>
                                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Posición</th>
                                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Proyecto</th>
                                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Líder</th>
                                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Puntos Totales</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {rest.map((project, index) => (
                                    <tr key={project.id} className="hover:bg-gray-50/50 transition-colors">
                                        <td className="px-6 py-4 whitespace-nowrap text-gray-500 font-bold">
                                            #{index + 4}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="font-bold text-gray-900">{project.titulo}</div>
                                            <div className="text-xs text-gray-500">{project.materia}</div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                                            {project.liderNombre}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right">
                                            <div className="inline-flex items-center gap-1 font-bold text-gray-900">
                                                {project.puntosTotales} pts
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>
        </div>
    );
}
