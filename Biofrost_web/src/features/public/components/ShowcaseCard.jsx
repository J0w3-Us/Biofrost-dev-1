import { useState, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Play, Users, ExternalLink, Edit, Star, ChevronLeft, ChevronRight, Image as ImageIcon, Trophy, X, Palette, Zap, Airplay, Target } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import { UserAvatar } from '../../../components/UserAvatar';
import api from '../../../lib/axios';
import { FONTS } from '../../projects/constants/editorFonts';

// Safely reads the font of the first text block in the canvas — returns undefined if none.
function getProjectTitleFont(project) {
    try {
        const TEXT_TYPES = ['text', 'h1', 'h2', 'h3', 'quote', 'bullet', 'todo'];
        const firstTextBlock = (project.canvas || []).find(b => TEXT_TYPES.includes(b.type));
        const font = firstTextBlock?.metadata?.fontFamily;
        // Validate it's one of our known fonts
        if (font && FONTS.some(f => f.value === font)) return font;
    } catch (_) { }
    return undefined;
}

export function ShowcaseCard({ project, onClick }) {
    const [isPlaying, setIsPlaying] = useState(false);
    const [currentSlide, setCurrentSlide] = useState(0);
    const { userData } = useAuth();
    const navigate = useNavigate();
    const videoRef = useRef(null);
    const lightboxVideoRef = useRef(null);
    const [isLightboxOpen, setIsLightboxOpen] = useState(false);

    // Rubric Voting State
    const CRITERIA = [
        { key: 'uiux',        label: 'UI/UX',       Icon: Palette,  color: 'indigo',  activeColor: '#6366f1', hoverBg: 'hover:bg-indigo-50 dark:hover:bg-indigo-900/20' },
        { key: 'inovacion',   label: 'Innovación',  Icon: Zap,      color: 'amber',   activeColor: '#f59e0b', hoverBg: 'hover:bg-amber-50 dark:hover:bg-amber-900/20' },
        { key: 'presentacion',label: 'Presentación',Icon: Airplay,  color: 'sky',     activeColor: '#0ea5e9', hoverBg: 'hover:bg-sky-50 dark:hover:bg-sky-900/20' },
        { key: 'impacto',     label: 'Impacto',     Icon: Target,   color: 'emerald', activeColor: '#10b981', hoverBg: 'hover:bg-emerald-50 dark:hover:bg-emerald-900/20' },
    ];

    const getInitialRubric = () => {
        if (userData?.userId && project.votantes?.[userData.userId] && typeof project.votantes[userData.userId] === 'object') {
            const v = project.votantes[userData.userId];
            return { uiux: v.ui_ux || 0, inovacion: v.inovacion || 0, presentacion: v.presentacion || 0, impacto: v.impacto || 0 };
        }
        return { uiux: 0, inovacion: 0, presentacion: 0, impacto: 0 };
    };

    const [rubric, setRubric]           = useState(getInitialRubric);
    const [hoverRubric, setHoverRubric] = useState({ uiux: 0, inovacion: 0, presentacion: 0, impacto: 0 });
    const [isVoting, setIsVoting]       = useState(false);
    const [voteSuccess, setVoteSuccess] = useState(false);
    const [activeCriteria, setActiveCriteria] = useState(null);

    const isOwner = userData?.userId === project.liderId;

    // Read font from first text block in canvas (safe, no layout changes)
    const titleFont = getProjectTitleFont(project);

    // 2. Gather Media Items (Video + Thumbnail + Canvas Images)
    const mediaItems = [];

    // Add Video Pitch if exists
    if (project.videoUrl) {
        mediaItems.push({ type: 'video', url: project.videoUrl, thumbnail: project.thumbnailUrl });
    }

    // Add Project Thumbnail (if not used as video thumb) OR just as an image
    if (project.thumbnailUrl && !mediaItems.some(item => item.url === project.thumbnailUrl)) {
        mediaItems.push({ type: 'image', url: project.thumbnailUrl });
    }

    // Add Images from Canvas
    if (project.canvas) {
        const canvasImages = project.canvas
            .filter(b => b.type === 'image' && b.content && b.content !== project.thumbnailUrl)
            .map(b => ({ type: 'image', url: b.content }));
        mediaItems.push(...canvasImages);
    }

    // Default Placeholder if empty
    if (mediaItems.length === 0) {
        mediaItems.push({ type: 'placeholder' });
    }

    const currentMedia = mediaItems[currentSlide];

    // Carousel Navigation
    const nextSlide = (e) => {
        e.stopPropagation();
        setCurrentSlide((prev) => (prev + 1) % mediaItems.length);
        setIsPlaying(false); // Stop video on slide change
    };

    const prevSlide = (e) => {
        e.stopPropagation();
        setCurrentSlide((prev) => (prev - 1 + mediaItems.length) % mediaItems.length);
        setIsPlaying(false);
    };

    // Handle Rubric Vote
    const handleRubricVote = async (e, criteriaKey, stars) => {
        e.stopPropagation();
        if (!userData) return;
        if (isOwner) return;

        const newRubric = { ...rubric, [criteriaKey]: stars };
        setRubric(newRubric);

        // Only submit if all criteria have been rated
        const allRated = Object.values(newRubric).every(v => v > 0);
        if (!allRated || isVoting) return;

        setIsVoting(true);
        try {
            await api.post(`/api/projects/${project.id}/rate`, {
                userId: userData.userId,
                uIUX: newRubric.uiux,
                inovacion: newRubric.inovacion,
                presentacion: newRubric.presentacion,
                impacto: newRubric.impacto,
            });
            setVoteSuccess(true);
            setTimeout(() => setVoteSuccess(false), 2000);
        } catch (error) {
            console.error('Error rating project:', error);
        } finally {
            setIsVoting(false);
        }
    };

    // 3. Determine Description
    const description = project.descripcion || 'Sin descripción disponible. Navega a los detalles para ver más.';

    // 4. Handle Edit Click
    const handleEditClick = (e) => {
        e.stopPropagation();
        navigate(`/project/${project.id}/editor`);
    };

    return (
        <div className="bg-white dark:bg-[#1a1d27] rounded-xl border border-gray-100 dark:border-slate-700/50 shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden flex flex-col mb-12 group group-hover:-translate-y-1 hover:ring-1 hover:ring-indigo-100 dark:hover:ring-slate-600 w-full mx-auto">

            {/* --- 1. Header: User & Status (Instagram Style Top) --- */}
            <div className="p-4 flex items-center justify-between border-b border-gray-50 dark:border-slate-700/50 bg-white dark:bg-[#1a1d27] z-10">
                <div className="flex items-center gap-3">
                    <div onClick={(e) => { e.stopPropagation(); navigate(`/profile/${project.liderId}`); }} className="cursor-pointer hover:ring-2 hover:ring-indigo-200 rounded-full transition-all shrink-0">
                        <UserAvatar src={project.liderFotoUrl} name={project.liderNombre} size="md" className="border border-indigo-50 shadow-sm" />
                    </div>
                    <div className="flex flex-col cursor-pointer hover:text-indigo-600 transition-colors" onClick={(e) => { e.stopPropagation(); navigate(`/profile/${project.liderId}`); }}>
                        <h4 className="text-sm font-bold leading-none truncate max-w-[180px] dark:text-white" title={project.liderNombre}>
                            {project.liderNombre || 'Desconocido'}
                        </h4>
                        <span className="text-[11px] text-gray-400 mt-1 font-medium">
                            {new Date(project.createdAt).toLocaleDateString()}
                        </span>
                    </div>
                </div>

                <div className="flex items-center gap-2">
                    {/* Status Badge */}
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${project.estado === 'Completado' ? 'bg-green-50 text-green-700 border border-green-200/50' :
                        project.estado === 'Activo' ? 'bg-blue-50 text-blue-700 border border-blue-200/50' :
                            'bg-gray-50 text-gray-500 border border-gray-200/50'
                        }`}>
                        {project.estado}
                    </span>

                    {isOwner && (
                        <button
                            onClick={handleEditClick}
                            className="p-1.5 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-full transition-all"
                            title="Editar Proyecto"
                        >
                            <Edit size={16} />
                        </button>
                    )}
                </div>
            </div>

            {/* --- 2. Media Area (Adapted with Efecto Cine) --- */}
            <div
                className="w-full bg-black relative flex items-center justify-center overflow-hidden min-h-[300px] max-h-[85vh] group/media"
                onMouseEnter={() => {
                    if (currentMedia.type === 'video') {
                        setIsPlaying(true);
                        videoRef.current?.play().catch(() => { });
                    }
                }}
                onMouseLeave={() => {
                    if (currentMedia.type === 'video') {
                        setIsPlaying(false);
                        videoRef.current?.pause();
                    }
                }}
            >
                {/* Fondo Difuminado (Efecto Cine) */}
                {currentMedia.url && currentMedia.type !== 'placeholder' && (
                    currentMedia.type === 'video' ? (
                        <video
                            src={currentMedia.url}
                            className="absolute inset-0 w-full h-full object-cover scale-[1.2] opacity-40 blur-[50px] z-0 pointer-events-none"
                            autoPlay
                            muted
                            loop
                            playsInline
                        />
                    ) : (
                        <img
                            src={currentMedia.url}
                            className="absolute inset-0 w-full h-full object-cover scale-[1.2] opacity-40 blur-[50px] z-0 pointer-events-none filter"
                            alt=""
                        />
                    )
                )}

                {/* Media Content */}
                {currentMedia.type === 'video' ? (
                    <div
                        className="w-full relative z-10 flex items-center justify-center cursor-pointer bg-transparent"
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
                            className={`w-full max-h-[85vh] object-contain transition-opacity duration-500 ${isPlaying ? 'opacity-100' : 'opacity-70'}`}
                        />

                        {/* Play Overlay (Only visible when paused) */}
                        {!isPlaying && (
                            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                                <div className="w-16 h-16 bg-black/40 backdrop-blur-md rounded-full flex items-center justify-center border border-white/30 shadow-xl transition-all duration-300">
                                    <Play fill="white" className="text-white ml-1" size={32} />
                                </div>
                            </div>
                        )}

                        <span className="absolute bottom-4 left-4 px-2.5 py-1 bg-black/70 backdrop-blur-md rounded-md text-white text-[10px] font-bold uppercase tracking-wider border border-white/20 shadow-lg pointer-events-none z-10">
                            Video Pitch
                        </span>
                    </div>
                ) : currentMedia.type === 'image' ? (
                    <div
                        className="w-full relative z-10 flex items-center justify-center cursor-pointer group/img bg-transparent"
                        title="Clic para ampliar"
                        onClick={(e) => {
                            e.stopPropagation();
                            setIsLightboxOpen(true);
                        }}
                    >
                        <img
                            src={currentMedia.url}
                            alt={project.titulo}
                            className="w-full max-h-[85vh] object-contain drop-shadow-xl"
                        />
                    </div>
                ) : (
                    // Placeholder
                    <div className="flex flex-col items-center justify-center text-gray-500">
                        <ImageIcon size={48} className="mb-2 opacity-50" />
                        <span className="text-xs font-medium">Sin contenido visual</span>
                    </div>
                )}

                {/* Carousel Controls (Only if multiple items) */}
                {mediaItems.length > 1 && (
                    <>
                        <button
                            onClick={prevSlide}
                            className="absolute left-3 top-1/2 -translate-y-1/2 p-2 bg-black/40 backdrop-blur-md text-white rounded-full hover:bg-black/70 hover:scale-110 transition-all opacity-0 group-hover:opacity-100 z-30 shadow-lg cursor-pointer"
                        >
                            <ChevronLeft size={20} />
                        </button>
                        <button
                            onClick={nextSlide}
                            className="absolute right-3 top-1/2 -translate-y-1/2 p-2 bg-black/40 backdrop-blur-md text-white rounded-full hover:bg-black/70 hover:scale-110 transition-all opacity-0 group-hover:opacity-100 z-30 shadow-lg cursor-pointer"
                        >
                            <ChevronRight size={20} />
                        </button>

                        {/* Dots Indicator */}
                        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-1.5 z-30 bg-black/30 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/10">
                            {mediaItems.map((_, idx) => (
                                <div
                                    key={idx}
                                    className={`w-1.5 h-1.5 rounded-full shadow-sm transition-all duration-300 ${idx === currentSlide ? 'bg-white scale-125' : 'bg-white/40'}`}
                                />
                            ))}
                        </div>
                    </>
                )}

                {/* Ranking Badge (Total Points) - Absolute Top Right */}
                {project.puntosTotales > 0 && (
                    <div className="absolute top-4 right-4 z-30 bg-yellow-400/95 backdrop-blur-md text-yellow-900 px-3 py-1.5 rounded-full shadow-xl flex items-center gap-1.5 font-bold text-xs border border-yellow-300/50">
                        <Trophy size={16} fill="currentColor" />
                        <span>{project.puntosTotales} pts</span>
                    </div>
                )}
            </div>

            {/* --- 3. Body & Footer (Info Section) --- */}
            <div className="p-5 flex flex-col flex-1 bg-white dark:bg-[#1a1d27]">

                {/* Title & Description */}
                <div className="mb-4">
                    <h3
                        onClick={onClick}
                        className="text-lg font-bold text-gray-900 dark:text-white leading-snug mb-2 cursor-pointer hover:text-indigo-600 transition-colors line-clamp-1"
                        style={titleFont ? { fontFamily: titleFont } : undefined}
                    >
                        {project.titulo || 'Sin Título'}
                    </h3>
                    <p onClick={onClick} className="text-gray-600 dark:text-slate-400 text-sm leading-relaxed line-clamp-2 cursor-pointer">
                        {description}
                    </p>
                </div>

                {/* Tech Stack */}
                <div className="flex flex-wrap gap-1.5 mb-5 mt-auto">
                    {project.stackTecnologico?.slice(0, 3).map((tech, i) => (
                        <span key={i} className="px-2.5 py-1 bg-gray-50 dark:bg-slate-800 border border-gray-100 dark:border-slate-700 text-gray-600 dark:text-slate-300 text-[11px] font-semibold rounded-md shadow-sm">
                            {tech}
                        </span>
                    ))}
                    {(project.stackTecnologico?.length || 0) > 3 && (
                        <span className="px-2 py-1 text-gray-400 dark:text-slate-500 text-[11px] font-medium bg-gray-50/50 dark:bg-slate-800/50 rounded-md">
                            +{project.stackTecnologico.length - 3}
                        </span>
                    )}
                </div>

                {/* Bottom Action Row */}
                <div className="flex items-center justify-between mt-auto pt-4 border-t border-gray-50 dark:border-slate-700/50">

                    {/* Rubric Voting Panel - Only if NOT owner */}
                    <div className="flex items-center gap-3">
                        {/* Calificación oficial */}
                        {project.calificacion !== null && project.calificacion !== undefined && (
                            <div className="flex items-center gap-1.5 text-indigo-700 font-bold text-xs bg-indigo-50 px-2.5 py-1 rounded-md border border-indigo-100" title="Calificación Oficial">
                                <span>Calificación: {project.calificacion}</span>
                            </div>
                        )}

                        {!isOwner && (
                            <div className="flex items-center gap-1.5 flex-wrap" onMouseLeave={() => setHoverRubric({ uiux: 0, inovacion: 0, presentacion: 0, impacto: 0 })}>
                                {CRITERIA.map(({ key, label, Icon, activeColor, hoverBg }) => {
                                    const current = hoverRubric[key] || rubric[key];
                                    const isRated = rubric[key] > 0;
                                    const isActive = activeCriteria === key;
                                    
                                    return (
                                        <div 
                                            key={key} 
                                            className={`flex items-center transition-all duration-300 rounded-full ${
                                                isActive 
                                                    ? 'bg-white dark:bg-slate-800 shadow-sm border border-gray-200 dark:border-slate-700 pr-3 py-1 pl-1' 
                                                    : 'border border-transparent'
                                            }`}
                                        >
                                            {/* Trigger Icon */}
                                            <button
                                                onClick={(e) => { e.stopPropagation(); setActiveCriteria(isActive ? null : key); }}
                                                className={`p-1.5 rounded-full transition-all duration-200 hover:scale-110 flex items-center gap-1.5 ${hoverBg} ${isRated && !isActive ? 'scale-110' : ''}`}
                                                title={label}
                                                style={isRated || isActive ? { color: activeColor } : {}}
                                            >
                                                <Icon
                                                    size={18}
                                                    fill={isRated ? activeColor : 'none'}
                                                    stroke={isRated || isActive ? activeColor : 'currentColor'}
                                                    className={isRated || isActive ? '' : 'text-gray-400 dark:text-slate-500'}
                                                />
                                                {isActive && (
                                                    <span className="text-[10px] font-bold tracking-wider uppercase" style={{ color: activeColor }}>
                                                        {label}
                                                    </span>
                                                )}
                                            </button>

                                            {/* Estrellas Inline */}
                                            {isActive && (
                                                <div className="flex gap-0.5 items-center ml-1 border-l border-gray-100 dark:border-slate-700 pl-2 animate-fade-in">
                                                    {[1, 2, 3, 4, 5].map(star => (
                                                        <button
                                                            key={star}
                                                            onMouseEnter={() => setHoverRubric(h => ({ ...h, [key]: star }))}
                                                            onMouseLeave={() => setHoverRubric(h => ({ ...h, [key]: 0 }))}
                                                            onClick={(e) => {
                                                                handleRubricVote(e, key, star);
                                                                // Opcional: colapsar después de votar
                                                                // setTimeout(() => setActiveCriteria(null), 500); 
                                                            }}
                                                            disabled={isVoting}
                                                            className="transition-all duration-150 hover:scale-125 p-0.5"
                                                        >
                                                            <Star
                                                                size={16}
                                                                fill={current >= star ? activeColor : 'none'}
                                                                stroke={current >= star ? activeColor : '#cbd5e1'}
                                                                className="opacity-90 hover:opacity-100"
                                                            />
                                                        </button>
                                                    ))}
                                                    {rubric[key] > 0 && (
                                                        <span className="text-[10px] font-bold ml-1.5" style={{ color: activeColor }}>{rubric[key]}/5</span>
                                                    )}
                                                </div>
                                            )}
                                        </div>
                                    );
                                })}
                                {/* Éxito de voto */}
                                {voteSuccess && (
                                    <span className="text-[10px] font-bold text-emerald-500 animate-pulse ml-1">Votado ✓</span>
                                )}
                            </div>
                        )}

                    </div>

                    <button
                        onClick={onClick}
                        className="flex items-center justify-center gap-2 px-4 py-2 bg-gray-900 text-white text-sm font-semibold rounded-lg hover:bg-gray-800 transition-all shadow-sm group/btn hover:shadow-md active:scale-95"
                    >
                        Ver más
                        <ExternalLink size={14} className="group-hover/btn:translate-x-1 group-hover/btn:-translate-y-0.5 transition-transform" />
                    </button>
                </div>
            </div>

            {isLightboxOpen && createPortal(
                <div
                    className="fixed inset-0 z-[9999] bg-black/95 flex items-center justify-center backdrop-blur-md group/lightbox"
                    onClick={() => setIsLightboxOpen(false)}
                >
                    {/* Close Button */}
                    <button
                        className="absolute top-6 right-6 p-3 bg-white/10 hover:bg-white/20 rounded-full text-white transition-all z-50 cursor-pointer opacity-0 group-hover/lightbox:opacity-100 duration-300"
                        onClick={(e) => {
                            e.stopPropagation();
                            setIsLightboxOpen(false);
                        }}
                    >
                        <X size={32} />
                    </button>

                    {/* Navigation Arrows (if multiple media) */}
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

                    {/* Lightbox Content */}
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

                    {/* Lightbox Dots Indicator */}
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
    );
}
