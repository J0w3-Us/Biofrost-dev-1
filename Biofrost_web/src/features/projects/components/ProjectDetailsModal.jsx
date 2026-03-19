import { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { X, UserPlus, Trash2, ExternalLink, BookOpen, Hash, Users, Activity, Image as ImageIcon, ChevronLeft, ChevronRight, Play, Maximize2, Minimize2 } from 'lucide-react';
import { motion } from 'framer-motion';
import { useAuth } from '../../auth/hooks/useAuth';
import { UserAvatar } from '../../../components/UserAvatar';
import api from '../../../lib/axios';
import { EvaluationPanel } from '../../evaluations/components/EvaluationPanel';
import { CanvasEditor } from './CanvasEditor';
import { ProjectPDFExportButton } from './ProjectPDFExport';
import { Link } from 'react-router-dom';

export function ProjectDetailsModal({ project: initialProject, onClose, onUpdate }) {
    const { userData } = useAuth();
    // Helper to normalize keys of an object to camelCase
    const normalizeProjectData = (data) => {
        if (!data) return null;
        const normalized = {};
        Object.keys(data).forEach(key => {
            const camelKey = key.charAt(0).toLowerCase() + key.slice(1);
            normalized[camelKey] = data[key];
        });

        // Specific field mapping if needed (e.g. if backend sends weird names)
        // Ensure arrays are initialized
        if (!normalized.members) normalized.members = normalized.miembros || [];
        if (!normalized.miembrosIds) normalized.miembrosIds = [];
        if (!normalized.canvas) normalized.canvas = normalized.canvasBlocks || [];

        // Deep normalize members
        normalized.members = normalized.members.map(m => {
            if (!m) return m;
            const nm = {};
            Object.keys(m).forEach(k => nm[k.charAt(0).toLowerCase() + k.slice(1)] = m[k]);
            return nm;
        });

        // Deep normalize canvas blocks
        normalized.canvas = normalized.canvas.map(b => {
            if (!b) return b;
            const nb = {};
            Object.keys(b).forEach(k => nb[k.charAt(0).toLowerCase() + k.slice(1)] = b[k]);
            return nb;
        });

        return normalized;
    };

    const [project, setProject] = useState(() => normalizeProjectData(initialProject));
    const [activeTab, setActiveTab] = useState('docs'); // 'docs' | 'eval' | 'settings'
    const [newMemberEmail, setNewMemberEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [fetchingDetails, setFetchingDetails] = useState(true);
    const [error, setError] = useState('');
    const [editTitle, setEditTitle] = useState(initialProject.titulo || '');
    const [isDeleting, setIsDeleting] = useState(false);
    
    // Custom Confirmation States (to avoid window.confirm/prompt blocking)
    const [deleteStep, setDeleteStep] = useState(0); // 0: none, 1: first confirm, 2: final input
    const [deleteInput, setDeleteInput] = useState('');
    const [memberToRemove, setMemberToRemove] = useState(null); // stores memberId

    // Autocomplete State
    const [availableStudents, setAvailableStudents] = useState([]);
    const [fetchingStudents, setFetchingStudents] = useState(false);
    const [showSuggestions, setShowSuggestions] = useState(false);

    // Carousel State
    const [currentSlide, setCurrentSlide] = useState(0);
    const [isPlaying, setIsPlaying] = useState(false);
    const [readMode, setReadMode] = useState(false);
    const videoRef = useRef(null);
    const [isLightboxOpen, setIsLightboxOpen] = useState(false);

    const isLeader = userData?.userId === project?.liderId;
    const isAdmin = userData?.rol === 'Admin' || userData?.rol === 'SuperAdmin';
    const isAssignedTeacher = userData?.rol === 'Docente' && project?.docenteId === userData?.userId;
    const canDelete = isLeader || isAdmin || isAssignedTeacher;
    const canSeeSettings = canDelete;

    // Reset carousel/lightbox state when the project changes
    useEffect(() => {
        setCurrentSlide(0);
        setIsPlaying(false);
        setIsLightboxOpen(false);
        setReadMode(false);
        if (videoRef.current) {
            videoRef.current.pause();
        }
    }, [initialProject?.id]);

    useEffect(() => {
        fetchDetails();
        if (project?.grupoId) {
            fetchAvailableStudents();
        }
    }, [project?.grupoId]);

    const fetchAvailableStudents = async () => {
        setFetchingStudents(true);
        try {
            const response = await api.get(`/api/Teams/available-students?groupId=${project.grupoId}`);
            setAvailableStudents(response.data || []);
        } catch (err) {
            console.error('Error fetching available students:', err);
        } finally {
            setFetchingStudents(false);
        }
    };

    const fetchDetails = async () => {
        try {
            const response = await api.get(`/api/projects/${initialProject.id}`);
            let projectData = response.data;

            // Normalize canvas/canvasBlocks if needed
            if (!projectData.canvas) projectData.canvas = projectData.canvasBlocks || [];

            setProject(normalizeProjectData(projectData));
            setEditTitle(projectData.titulo);
        } catch (err) {
            console.error('Error fetching details:', err);
        } finally {
            setFetchingDetails(false);
        }
    };

    const handleAddMember = async (e) => {
        if (e) e.preventDefault(); // IMPORTANTE: Evitar recarga de página al usar con un form
        
        if (!newMemberEmail.trim()) return;
        setLoading(true);
        setError('');
        console.log('[MEMBER-DEBUG] handleAddMember triggered for:', newMemberEmail);
        
        try {
            const response = await api.post(`/api/Projects/${project.id}/members`, {
                emailOrMatricula: newMemberEmail,
                leaderId: userData.userId
            });
            console.log('[MEMBER-DEBUG] Member added response:', response.data);
            await fetchDetails();
            setNewMemberEmail('');
            setShowSuggestions(false);
            onUpdate?.();
        } catch (err) {
            console.error('[MEMBER-DEBUG] Error adding member:', err);
            setError(err.response?.data?.message || 'Error al agregar miembro');
        } finally {
            setLoading(false);
        }
    };

    const handleRemoveMember = async (memberId) => {
        console.log('[MEMBER-DEBUG] handleRemoveMember triggered for:', memberId);
        // Instead of confirm, we set the state to show the inline UI
        setMemberToRemove(memberId);
    };

    const confirmRemoveMember = async () => {
        if (!memberToRemove) return;
        const memberId = memberToRemove;
        console.log('[MEMBER-DEBUG] confirmRemoveMember ACCEPTED for:', memberId);

        setLoading(true);
        try {
            const url = `/api/Projects/${project.id}/members/${memberId}?requestingUserId=${userData.userId}`;
            console.log('[MEMBER-DEBUG] Sending DELETE request to:', url);
            const response = await api.delete(url);
            console.log('[MEMBER-DEBUG] Remove member response:', response.data);
            await fetchDetails();
            onUpdate?.();
        } catch (err) {
            console.error('[MEMBER-DEBUG] Error removing member:', err);
            setError(err.response?.data?.message || 'Error al eliminar miembro');
        } finally {
            setLoading(false);
            setMemberToRemove(null);
        }
    };

    const handleVisibilityToggle = async () => {
        const newStatus = !project.esPublico;
        // Optimistic UI update
        setProject(prev => ({ ...prev, esPublico: newStatus }));

        try {
            await api.put(`/api/projects/${project.id}`, {
                titulo: project.titulo,
                videoUrl: project.videoUrl,
                canvasBlocks: project.canvasBlocks || project.canvas, // Send current blocks to avoid data loss
                esPublico: newStatus
            });
            await onUpdate?.(); // Refresh list to reflect changes
        } catch (err) {
            console.error('Error updating visibility:', err);
            // Revert on error
            setProject(prev => ({ ...prev, esPublico: !newStatus }));
            alert('Error al cambiar la visibilidad del proyecto');
        }
    };

    const handleUpdateTitle = async () => {
        if (!editTitle || editTitle === project.titulo) return;

        try {
            await api.put(`/api/projects/${project.id}`, {
                titulo: editTitle,
                videoUrl: project.videoUrl,
                canvasBlocks: project.canvasBlocks || project.canvas,
                esPublico: project.esPublico
            });
            setProject(prev => ({ ...prev, titulo: editTitle }));
            await onUpdate?.();
            alert('Título actualizado correctamente');
        } catch (err) {
            console.error('Error updating title:', err);
            alert('Error al actualizar el título');
        }
    };
    const handleDeleteProject = async () => {
        console.log('[DELETE-DEBUG] handleDeleteProject triggered - Using Custom Modal UI');
        setDeleteStep(1); // Show first confirmation
    };

    const proceedToDeleteStep2 = () => {
        console.log('[DELETE-DEBUG] First confirmation ACCEPTED (via UI)');
        setDeleteStep(2); // Show input confirmation
    };

    const executeFinalDelete = async () => {
        if (deleteInput !== 'ELIMINAR') {
            console.log('[DELETE-DEBUG] Execution blocked: Input was', deleteInput);
            if (deleteInput !== null) alert('Para eliminar el proyecto debes escribir exactamente "ELIMINAR"');
            return;
        }
        console.log('[DELETE-DEBUG] Final confirmation ACCEPTED. Proceeding with deletion...');

        setIsDeleting(true);
        try {
            const url = `/api/Projects/${project.id}?requestingUserId=${userData.userId}`;
            console.log('[DELETE-DEBUG] Sending DELETE request to:', url);
            
            const response = await api.delete(url);
            console.log('[DELETE-DEBUG] Delete response received:', response.data);
            
            alert('Proyecto eliminado exitosamente');
            onUpdate?.();
            onClose(); 
        } catch (err) {
            console.error('[DELETE-DEBUG] Error deleting project:', err);
            const errorMsg = err.response?.data?.message || err.response?.data || err.message;
            alert('Error al eliminar el proyecto: ' + errorMsg);
        } finally {
            setIsDeleting(false);
            setDeleteStep(0);
            setDeleteInput('');
            console.log('[DELETE-DEBUG] Deletion process finished');
        }
    };

    if (!project) return <div>Cargando...</div>;

    // Leader Name Resolution
    const leader = project?.members?.find(m => m.id === project.liderId);
    const creadorNombre = leader
        ? (leader.nombre !== 'Usuario' ? leader.nombre : leader.email)
        : (project?.liderNombre || 'Desconocido');

    // Gather Media Items
    const mediaItems = [];
    if (project.videoUrl && project.videoUrl.trim() !== '' && project.videoUrl !== 'null') {
        mediaItems.push({ type: 'video', url: project.videoUrl, thumbnail: project.thumbnailUrl });
    }
    if (project.thumbnailUrl && project.thumbnailUrl.trim() !== '' && project.thumbnailUrl !== 'null' && !mediaItems.some(item => item.url === project.thumbnailUrl)) {
        mediaItems.push({ type: 'image', url: project.thumbnailUrl });
    }
    if (project.canvas) {
        const canvasImages = project.canvas
            .filter(b => b.type === 'image' && b.content && b.content !== project.thumbnailUrl)
            .map(b => ({ type: 'image', url: b.content }));
        mediaItems.push(...canvasImages);
    }
    if (mediaItems.length === 0) mediaItems.push({ type: 'placeholder' });

    const currentMedia = mediaItems[currentSlide] || mediaItems[0];

    const nextSlide = (e) => {
        e.stopPropagation();
        setCurrentSlide((prev) => (prev + 1) % mediaItems.length);
        setIsPlaying(false);
    };

    const prevSlide = (e) => {
        e.stopPropagation();
        setCurrentSlide((prev) => (prev - 1 + mediaItems.length) % mediaItems.length);
        setIsPlaying(false);
    };

    return (
        <div className="flex flex-col h-full overflow-hidden relative">
            {/* Master-Detail Layout — Immersive, no outer padding */}
            <div className="flex flex-col lg:flex-row flex-1 overflow-hidden bg-black relative z-10">

                {/* Left Column: Media Carousel */}
                <motion.div
                    initial={false}
                    animate={{ width: readMode ? '0%' : '66%', opacity: readMode ? 0 : 1 }}
                    transition={{ duration: 0.35, ease: 'easeInOut' }}
                    className="relative bg-black flex-col items-center justify-center p-0 group overflow-hidden hidden lg:flex shrink-0"
                    style={{ minWidth: readMode ? 0 : undefined }}
                    onMouseEnter={() => {
                        if (currentMedia?.type === 'video') {
                            setIsPlaying(true);
                            videoRef.current?.play().catch(() => { });
                        }
                    }}
                    onMouseLeave={() => {
                        if (currentMedia?.type === 'video') {
                            setIsPlaying(false);
                            videoRef.current?.pause();
                        }
                    }}
                >
                    <div className="w-full h-full relative flex items-center justify-center overflow-hidden">
                        {/* 🌟 EFECTO CINE BACKGROUND 🌟 */}
                        {currentMedia.type === 'video' ? (
                            <video
                                src={currentMedia.url}
                                muted
                                loop
                                playsInline
                                autoPlay
                                className="absolute inset-0 w-full h-full object-cover scale-150 opacity-40 blur-[60px] z-0 pointer-events-none"
                            />
                        ) : currentMedia.type === 'image' ? (
                            <img
                                src={currentMedia.url}
                                alt=""
                                className="absolute inset-0 w-full h-full object-cover scale-150 opacity-40 blur-[60px] z-0 pointer-events-none"
                            />
                        ) : null}

                        {/* FOREGROUND MEDIA - Mantiene object-contain sin recortar */}
                        <div className="relative z-10 w-full h-full flex items-center justify-center">
                            {currentMedia.type === 'video' ? (
                                <div
                                    className="w-full h-full relative flex items-center justify-center cursor-pointer"
                                    title="Clic para ampliar"
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        setIsLightboxOpen(true);
                                    }}
                                >
                                    <video
                                        ref={videoRef}
                                        src={currentMedia.url}
                                        loop
                                        muted
                                        playsInline
                                        className={`w-full h-full object-contain transition-opacity duration-500 drop-shadow-2xl ${isPlaying ? 'opacity-100' : 'opacity-80'}`}
                                    />

                                    {!isPlaying && (
                                        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                                            <div className="w-20 h-20 bg-black/40 backdrop-blur-md rounded-full flex items-center justify-center border border-white/30 shadow-xl transition-all duration-300 group-hover:scale-110">
                                                <Play fill="white" className="text-white ml-1" size={40} />
                                            </div>
                                        </div>
                                    )}

                                    <span className="absolute bottom-6 left-6 px-3 py-1.5 bg-black/70 backdrop-blur-md rounded-md text-white text-xs font-bold uppercase tracking-wider border border-white/20 shadow-lg pointer-events-none z-10">
                                        Video Pitch
                                    </span>
                                </div>
                            ) : currentMedia.type === 'image' ? (
                                <div
                                    className="w-full h-full flex items-center justify-center cursor-pointer p-4"
                                    title="Clic para ampliar"
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        setIsLightboxOpen(true);
                                    }}
                                >
                                    <img
                                        src={currentMedia.url}
                                        alt={project.titulo}
                                        className="w-full h-full object-contain drop-shadow-2xl"
                                    />
                                </div>
                            ) : (
                                <div className="flex flex-col items-center justify-center text-gray-500 bg-black/50 backdrop-blur-md w-full h-full">
                                    <ImageIcon size={64} className="mb-4 opacity-50" />
                                    <span className="text-sm font-medium">Sin contenido visual</span>
                                </div>
                            )}
                        </div>

                        {/* Carousel Controls */}
                        {mediaItems.length > 1 && (
                            <>
                                <button
                                    onClick={prevSlide}
                                    className="absolute left-4 top-1/2 -translate-y-1/2 p-3 bg-black/50 backdrop-blur-md text-white rounded-full hover:bg-black/80 hover:scale-110 transition-all opacity-0 group-hover:opacity-100 z-30 shadow-lg cursor-pointer border border-white/10"
                                >
                                    <ChevronLeft size={24} />
                                </button>
                                <button
                                    onClick={nextSlide}
                                    className="absolute right-4 top-1/2 -translate-y-1/2 p-3 bg-black/50 backdrop-blur-md text-white rounded-full hover:bg-black/80 hover:scale-110 transition-all opacity-0 group-hover:opacity-100 z-30 shadow-lg cursor-pointer border border-white/10"
                                >
                                    <ChevronRight size={24} />
                                </button>

                                {/* Dots Indicator */}
                                <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-2 z-30 bg-black/40 backdrop-blur-md px-4 py-2 rounded-full border border-white/10">
                                    {mediaItems.map((_, idx) => (
                                        <div
                                            key={idx}
                                            className={`transition-all duration-300 rounded-full shadow-sm cursor-pointer ${idx === currentSlide ? 'bg-white w-2.5 h-2.5' : 'bg-white/40 w-2 h-2 hover:bg-white/70'}`}
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                setCurrentSlide(idx);
                                            }}
                                        />
                                    ))}
                                </div>
                            </>
                        )}
                    </div>
                </motion.div>

                {/* Right Column: Info & Content */}
                <div className="flex-1 min-w-0 flex flex-col overflow-hidden bg-white dark:bg-[#1a1d27] border-l border-slate-200 dark:border-slate-700/50 relative">
                    {/* --- Botón Cerrar Minimalista (Estilo Instagram) --- */}
                    <button
                        onClick={onClose}
                        className="absolute top-4 right-4 z-[100] w-10 h-10 flex items-center justify-center text-gray-500 hover:text-gray-700 dark:text-slate-400 dark:hover:text-white transition-all rounded-full hover:bg-gray-100/50 dark:hover:bg-slate-800/50 group/close"
                        title="Cerrar"
                    >
                        <X size={24} strokeWidth={2.2} className="group-hover/close:rotate-90 transition-transform duration-300" />
                    </button>

                    {/* Integrated Header */}
                    <div className="px-6 pt-5 pb-0 shrink-0 border-b border-gray-100 dark:border-slate-700/50">
                        {/* Title row */}
                        <div className="flex items-start justify-between gap-3 mb-3">
                            <div className="flex-1 min-w-0">
                                <div className="flex items-center gap-3 flex-wrap">
                                    <h2 className="text-xl font-bold text-gray-900 dark:text-white tracking-tight truncate leading-tight">
                                        {project.titulo}
                                    </h2>
                                </div>
                            </div>
                            {/* Action buttons */}
                            <div className="flex items-center gap-1.5 shrink-0 pr-10">
                                <ProjectPDFExportButton project={project} creadorNombre={creadorNombre} />
                                <button
                                    onClick={() => setReadMode(r => !r)}
                                    title={readMode ? 'Ver multimedia' : 'Modo lectura'}
                                    className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 dark:text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-all"
                                >
                                    {readMode ? <Minimize2 size={18} /> : <Maximize2 size={18} />}
                                </button>
                            </div>
                        </div>

                        {/* Tabs */}
                        <div className="flex justify-between items-center pb-0">
                            <div className="flex gap-4">
                                <button
                                    onClick={() => setActiveTab('docs')}
                                    className={`text-sm font-bold transition-all relative pb-1 ${activeTab === 'docs'
                                        ? 'text-blue-600'
                                        : 'text-gray-400 dark:text-slate-500 hover:text-gray-600 dark:hover:text-slate-300'
                                        }`}
                                >
                                    Info
                                    {activeTab === 'docs' && (
                                        <span className="absolute bottom-0 left-0 w-full h-[2px] bg-blue-600 rounded-full"></span>
                                    )}
                                </button>
                                <button
                                    onClick={() => setActiveTab('eval')}
                                    className={`text-sm font-bold transition-all relative pb-1 ${activeTab === 'eval'
                                        ? 'text-blue-600'
                                        : 'text-gray-400 dark:text-slate-500 hover:text-gray-600 dark:hover:text-slate-300'
                                        }`}
                                >
                                    Evaluación
                                    {activeTab === 'eval' && (
                                        <span className="absolute bottom-0 left-0 w-full h-[2px] bg-blue-600 rounded-full"></span>
                                    )}
                                </button>
                                {canSeeSettings && (
                                    <button
                                        onClick={() => setActiveTab('settings')}
                                        className={`text-sm font-bold transition-all relative pb-1 ${activeTab === 'settings'
                                            ? 'text-blue-600'
                                            : 'text-gray-400 dark:text-slate-500 hover:text-gray-600 dark:hover:text-slate-300'
                                            }`}
                                    >
                                        Ajustes
                                        {activeTab === 'settings' && (
                                            <span className="absolute bottom-0 left-0 w-full h-[2px] bg-blue-600 rounded-full"></span>
                                        )}
                                    </button>
                                )}
                            </div>

                            {/* Edit Button (only visible in docs tab for members/leader) */}
                            <div className="flex gap-2">
                                {(isLeader || (project.members || []).some(m => m.id === userData.userId)) && activeTab === 'docs' && (
                                    <button
                                        onClick={() => window.open(`/project/${project.id}/editor`, '_self')}
                                        className="px-4 py-1.5 rounded-full font-bold text-xs text-blue-600 bg-blue-50 dark:bg-blue-900/30 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-900/50 transition-all flex items-center justify-center gap-1.5"
                                    >
                                        <ExternalLink size={14} />
                                        Editar Docs
                                    </button>
                                )}
                            </div>
                        </div>
                    </div>{/* End Integrated Header */}

                    {/* Scrollable Content */}
                    <div className={`flex-1 overflow-y-auto custom-scrollbar ${readMode ? 'px-10 py-8 lg:px-20' : 'p-6'}`}>

                        {/* Always visible Info header when on docs tab (like Instagram caption) */}
                        {activeTab === 'docs' && (
                            <div className="mb-8 space-y-6">
                                {/* Leader/Team Meta */}
                                    <div className="flex items-center gap-3">
                                        <Link to={`/profile/${project.liderId}`} className="w-10 h-10 rounded-full bg-gradient-to-tr from-blue-500 to-purple-500 flex items-center justify-center border-2 border-white shadow-sm text-white overflow-hidden hover:ring-2 hover:ring-blue-500 transition-all shrink-0" title="Ver perfil">
                                            <UserAvatar src={leader?.fotoUrl || leader?.FotoUrl} name={creadorNombre} size="md" className="w-full h-full" />
                                        </Link>
                                        <div>
                                            <Link to={`/profile/${project.liderId}`} className="hover:text-blue-600 transition-colors">
                                                <p className="text-sm font-bold text-gray-900 dark:text-white leading-tight">
                                                    {creadorNombre}
                                                </p>
                                            </Link>
                                            <div className="flex items-center gap-2 mt-0.5">
                                                <p className="text-[11px] font-medium text-gray-500 dark:text-slate-400 uppercase tracking-wide flex items-center gap-2">
                                                    <span>Ciclo {project.ciclo} • {project.materia}</span>
                                                </p>
                                                <span className="text-gray-300 dark:text-slate-600">•</span>
                                                {isLeader ? (
                                                    <button
                                                        onClick={handleVisibilityToggle}
                                                        className={`px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider transition-all flex items-center gap-1 ${project.esPublico
                                                            ? 'bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-400 hover:bg-green-100'
                                                            : 'bg-gray-100 text-gray-500 dark:bg-slate-800 dark:text-slate-400 hover:bg-gray-200'
                                                            }`}
                                                        title={project.esPublico ? 'Click para hacer privado' : 'Click para hacer público'}
                                                    >
                                                        {project.esPublico ? '🌍 Público' : '🔒 Privado'}
                                                    </button>
                                                ) : (
                                                    <span className={`px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider flex items-center gap-1 ${project.esPublico ? 'text-green-600 dark:text-green-400' : 'text-gray-400 dark:text-slate-500'}`}>
                                                        {project.esPublico ? '🌍 Público' : '🔒 Privado'}
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    </div>

                                {/* Text Content from Canvas Editor */}
                                <div className={`prose max-w-none text-gray-800 dark:text-slate-300 dark:prose-invert ${readMode ? 'prose-base lg:prose-lg' : 'prose-sm'}`}>
                                    <CanvasEditor
                                        key={`canvas-editor-${fetchingDetails ? 'loading' : 'loaded'}`}
                                        project={project}
                                        readOnly={true}
                                        mode="text"
                                    />
                                </div>

                                {/* Squad Divider */}
                                <div className="border-t border-gray-100 dark:border-slate-700/50 pt-6 mt-6">
                                    <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                                        <Users size={16} className="text-gray-400" />
                                        Squad ({project.miembrosIds?.length || 0}/5)
                                    </h3>

                                    {/* Add Member Combobox */}
                                    {isLeader && (
                                        <form onSubmit={handleAddMember} className="mb-4 relative">
                                            <div className="bg-gray-50 dark:bg-slate-800 border border-gray-100 dark:border-slate-700 rounded-xl p-1.5 flex items-center gap-2">
                                                <div className="relative flex-1">
                                                    <input
                                                        type="text"
                                                        value={newMemberEmail}
                                                        onChange={(e) => {
                                                            setNewMemberEmail(e.target.value);
                                                            setShowSuggestions(true);
                                                        }}
                                                        onFocus={() => setShowSuggestions(true)}
                                                        onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
                                                        placeholder="Buscar por matrícula o nombre..."
                                                        className="w-full bg-transparent px-3 py-1 outline-none text-sm font-medium text-gray-800 dark:text-white placeholder-gray-400 dark:placeholder-slate-500"
                                                        disabled={loading || fetchingStudents}
                                                    />

                                                    {/* Suggestions Dropdown */}
                                                    {showSuggestions && newMemberEmail && (
                                                        <div className="absolute z-50 top-full left-0 right-0 mt-2 bg-white dark:bg-[#1a1d27] rounded-xl border border-gray-100 dark:border-slate-700 shadow-xl overflow-hidden max-h-60 overflow-y-auto custom-scrollbar">
                                                            {fetchingStudents ? (
                                                                <div className="p-4 text-center text-xs text-gray-500">Cargando compañeros...</div>
                                                            ) : availableStudents.filter(s =>
                                                            (s.nombreCompleto?.toLowerCase().includes(newMemberEmail.toLowerCase()) ||
                                                                s.matricula?.toLowerCase().includes(newMemberEmail.toLowerCase()) ||
                                                                s.email?.toLowerCase().includes(newMemberEmail.toLowerCase()))
                                                            ).length > 0 ? (
                                                                availableStudents.filter(s =>
                                                                (s.nombreCompleto?.toLowerCase().includes(newMemberEmail.toLowerCase()) ||
                                                                    s.matricula?.toLowerCase().includes(newMemberEmail.toLowerCase()) ||
                                                                    s.email?.toLowerCase().includes(newMemberEmail.toLowerCase()))
                                                                ).map(student => (
                                                                    <div
                                                                        key={student.id}
                                                                        onClick={() => {
                                                                            setNewMemberEmail(student.matricula || student.email);
                                                                            setShowSuggestions(false);
                                                                        }}
                                                                        className="flex items-center gap-3 p-3 hover:bg-gray-50 dark:hover:bg-slate-800 cursor-pointer border-b border-gray-50 dark:border-slate-700/50 last:border-0 transition-colors"
                                                                    >
                                                                        <UserAvatar src={student.fotoUrl || student.FotoUrl} name={student.nombreCompleto || 'U'} size="sm" className="bg-gradient-to-tr from-blue-100 to-purple-100 text-blue-600 shrink-0" />
                                                                        <div className="flex-1 min-w-0">
                                                                            <p className="text-sm font-bold text-gray-800 dark:text-white truncate">
                                                                                {student.nombreCompleto && student.nombreCompleto.trim() !== '' ? student.nombreCompleto : (student.email || 'Estudiante')}
                                                                            </p>
                                                                            <p className="text-[11px] font-medium text-gray-400 truncate uppercase mt-0.5">
                                                                                {student.matricula || student.email}
                                                                            </p>
                                                                        </div>
                                                                        <UserPlus size={14} className="text-gray-300" />
                                                                    </div>
                                                                ))
                                                            ) : (
                                                                <div className="p-4 text-center text-xs text-gray-500">No se encontraron compañeros disponibles.</div>
                                                            )}
                                                        </div>
                                                    )}
                                                </div>
                                                <button
                                                    type="submit"
                                                    disabled={loading || !newMemberEmail}
                                                    className="px-3 py-1.5 rounded-lg bg-blue-600 text-white text-xs font-bold shadow-sm hover:bg-blue-700 disabled:opacity-50 transition-colors"
                                                >
                                                    Agregar
                                                </button>
                                            </div>
                                            {error && <p className="text-xs text-red-500 mt-2 ml-2 font-medium">{error}</p>}
                                        </form>
                                    )}

                                    {/* Members List */}
                                    <div className="space-y-2">
                                        {fetchingDetails ? (
                                            <div className="space-y-2">
                                                {[1, 2, 3].map(i => <div key={i} className="h-12 bg-gray-50 dark:bg-slate-800 rounded-xl animate-pulse" />)}
                                            </div>
                                        ) : (
                                            (project.members || []).length > 0 ? (
                                                (project.members || []).map((member, idx) => (
                                                    <motion.div
                                                        key={member.id || idx}
                                                        initial={{ opacity: 0, y: 5 }}
                                                        animate={{ opacity: 1, y: 0 }}
                                                        transition={{ delay: idx * 0.05 }}
                                                        className="p-2 rounded-xl hover:bg-gray-50 dark:hover:bg-slate-800 flex items-center justify-between group transition-colors"
                                                    >
                                                        <div className="flex items-center gap-3">
                                                            <Link to={`/profile/${member.id}`} className="shrink-0 rounded-full hover:ring-2 hover:ring-blue-500 transition-all" title="Ver perfil">
                                                                <UserAvatar src={member.fotoUrl || member.FotoUrl} name={member.nombre || 'U'} size="sm" className="bg-gray-200" />
                                                            </Link>
                                                            <div>
                                                                <Link to={`/profile/${member.id}`} className="hover:text-blue-600 transition-colors">
                                                                    <p className="text-sm font-bold text-gray-800 dark:text-white leading-none">
                                                                        {(member.nombre && member.nombre !== 'Usuario') ? member.nombre : (member.email || 'Miembro')}
                                                                    </p>
                                                                </Link>
                                                                <p className="text-[10px] uppercase font-bold text-gray-400 dark:text-slate-500 mt-1 leading-none">{member.rol || 'Miembro'}</p>
                                                            </div>
                                                        </div>

                                                        {member.id === project.liderId ? (
                                                            <span className="text-[10px] font-bold bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 px-2 py-1 rounded-md">Líder</span>
                                                        ) : (
                                                            (isLeader || userData?.userId === member.id) && (
                                                                <div className="flex items-center gap-1.5">
                                                                    {memberToRemove === member.id ? (
                                                                        <>
                                                                            <button
                                                                                onClick={() => confirmRemoveMember()}
                                                                                disabled={loading}
                                                                                className="px-2 py-1 bg-red-500 text-white text-[10px] font-bold rounded hover:bg-red-600 transition-colors"
                                                                            >
                                                                                Confirmar
                                                                            </button>
                                                                            <button
                                                                                onClick={() => setMemberToRemove(null)}
                                                                                className="px-2 py-1 bg-gray-200 dark:bg-slate-700 text-gray-700 dark:text-gray-300 text-[10px] font-bold rounded hover:bg-gray-300 transition-colors"
                                                                            >
                                                                                X
                                                                            </button>
                                                                        </>
                                                                    ) : (
                                                                        <button
                                                                            onClick={() => handleRemoveMember(member.id)}
                                                                            className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-md transition-colors opacity-0 group-hover:opacity-100"
                                                                        >
                                                                            <Trash2 size={14} />
                                                                        </button>
                                                                    )}
                                                                </div>
                                                            )
                                                        )}
                                                    </motion.div>
                                                ))
                                            ) : (
                                                <p className="text-xs text-gray-400 text-center py-2">No hay miembros aún.</p>
                                            )
                                        )}
                                    </div>
                                    <p className="text-[10px] text-gray-400 dark:text-slate-500 uppercase tracking-widest mt-8 pt-4 border-t border-gray-50 dark:border-slate-800/30">
                                        {(() => {
                                            if (!project.createdAt) return null;
                                            const date = project.createdAt.seconds ? new Date(project.createdAt.seconds * 1000) : new Date(project.createdAt);
                                            return isNaN(date.getTime()) ? null : date.toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' }).toUpperCase();
                                        })()}
                                    </p>
                                </div>
                            </div>
                        )}

                        {activeTab === 'eval' && (
                            <div className="p-6 max-w-4xl mx-auto pb-20 animate-fadeIn">
                                <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                                    <Activity size={20} className="text-blue-500" />
                                    Evaluación y Rúbrica
                                </h3>
                                <EvaluationPanel projectId={project.id} />
                            </div>
                        )}

                        {activeTab === 'settings' && canSeeSettings && (
                            <div className="p-6 max-w-4xl mx-auto pb-20 space-y-6 animate-fadeIn">
                                <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                                    <Hash size={20} className="text-blue-500" />
                                    Ajustes del Proyecto
                                </h3>

                                {/* Edit Title - Solo para el líder */}
                                {isLeader && (
                                    <>
                                        <div className="space-y-2">
                                            <label className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase">Título del Proyecto</label>
                                            <div className="flex gap-2">
                                                <input
                                                    type="text"
                                                    value={editTitle}
                                                    onChange={(e) => setEditTitle(e.target.value)}
                                                    className="flex-1 px-3 py-2 text-sm bg-gray-50 dark:bg-slate-800 dark:text-white border border-gray-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-100 dark:focus:ring-slate-600 focus:border-blue-400 dark:focus:border-slate-500 outline-none transition-all"
                                                />
                                                <button
                                                    onClick={handleUpdateTitle}
                                                    disabled={!editTitle || editTitle === project.titulo}
                                                    className="px-4 py-2 bg-gray-900 text-white rounded-lg text-sm font-bold hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                                                >
                                                    Guardar
                                                </button>
                                            </div>
                                        </div>

                                        {/* Visibility Toggle */}
                                        <div className="space-y-2 pt-4 border-t border-gray-100 dark:border-slate-700/50">
                                            <label className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase">Visibilidad</label>
                                            <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-slate-800 rounded-xl border border-gray-100 dark:border-slate-700">
                                                <div>
                                                    <p className="text-sm font-bold text-gray-900 dark:text-white">{project.esPublico ? 'Público' : 'Privado'}</p>
                                                    <p className="text-[11px] text-gray-500 dark:text-slate-400 mt-0.5 max-w-[200px]">
                                                        {project.esPublico
                                                            ? 'Visible en la galería general.'
                                                            : 'Solo visible para el equipo y profesores.'}
                                                    </p>
                                                </div>
                                                <button
                                                    onClick={handleVisibilityToggle}
                                                    className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${project.esPublico
                                                        ? 'bg-green-100 text-green-700 hover:bg-green-200'
                                                        : 'bg-white dark:bg-slate-700 border border-gray-200 dark:border-slate-600 text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-600'
                                                        }`}
                                                >
                                                    {project.esPublico ? 'Hacer Privado' : 'Hacer Público'}
                                                </button>
                                            </div>
                                        </div>
                                    </>
                                )}

                                {/* Danger Zone */}
                                <div className="pt-6 mt-6 border-t border-red-100">
                                    <h4 className="text-xs font-bold text-red-500 uppercase mb-3 flex items-center gap-1.5">
                                        <Trash2 size={14} /> Zona de Peligro
                                    </h4>
                                    <div className="p-3 bg-red-50 dark:bg-red-900/10 rounded-xl border border-red-100 dark:border-red-900/20 flex flex-col gap-3">
                                        <div>
                                            <p className="text-sm font-bold text-red-700">Eliminar Proyecto</p>
                                            <p className="text-[11px] text-red-500/80 mt-0.5">
                                                Acción irreversible. Eliminará contenido y liberará al equipo.
                                            </p>
                                        </div>

                                        {deleteStep === 0 && (
                                            <button
                                                onClick={handleDeleteProject}
                                                className="w-full py-2 bg-white dark:bg-slate-800 border border-red-200 dark:border-red-900/30 text-red-600 rounded-lg text-sm font-bold hover:bg-red-600 hover:text-white hover:border-red-600 transition-all shadow-sm"
                                            >
                                                Eliminar Definitivamente
                                            </button>
                                        )}

                                        {deleteStep === 1 && (
                                            <div className="space-y-3 animate-fadeIn">
                                                <p className="text-xs font-bold text-red-600 bg-red-100 p-2 rounded-lg text-center">
                                                    ⚠️ ¿ESTÁS SEGURO? Esta acción no se puede deshacer.
                                                </p>
                                                <div className="flex gap-2">
                                                    <button
                                                        onClick={proceedToDeleteStep2}
                                                        className="flex-1 py-1.5 bg-red-600 text-white rounded-lg text-xs font-bold hover:bg-red-700 transition-all"
                                                    >
                                                        Sí, continuar
                                                    </button>
                                                    <button
                                                        onClick={() => setDeleteStep(0)}
                                                        className="flex-1 py-1.5 bg-gray-200 dark:bg-slate-700 text-gray-700 dark:text-gray-300 rounded-lg text-xs font-bold hover:bg-gray-300 dark:hover:bg-slate-600 transition-all"
                                                    >
                                                        Cancelar
                                                    </button>
                                                </div>
                                            </div>
                                        )}

                                        {deleteStep === 2 && (
                                            <div className="space-y-3 animate-fadeIn">
                                                <div className="space-y-1">
                                                    <label className="text-[10px] font-bold text-red-600 uppercase">Escribe "ELIMINAR" para confirmar</label>
                                                    <input
                                                        type="text"
                                                        value={deleteInput}
                                                        onChange={(e) => setDeleteInput(e.target.value)}
                                                        placeholder="ELIMINAR"
                                                        className="w-full px-3 py-2 bg-white dark:bg-slate-800 border border-red-200 dark:border-slate-700 rounded-lg text-sm text-gray-900 dark:text-white focus:ring-2 focus:ring-red-500 outline-none placeholder-gray-400 dark:placeholder-slate-500"
                                                    />
                                                </div>
                                                <div className="flex gap-2">
                                                    <button
                                                        onClick={executeFinalDelete}
                                                        disabled={deleteInput !== 'ELIMINAR' || isDeleting}
                                                        className="flex-1 py-1.5 bg-red-600 text-white rounded-lg text-xs font-bold hover:bg-red-700 transition-all disabled:opacity-50 disabled:bg-gray-400"
                                                    >
                                                        {isDeleting ? 'Eliminando...' : 'CONFIRMAR ELIMINACIÓN'}
                                                    </button>
                                                    <button
                                                        onClick={() => {
                                                            setDeleteStep(0);
                                                            setDeleteInput('');
                                                        }}
                                                        disabled={isDeleting}
                                                        className="flex-1 py-1.5 bg-gray-200 dark:bg-slate-700 text-gray-700 dark:text-gray-300 rounded-lg text-xs font-bold hover:bg-gray-300 dark:hover:bg-slate-600 transition-all"
                                                    >
                                                        Cancelar
                                                    </button>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>

                {/* --- LIGHTBOX OVERLAY --- */}
                {isLightboxOpen && createPortal(
                    <div
                        className="fixed inset-0 z-[9999] bg-black/95 flex items-center justify-center backdrop-blur-md group/lightbox"
                        onClick={() => setIsLightboxOpen(false)}
                    >
                        <button
                            className="absolute top-6 right-6 p-3 bg-white/10 hover:bg-white/20 rounded-full text-white transition-all z-50 cursor-pointer opacity-0 group-hover/lightbox:opacity-100 duration-300"
                            onClick={(e) => {
                                e.stopPropagation();
                                setIsLightboxOpen(false);
                            }}
                        >
                            <X size={32} />
                        </button>

                        {mediaItems.length > 1 && (
                            <>
                                <button
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        setCurrentSlide((prev) => (prev - 1 + mediaItems.length) % mediaItems.length);
                                    }}
                                    className="absolute left-6 top-1/2 -translate-y-1/2 p-4 bg-white/10 hover:bg-white/20 rounded-full text-white transition-all z-50 cursor-pointer"
                                >
                                    <ChevronLeft size={36} />
                                </button>
                                <button
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        setCurrentSlide((prev) => (prev + 1) % mediaItems.length);
                                    }}
                                    className="absolute right-6 top-1/2 -translate-y-1/2 p-4 bg-white/10 hover:bg-white/20 rounded-full text-white transition-all z-50 cursor-pointer"
                                >
                                    <ChevronRight size={36} />
                                </button>
                            </>
                        )}

                        <div className="relative w-[90vw] h-[90vh] flex items-center justify-center pointer-events-none">
                            {currentMedia.type === 'video' ? (
                                <video
                                    src={currentMedia.url}
                                    controls
                                    autoPlay
                                    className="w-full h-full object-contain drop-shadow-2xl rounded-lg pointer-events-auto"
                                />
                            ) : currentMedia.type === 'image' ? (
                                <img
                                    src={currentMedia.url}
                                    alt="Contenido Ampliado"
                                    className="w-full h-full object-contain drop-shadow-2xl rounded-lg pointer-events-auto"
                                />
                            ) : null}
                        </div>

                        {mediaItems.length > 1 && (
                            <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex gap-2 z-50 bg-black/50 px-4 py-2 rounded-full border border-white/10">
                                {mediaItems.map((_, idx) => (
                                    <div
                                        key={idx}
                                        className={`w-2 h-2 rounded-full transition-all duration-300 ${idx === currentSlide ? 'bg-white scale-125' : 'bg-white/30 cursor-pointer hover:bg-white/60'}`}
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            setCurrentSlide(idx);
                                        }}
                                    />
                                ))}
                            </div>
                        )}
                    </div>,
                    document.body
                )}
            </div>
        </div>
    );
}
