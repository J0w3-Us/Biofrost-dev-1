import { useState, useEffect } from 'react';
import { Search, Filter, Rocket, MoreHorizontal } from 'lucide-react';
import api from '../../../lib/axios';

// Import Shared Component
// Import Shared Component
import { ShowcaseCard } from '../components/ShowcaseCard';
import { ProjectDetailsModal } from '../../projects/components/ProjectDetailsModal';

export function ShowcasePage() {
    const [projects, setProjects] = useState([]);
    const [filteredProjects, setFilteredProjects] = useState([]);
    const [selectedProject, setSelectedProject] = useState(null);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedStack, setSelectedStack] = useState(null);
    const [allStacks, setAllStacks] = useState([]);
    const [isSearchExpanded, setIsSearchExpanded] = useState(false);

    useEffect(() => {
        fetchPublicProjects();
    }, []);

    useEffect(() => {
        filterProjects();
    }, [searchTerm, selectedStack, projects]);

    const fetchPublicProjects = async () => {
        try {
            const response = await api.get('/api/projects/public');
            setProjects(response.data);

            // Extract unique stacks
            const stacks = new Set();
            response.data.forEach(p => {
                p.stackTecnologico?.forEach(tech => stacks.add(tech));
            });
            setAllStacks(Array.from(stacks).sort());
        } catch (error) {
            console.error('Error fetching public projects:', error);
        } finally {
            setLoading(false);
        }
    };

    const filterProjects = () => {
        let filtered = projects;

        if (searchTerm) {
            filtered = filtered.filter(p =>
                p.titulo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                p.materia?.toLowerCase().includes(searchTerm.toLowerCase())
            );
        }

        if (selectedStack) {
            filtered = filtered.filter(p =>
                p.stackTecnologico?.includes(selectedStack)
            );
        }

        setFilteredProjects(filtered);
    };

    return (
        <div className="min-h-screen bg-white dark:bg-[#0f1117] font-sans text-gray-900 dark:text-white">
            {/* Header / Hero */}
            <header className="border-b border-gray-100 dark:border-slate-700/50 bg-white dark:bg-[#0f1117]">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
                    <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
                        <div>
                            <h1 className="text-3xl md:text-5xl font-bold tracking-tight text-gray-900 dark:text-white mb-3">
                                Galería de Proyectos
                            </h1>
                            <p className="text-gray-500 dark:text-slate-400 text-lg max-w-xl">
                                Explora el talento y la innovación de nuestros estudiantes.
                            </p>
                        </div>

                        {/* Search Input - Spherical "Thinking Bubble" Design */}
                        <div className={`flex items-center gap-1.5 transition-all duration-500 ease-[cubic-bezier(0.23,1,0.32,1)] ${isSearchExpanded ? 'w-full md:w-96' : 'w-fit'}`}>
                            {/* Thinking Dots */}
                            {!isSearchExpanded && (
                                <div className="flex items-end gap-1 mb-1 animate-in fade-in duration-700">
                                    <div className="w-1.5 h-1.5 bg-gray-50 dark:bg-[#1a1d27] border border-gray-200 dark:border-slate-700/50 rounded-full shadow-sm"></div>
                                    <div className="w-2.5 h-2.5 bg-gray-50 dark:bg-[#1a1d27] border border-gray-200 dark:border-slate-700/50 rounded-full shadow-sm"></div>
                                </div>
                            )}

                            <div 
                                onClick={() => !isSearchExpanded && setIsSearchExpanded(true)}
                                className={`flex items-center bg-gray-50 dark:bg-[#1a1d27] border border-gray-200 dark:border-slate-700/50 shadow-md cursor-pointer transition-all duration-500 ease-[cubic-bezier(0.23,1,0.32,1)] overflow-hidden ${
                                    isSearchExpanded ? 'rounded-2xl w-full px-5 py-3 h-12' : 'rounded-full w-14 h-14 justify-center hover:scale-110 active:scale-95'
                                }`}
                            >
                                <Search 
                                    className={`text-gray-400 transition-colors ${isSearchExpanded ? 'mr-3' : 'scale-125'}`} 
                                    size={isSearchExpanded ? 20 : 24} 
                                />
                                {isSearchExpanded && (
                                    <input
                                        autoFocus
                                        type="text"
                                        value={searchTerm}
                                        onChange={(e) => setSearchTerm(e.target.value)}
                                        onBlur={() => !searchTerm && setIsSearchExpanded(false)}
                                        placeholder="Buscar proyecto..."
                                        className="w-full bg-transparent border-none focus:outline-none text-base font-semibold placeholder-gray-400 dark:placeholder-slate-500 dark:text-white"
                                    />
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">

                {/* Filters */}
                <div className="mb-10 overflow-x-auto pb-4 scrollbar-hide">
                    <div className="flex items-center gap-3">
                        <div className="flex items-center gap-3 px-4 py-2 bg-gray-50 dark:bg-[#1a1d27] rounded-2xl border border-gray-100 dark:border-slate-700/50 mr-2 shadow-sm">
                            <div className="p-1.5 bg-white dark:bg-[#0f1117] rounded-xl shadow-sm border border-gray-100 dark:border-slate-700">
                                <Filter size={16} className="text-gray-400 dark:text-slate-500" />
                            </div>
                            <span className="text-sm font-bold tracking-tight text-gray-700 dark:text-slate-300 whitespace-nowrap">
                                Colección
                            </span>
                        </div>
                        <button
                            onClick={() => setSelectedStack(null)}
                            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-all whitespace-nowrap border ${selectedStack === null
                                ? 'bg-gray-900 text-white border-gray-900'
                                : 'bg-white dark:bg-[#1a1d27] text-gray-600 dark:text-slate-300 border-gray-200 dark:border-slate-700 hover:border-gray-300 dark:hover:border-slate-600'
                                }`}
                        >
                            Todas
                        </button>
                        {allStacks.map(stack => (
                            <button
                                key={stack}
                                onClick={() => setSelectedStack(stack)}
                                className={`px-4 py-1.5 rounded-full text-sm font-medium transition-all whitespace-nowrap border ${selectedStack === stack
                                    ? 'bg-gray-900 text-white border-gray-900'
                                    : 'bg-white dark:bg-[#1a1d27] text-gray-600 dark:text-slate-300 border-gray-200 dark:border-slate-700 hover:border-gray-300 dark:hover:border-slate-600'
                                    }`}
                            >
                                {stack}
                            </button>
                        ))}
                    </div>
                </div>

                {/* Grid */}
                {loading ? (
                    <div className="space-y-8 animate-pulse">
                        {[1, 2, 3].map((i) => (
                            <div key={i} className="bg-gray-100 dark:bg-slate-800 rounded-3xl h-[400px]"></div>
                        ))}
                    </div>
                ) : filteredProjects.length > 0 ? (
                    <div className="grid grid-cols-1 gap-16 w-[95%] md:w-[90%] lg:w-[85%] xl:w-[80%] max-w-5xl mx-auto">
                        {filteredProjects.map(project => (
                            <ShowcaseCard
                                key={project.id}
                                project={project}
                                onClick={() => setSelectedProject(project)}
                            />
                        ))}
                    </div>
                ) : (
                    <div className="text-center py-20 bg-gray-50 dark:bg-[#1a1d27] rounded-2xl border border-dashed border-gray-200 dark:border-slate-700">
                        <div className="w-16 h-16 bg-white dark:bg-slate-800 rounded-full flex items-center justify-center mx-auto mb-4 shadow-sm text-gray-400">
                            <Search size={24} />
                        </div>
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">Sin resultados</h3>
                        <p className="text-gray-500 dark:text-slate-400">No encontramos proyectos con esos filtros.</p>
                    </div>
                )}

                {/* Details Modal */}
                {selectedProject && (
                    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                        <div className="bg-black dark:bg-black w-[95vw] md:w-[95vw] lg:w-[95vw] xl:w-[95vw] 2xl:w-[95vw] max-w-none rounded-2xl shadow-2xl border border-gray-100 dark:border-slate-700/50 overflow-hidden h-[95vh] flex flex-col">
                            <ProjectDetailsModal
                                key={selectedProject.id}
                                project={selectedProject}
                                onClose={() => setSelectedProject(null)}
                                onUpdate={fetchPublicProjects}
                            />
                        </div>
                    </div>
                )}
            </main>
        </div>
    );
}
