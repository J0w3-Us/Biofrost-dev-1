import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Save, Loader } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import { CanvasEditor } from '../components/CanvasEditor';
import api from '../../../lib/axios';

export function ProjectEditorPage() {
    const { id } = useParams();
    const navigate = useNavigate();
    const { userData } = useAuth();
    const [project, setProject] = useState(null);
    const [loading, setLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);

    // Reference to the CanvasEditor to trigger manual save
    const editorRef = useRef(null);

    useEffect(() => {
        fetchProject();
    }, [id]);

    const fetchProject = async () => {
        try {
            const response = await api.get(`/api/projects/${id}`);
            // Map backend CanvasBlocks to frontend format if needed (currently matching)
            const projectData = response.data;
            if (!projectData.canvas) projectData.canvas = projectData.canvasBlocks || [];
            setProject(projectData);
        } catch (error) {
            console.error('Error fetching project:', error);
            // Handle 404 or auth error
        } finally {
            setLoading(false);
        }
    };

    const handleManualSave = () => {
        if (editorRef.current) {
            editorRef.current.save();
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-white dark:bg-[#0f1117] flex items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
        );
    }

    if (!project) return <div>Proyecto no encontrado</div>;

    return (
        <div className="min-h-screen bg-white dark:bg-[#0f1117]">
            {/* Navigation Bar */}
            <nav className="border-b border-gray-100 dark:border-slate-700/50 px-4 py-3 sticky top-0 bg-white/80 dark:bg-[#0f1117]/80 backdrop-blur z-10 flex items-center justify-between">
                <button
                    onClick={() => navigate('/dashboard')}
                    className="flex items-center gap-2 text-gray-500 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                >
                    <ArrowLeft size={20} />
                    <span className="text-sm font-medium">Volver al Dashboard</span>
                </button>

                <div className="flex items-center gap-4">
                    <div className="flex -space-x-2">
                        {(project.members || []).slice(0, 3).map(m => (
                            <img
                                key={m.id}
                                src={m.fotoUrl || `https://ui-avatars.com/api/?name=${m.nombre}&background=random`}
                                className="w-8 h-8 rounded-full border-2 border-white dark:border-slate-800"
                                title={m.nombre}
                            />
                        ))}
                        {(project.members || []).length > 3 && (
                            <div className="w-8 h-8 rounded-full bg-gray-100 dark:bg-slate-700 flex items-center justify-center text-xs font-bold text-gray-500 dark:text-slate-300 border-2 border-white dark:border-slate-800">
                                +{project.members.length - 3}
                            </div>
                        )}
                    </div>
                    <button
                        className={`
                            px-4 py-2 rounded-xl text-sm font-bold transition-all flex items-center gap-2
                            ${isSaving
                                ? 'bg-gray-100 text-gray-500'
                                : 'bg-blue-600 text-white hover:bg-blue-700 shadow-lg hover:shadow-blue-500/30'
                            }
                        `}
                        onClick={handleManualSave}
                        disabled={isSaving}
                    >
                        {isSaving ? (
                            <>
                                <Loader size={16} className="animate-spin" />
                                Guardando...
                            </>
                        ) : (
                            <>
                                <Save size={16} />
                                Guardar
                            </>
                        )}
                    </button>
                </div>
            </nav>

            {/* Editor Area */}
            <CanvasEditor
                ref={editorRef}
                project={project}
                onSaveStatusChange={setIsSaving}
            />
        </div>
    );
}
