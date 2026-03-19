import { useState, useCallback, useRef, useEffect } from 'react';
import {
    Plus, Image as ImageIcon, Type, Heading1, Heading2, Heading3,
    List, CheckSquare, Code, Quote, MoreVertical, X,
    GripVertical, Video, MonitorPlay,
    ChevronLeft, ChevronRight, Play, Trash2, Bold, Italic,
    Table as TableIcon, ChevronDown
} from 'lucide-react';
import { motion, Reorder, AnimatePresence } from 'framer-motion';
import api from '../../../lib/axios';
import { FONTS } from '../constants/editorFonts';

// ─── Block Types ──────────────────────────────────────────────────────────────
const BLOCK_TYPES = {
    TEXT: 'text', H1: 'h1', H2: 'h2', H3: 'h3',
    BULLET: 'bullet', TODO: 'todo',
    IMAGE: 'image', VIDEO: 'video',
    CODE: 'code', QUOTE: 'quote', DIVIDER: 'divider', TABLE: 'table',
};

const BLOCK_MENU = [
    { type: BLOCK_TYPES.TEXT, icon: Type, label: 'Texto Normal' },
    { type: BLOCK_TYPES.H1, icon: Heading1, label: 'Título Grande' },
    { type: BLOCK_TYPES.H2, icon: Heading2, label: 'Título Mediano' },
    { type: BLOCK_TYPES.H3, icon: Heading3, label: 'Título Pequeño' },
    { type: BLOCK_TYPES.BULLET, icon: List, label: 'Lista con viñetas' },
    { type: BLOCK_TYPES.TODO, icon: CheckSquare, label: 'Lista de tareas' },
    { type: BLOCK_TYPES.QUOTE, icon: Quote, label: 'Cita' },
    { type: BLOCK_TYPES.DIVIDER, icon: MoreVertical, label: 'Separador' },
    { type: BLOCK_TYPES.IMAGE, icon: ImageIcon, label: 'Imagen' },
    { type: BLOCK_TYPES.VIDEO, icon: Video, label: 'Video' },
    { type: BLOCK_TYPES.TABLE, icon: TableIcon, label: 'Tabla' },
];

const TEXT_BLOCK_TYPES = [
    BLOCK_TYPES.TEXT, BLOCK_TYPES.H1, BLOCK_TYPES.H2, BLOCK_TYPES.H3,
    BLOCK_TYPES.BULLET, BLOCK_TYPES.TODO, BLOCK_TYPES.QUOTE, BLOCK_TYPES.CODE,
];

// ─── Utility Helpers ────────────────────────────────────────────────────────
const createDefaultTable = () => ({
    rows: [
        ['Encabezado 1', 'Encabezado 2', 'Encabezado 3'],
        ['Celda', 'Celda', 'Celda'],
        ['Celda', 'Celda', 'Celda'],
    ],
    hasHeader: true,
});

const getNormalizedMetadata = (metadata) => {
    if (!metadata) return {};
    if (typeof metadata === 'string') {
        try { return JSON.parse(metadata); } catch { return {}; }
    }
    return metadata;
};

const getTableData = (block) => {
    const meta = getNormalizedMetadata(block.metadata);
    let raw = meta?.table || meta?.Table;

    // Handle case where 'table' was stored as a JSON string by the old backend
    if (typeof raw === 'string') {
        try { raw = JSON.parse(raw); } catch { raw = null; }
    }

    if (!raw) return createDefaultTable();

    let rows = raw.rows || raw.Rows;
    const hasHeader = raw.hasHeader ?? raw.HasHeader ?? true;

    // Each row might itself be a JSON string in heavily corrupted Firestore docs
    if (Array.isArray(rows)) {
        rows = rows.map(row => {
            if (typeof row === 'string') { try { return JSON.parse(row); } catch { return [row]; } }
            return Array.isArray(row) ? row : [String(row)];
        });
    }

    if (!Array.isArray(rows) || rows.length === 0) return createDefaultTable();
    return { rows, hasHeader };
};


// ─── Styles Map ───────────────────────────────────────────────────────────────
const BLOCK_STYLES = {
    [BLOCK_TYPES.H1]: 'text-4xl font-bold text-gray-900 dark:text-white leading-tight',
    [BLOCK_TYPES.H2]: 'text-2xl font-semibold text-gray-800 dark:text-slate-100 mt-6 mb-2',
    [BLOCK_TYPES.H3]: 'text-xl font-semibold text-gray-800 dark:text-slate-200 mt-4 mb-2',
    [BLOCK_TYPES.QUOTE]: 'border-l-4 border-gray-900 dark:border-slate-400 pl-4 italic text-gray-600 dark:text-slate-300 my-4 text-lg',
    [BLOCK_TYPES.CODE]: 'font-mono text-sm bg-gray-900 dark:bg-slate-900 text-gray-100 p-4 rounded-xl my-2',
    [BLOCK_TYPES.TEXT]: 'text-base text-gray-600 dark:text-slate-300 leading-relaxed',
    [BLOCK_TYPES.BULLET]: 'text-base text-gray-600 dark:text-slate-300 leading-relaxed',
    [BLOCK_TYPES.TODO]: 'text-base text-gray-600 dark:text-slate-300 leading-relaxed',
};

// ─── CanvasEditor ─────────────────────────────────────────────────────────────
export function CanvasEditor({ project, readOnly = false, mode = 'all', onSaveStatusChange }) {
    const [title, setTitle] = useState(project?.titulo || '');
    const [videoUrl, setVideoUrl] = useState(project?.videoUrl || null);
    const [videoUploadProgress, setVideoUploadProgress] = useState(0);

    const [blocks, setBlocks] = useState(() => {
        const c = project?.canvas || project?.canvasBlocks;
        if (c && c.length > 0) return c;
        return [{ id: crypto.randomUUID(), type: BLOCK_TYPES.TEXT, content: '', metadata: {} }];
    });

    const [activeBlock, setActiveBlock] = useState(null);
    const [showMenu, setShowMenu] = useState(null);
    const [saving, setSaving] = useState(false);

    const [lightboxOpen, setLightboxOpen] = useState(false);
    const [lightboxIndex, setLightboxIndex] = useState(0);
    const [lightboxItems, setLightboxItems] = useState([]);

    // Close menu when clicking outside
    useEffect(() => {
        if (!showMenu) return;
        const handler = (e) => {
            if (!e.target.closest('[data-block-menu]')) setShowMenu(null);
        };
        document.addEventListener('mousedown', handler);
        return () => document.removeEventListener('mousedown', handler);
    }, [showMenu]);

    useEffect(() => {
        if (project) {
            setTitle(project.titulo || '');
            setVideoUrl(project.videoUrl || null);
            const c = project.canvas || project.canvasBlocks;
            setBlocks(c && c.length > 0
                ? c
                : [{ id: crypto.randomUUID(), type: BLOCK_TYPES.TEXT, content: '', metadata: {} }]
            );
        }
    }, [project]);

    // Debounced auto-save
    useEffect(() => {
        if (readOnly) return;
        const t = setTimeout(saveContent, 2000);
        return () => clearTimeout(t);
    }, [blocks, title, videoUrl]);

    const saveContent = async () => {
        if (readOnly) return;
        setSaving(true);
        onSaveStatusChange?.(true);
        const sanitized = blocks.map(b => {
            const meta = getNormalizedMetadata(b.metadata);
            const { uploading, progress, error, ...rest } = meta;
            return { ...b, metadata: rest };
        });
        try {
            await api.put(`/api/projects/${project.id}`, {
                titulo: title,
                videoUrl,
                canvasBlocks: sanitized,
            });
        } catch (e) {
            console.error('Error saving project:', e);
        } finally {
            setSaving(false);
            onSaveStatusChange?.(false);
        }
    };

    // ─── Block Management ─────────────────────────────────────────────────────
    const addBlock = (type, index) => {
        const meta = type === BLOCK_TYPES.TABLE ? { table: createDefaultTable() } : {};
        const nb = { id: crypto.randomUUID(), type, content: '', metadata: meta };
        setBlocks(prev => {
            const next = [...prev];
            next.splice(index + 1, 0, nb);
            return next;
        });
        setActiveBlock(nb.id);
        setShowMenu(null);
    };

    const updateBlock = (id, content) =>
        setBlocks(prev => prev.map(b => b.id === id ? { ...b, content } : b));

    const removeBlock = (id) =>
        setBlocks(prev => prev.length > 1 ? prev.filter(b => b.id !== id) : prev);

    const handleBlockMetadataChange = (id, metadataUpdates) =>
        setBlocks(prev => prev.map(b => b.id === id
            ? { ...b, metadata: { ...getNormalizedMetadata(b.metadata), ...metadataUpdates } }
            : b
        ));

    const handleFontChange = (id, fontFamily) => handleBlockMetadataChange(id, { fontFamily });

    // ─── File Uploads ─────────────────────────────────────────────────────────
    const uploadFile = async (file, folder = 'project-assets', onProgress) => {
        const fd = new FormData();
        fd.append('file', file);
        const res = await api.post(`/api/storage/upload?folder=${folder}`, fd, {
            headers: { 'Content-Type': 'multipart/form-data' },
            onUploadProgress: e => onProgress?.(Math.round((e.loaded * 100) / e.total)),
        });
        return res.data.url;
    };

    const handleVideoPitchUpload = async (file) => {
        if (!file) return;
        if (file.type && !file.type.startsWith('video/')) return alert('Por favor sube un video válido (MP4, WebM, MOV).');
        if (file.size > 500 * 1024 * 1024) return alert('El video no puede pesar más de 500MB');
        try {
            setVideoUploadProgress(1);
            const url = await uploadFile(file, 'project-promos', setVideoUploadProgress);
            if (!url) throw new Error('Backend returned empty URL');
            setVideoUrl(url);
        } catch (e) {
            console.error('Video pitch upload error:', e);
            alert(`Error: ${e.response?.data?.error || e.message}`);
        } finally {
            setVideoUploadProgress(0);
        }
    };

    const handleBlockFileUpload = async (file, blockId, type) => {
        if (!file) return;
        if (type === 'image' && file.type.startsWith('video/')) return alert('Este bloque es para IMÁGENES.');
        if (type === 'video' && file.type.startsWith('image/')) return alert('Este bloque es para VIDEOS.');
        if (file.size > 500 * 1024 * 1024) return alert('El archivo no puede superar los 500MB');
        handleBlockMetadataChange(blockId, { uploading: true, progress: 0, error: null });
        try {
            const folder = type === 'video' ? 'videos' : 'images';
            const url = await uploadFile(file, folder, p => handleBlockMetadataChange(blockId, { progress: p }));
            if (!url) throw new Error('Backend returned empty URL');
            updateBlock(blockId, url);
        } catch (e) {
            handleBlockMetadataChange(blockId, { error: e.response?.data?.error || e.message || 'Error al subir archivo' });
        } finally {
            handleBlockMetadataChange(blockId, { uploading: false });
        }
    };

    // ─── Table Updates ────────────────────────────────────────────────────────
    const updateTableCell = (blockId, ri, ci, value) => setBlocks(prev => prev.map(b => {
        if (b.id !== blockId) return b;
        const { rows, hasHeader } = getTableData(b);
        const newRows = rows.map((row, r) =>
            r === ri ? row.map((cell, c) => c === ci ? value : cell) : row
        );
        return { ...b, metadata: { ...getNormalizedMetadata(b.metadata), table: { rows: newRows, hasHeader } } };
    }));
    const addTableRow = (blockId) => setBlocks(prev => prev.map(b => {
        if (b.id !== blockId) return b;
        const { rows, hasHeader } = getTableData(b);
        const cols = rows[0]?.length || 3;
        return { ...b, metadata: { ...getNormalizedMetadata(b.metadata), table: { rows: [...rows, Array(cols).fill('')], hasHeader } } };
    }));
    const addTableCol = (blockId) => setBlocks(prev => prev.map(b => {
        if (b.id !== blockId) return b;
        const { rows, hasHeader } = getTableData(b);
        const newRows = rows.map(r => [...r, '']);
        return { ...b, metadata: { ...getNormalizedMetadata(b.metadata), table: { rows: newRows, hasHeader } } };
    }));
    const removeTableRow = (blockId, ri) => setBlocks(prev => prev.map(b => {
        if (b.id !== blockId) return b;
        const { rows, hasHeader } = getTableData(b);
        if (rows.length <= 1) return b;
        const newRows = rows.filter((_, i) => i !== ri);
        return { ...b, metadata: { ...getNormalizedMetadata(b.metadata), table: { rows: newRows, hasHeader } } };
    }));
    const removeTableCol = (blockId, ci) => setBlocks(prev => prev.map(b => {
        if (b.id !== blockId) return b;
        const { rows, hasHeader } = getTableData(b);
        if ((rows[0]?.length || 0) <= 1) return b;
        const newRows = rows.map(r => r.filter((_, i) => i !== ci));
        return { ...b, metadata: { ...getNormalizedMetadata(b.metadata), table: { rows: newRows, hasHeader } } };
    }));

    // ─── Lightbox ─────────────────────────────────────────────────────────────
    const handleOpenLightbox = (items, index) => {
        setLightboxItems(items);
        setLightboxIndex(index);
        setLightboxOpen(true);
    };

    // ─── Render ───────────────────────────────────────────────────────────────
    const renderReadOnlyBlocks = () => {
        const filteredBlocks = blocks.filter(block => {
            if (mode === 'media') return block.type === BLOCK_TYPES.IMAGE || block.type === BLOCK_TYPES.VIDEO;
            if (mode === 'text') return block.type !== BLOCK_TYPES.IMAGE && block.type !== BLOCK_TYPES.VIDEO;
            return true;
        });

        const groupedGroups = [];
        let mediaGroup = [];
        filteredBlocks.forEach(block => {
            if (block.type === BLOCK_TYPES.IMAGE || block.type === BLOCK_TYPES.VIDEO) {
                mediaGroup.push(block);
            } else {
                if (mediaGroup.length) {
                    groupedGroups.push({ id: `g-${mediaGroup[0].id}`, type: 'media_gallery', items: [...mediaGroup] });
                    mediaGroup = [];
                }
                groupedGroups.push(block);
            }
        });
        if (mediaGroup.length) groupedGroups.push({ id: `g-${mediaGroup[0].id}`, type: 'media_gallery', items: mediaGroup });

        return groupedGroups.map(item => item.type === 'media_gallery'
            ? <MediaGallery key={item.id} items={item.items} onOpenLightbox={i => handleOpenLightbox(item.items, i)} />
            : <Block key={item.id} block={item} readOnly onToggleTodo={checked => handleBlockMetadataChange(item.id, { checked })} />
        );
    };

    return (
        <div className={mode === 'all' ? 'max-w-4xl mx-auto py-8 px-4 lg:px-0' : 'w-full h-full flex flex-col gap-4'}>
            {!readOnly && (
                <div className="mb-12 border-b border-gray-100 dark:border-slate-700 pb-8">
                    <input
                        type="text"
                        value={title}
                        onChange={e => setTitle(e.target.value)}
                        placeholder="Título del Proyecto"
                        className="text-4xl font-bold text-gray-900 dark:text-white placeholder-gray-300 dark:placeholder-slate-600 w-full outline-none bg-transparent mb-8"
                    />
                    <div className="space-y-4">
                        <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
                            <Video size={20} className="text-blue-600" />
                            Video Pitch
                        </h3>
                        {!videoUrl ? (
                            <div className="relative border-2 border-dashed border-gray-200 dark:border-slate-700 rounded-2xl p-8 hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors group cursor-pointer text-center">
                                <input type="file" className="absolute inset-0 w-full h-full opacity-0 cursor-pointer" onChange={e => handleVideoPitchUpload(e.target.files[0])} />
                                <div className="space-y-3">
                                    <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mx-auto group-hover:scale-110 transition-transform">
                                        <MonitorPlay size={24} />
                                    </div>
                                    <div>
                                        <p className="font-semibold text-gray-900 dark:text-white">Haz clic para subir tu Video Pitch</p>
                                        <p className="text-sm text-gray-500 dark:text-slate-400">MP4, WebM hasta 500MB</p>
                                    </div>
                                </div>
                                {videoUploadProgress > 0 && (
                                    <div className="absolute inset-x-8 bottom-4">
                                        <div className="h-1 bg-gray-200 dark:bg-slate-700 rounded-full overflow-hidden">
                                            <div className="h-full bg-blue-600 transition-all duration-300" style={{ width: `${videoUploadProgress}%` }} />
                                        </div>
                                    </div>
                                )}
                            </div>
                        ) : (
                            <div className="relative rounded-2xl overflow-hidden bg-black aspect-video group">
                                <video src={videoUrl} className="w-full h-full object-contain" controls />
                                <button
                                    onClick={() => confirm('¿Eliminar video pitch?') && setVideoUrl(null)}
                                    className="absolute top-4 right-4 p-2 bg-black/50 text-white rounded-lg hover:bg-red-500 transition-colors opacity-0 group-hover:opacity-100"
                                >
                                    <X size={16} />
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            )}

            <div className="space-y-2">
                {readOnly
                    ? renderReadOnlyBlocks()
                    : (
                        <Reorder.Group axis="y" values={blocks} onReorder={setBlocks}>
                            {blocks.map((block, index) => (
                                <Block
                                    key={block.id}
                                    block={block}
                                    active={activeBlock === block.id}
                                    menuOpen={showMenu === block.id}
                                    onFocus={() => setActiveBlock(block.id)}
                                    onChange={content => updateBlock(block.id, content)}
                                    onRemove={() => removeBlock(block.id)}
                                    onAddBlock={type => addBlock(type, index)}
                                    onToggleMenu={() => setShowMenu(prev => prev === block.id ? null : block.id)}
                                    onFileUpload={(file, type) => handleBlockFileUpload(file, block.id, type)}
                                    onFontChange={f => handleFontChange(block.id, f)}
                                    onUpdateTableCell={(ri, ci, v) => updateTableCell(block.id, ri, ci, v)}
                                    onAddTableRow={() => addTableRow(block.id)}
                                    onAddTableCol={() => addTableCol(block.id)}
                                    onRemoveTableRow={ri => removeTableRow(block.id, ri)}
                                    onRemoveTableCol={ci => removeTableCol(block.id, ci)}
                                    onToggleTodo={checked => handleBlockMetadataChange(block.id, { checked })}
                                />
                            ))}
                        </Reorder.Group>
                    )
                }
            </div>

            {!readOnly && (
                <div className="mt-8 pt-8 border-t border-gray-100 dark:border-slate-700 flex flex-wrap justify-center gap-3">
                    {[
                        { type: BLOCK_TYPES.TEXT, icon: Type, label: 'Texto', cls: 'bg-gray-50 dark:bg-slate-800 hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-300' },
                        { type: BLOCK_TYPES.IMAGE, icon: ImageIcon, label: 'Imagen', cls: 'bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 text-blue-600 dark:text-blue-400' },
                        { type: BLOCK_TYPES.VIDEO, icon: Video, label: 'Video', cls: 'bg-purple-50 dark:bg-purple-900/30 hover:bg-purple-100 text-purple-600 dark:text-purple-400' },
                        { type: BLOCK_TYPES.H2, icon: Heading2, label: 'Título', cls: 'bg-gray-50 dark:bg-slate-800 hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-300' },
                        { type: BLOCK_TYPES.TABLE, icon: TableIcon, label: 'Tabla', cls: 'bg-emerald-50 dark:bg-emerald-900/30 hover:bg-emerald-100 text-emerald-600 dark:text-emerald-400' },
                    ].map(({ type, icon: Icon, label, cls }) => (
                        <button
                            key={type}
                            onClick={() => addBlock(type, blocks.length - 1)}
                            className={`px-4 py-3 ${cls} rounded-xl font-medium transition-colors flex items-center gap-2 text-sm`}
                        >
                            <Icon size={18} />
                            {label}
                        </button>
                    ))}
                </div>
            )}

            <AnimatePresence>
                {lightboxOpen && (
                    <Lightbox
                        items={lightboxItems}
                        currentIndex={lightboxIndex}
                        onClose={() => setLightboxOpen(false)}
                        onChangeIndex={setLightboxIndex}
                    />
                )}
            </AnimatePresence>
        </div>
    );
}

// ─── TextToolbar ──────────────────────────────────────────────────────────────
function TextToolbar({ block, onFontChange }) {
    const [fontOpen, setFontOpen] = useState(false);
    const meta = getNormalizedMetadata(block.metadata);
    const currentFont = FONTS.find(f => f.value === meta.fontFamily) || FONTS[0];

    return (
        <div
            className="absolute -top-12 left-0 z-50 flex items-center gap-1 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl shadow-lg px-2 py-1.5"
            onMouseDown={e => e.preventDefault()}
        >
            <div className="relative" data-block-menu>
                <button
                    onClick={() => setFontOpen(v => !v)}
                    className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-700 dark:text-slate-200 text-xs font-medium transition-colors min-w-[130px] justify-between"
                    style={{ fontFamily: currentFont.value }}
                >
                    <span>{currentFont.label}</span>
                    <ChevronDown size={12} />
                </button>
                <AnimatePresence>
                    {fontOpen && (
                        <motion.div
                            initial={{ opacity: 0, y: -6 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -6 }}
                            className="absolute top-full left-0 mt-1.5 w-52 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-gray-100 dark:border-slate-700 z-50 overflow-hidden"
                        >
                            {FONTS.map(font => (
                                <button
                                    key={font.value}
                                    onMouseDown={e => { e.preventDefault(); onFontChange(font.value); setFontOpen(false); }}
                                    className={`w-full text-left px-3 py-2.5 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors text-sm ${meta.fontFamily === font.value ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600' : 'text-gray-700 dark:text-slate-300'}`}
                                    style={{ fontFamily: font.value }}
                                >
                                    {font.label}
                                </button>
                            ))}
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>
            <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-0.5" />
            <button onMouseDown={e => { e.preventDefault(); document.execCommand('bold', false, null); }} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-300 font-bold transition-colors">
                <Bold size={14} />
            </button>
            <button onMouseDown={e => { e.preventDefault(); document.execCommand('italic', false, null); }} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-300 italic transition-colors">
                <Italic size={14} />
            </button>
            <button onMouseDown={e => { e.preventDefault(); document.execCommand('underline', false, null); }} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-300 underline transition-colors text-xs font-bold">
                U
            </button>
        </div>
    );
}

// ─── TableBlock ───────────────────────────────────────────────────────────────
function TableBlock({ block, readOnly, onUpdateCell, onAddRow, onAddCol, onRemoveRow, onRemoveCol }) {
    const { rows, hasHeader } = getTableData(block);

    if (readOnly) {
        return (
            <div className="overflow-x-auto my-4 rounded-xl border border-gray-200 dark:border-slate-700">
                <table className="w-full text-sm text-left border-collapse">
                    <tbody>
                        {rows.map((row, ri) => (
                            <tr key={ri} className={hasHeader && ri === 0 ? 'bg-gray-50 dark:bg-slate-800' : 'hover:bg-gray-50 dark:hover:bg-slate-800/50'}>
                                {row.map((cell, ci) => (
                                    <td key={ci} className={`px-4 py-3 border-b border-r border-gray-200 dark:border-slate-700 last:border-r-0 ${hasHeader && ri === 0 ? 'font-semibold text-gray-800 dark:text-slate-100 border-b-2 border-b-gray-300 dark:border-b-slate-600' : 'text-gray-700 dark:text-slate-300'}`}>
                                        {cell || <span className="text-gray-300 dark:text-slate-600">—</span>}
                                    </td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        );
    }

    return (
        <div className="my-2 group/table">
            <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-slate-700">
                <table className="w-full text-sm border-collapse">
                    <tbody>
                        {rows.map((row, ri) => (
                            <tr key={ri} className={`group/row ${hasHeader && ri === 0 ? 'bg-gray-50 dark:bg-slate-800' : 'hover:bg-gray-50/50 dark:hover:bg-slate-800/30'}`}>
                                {row.map((cell, ci) => (
                                    <td key={ci} className="border border-gray-200 dark:border-slate-700 relative">
                                        {ri === 0 && row.length > 1 && (
                                            <button onClick={() => onRemoveCol(ci)} className="hidden absolute -top-3 left-1/2 -translate-x-1/2 w-5 h-5 bg-red-500 text-white rounded-full group-hover/table:flex items-center justify-center text-xs z-10 hover:bg-red-600">×</button>
                                        )}
                                        <input
                                            value={cell || ''}
                                            onChange={e => onUpdateCell(ri, ci, e.target.value)}
                                            placeholder={hasHeader && ri === 0 ? `Col ${ci + 1}` : ''}
                                            className={`w-full px-3 py-2.5 bg-transparent outline-none text-gray-800 dark:text-slate-200 placeholder-gray-300 dark:placeholder-slate-600 min-w-[80px] ${hasHeader && ri === 0 ? 'font-semibold' : ''}`}
                                        />
                                    </td>
                                ))}
                                {rows.length > 1 && (
                                    <td className="border-0 pl-1 w-6">
                                        <button onClick={() => onRemoveRow(ri)} className="hidden w-5 h-5 bg-red-500 text-white rounded-full group-hover/row:flex items-center justify-center text-xs hover:bg-red-600">×</button>
                                    </td>
                                )}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
            <div className="flex gap-2 mt-2 opacity-0 group-hover/table:opacity-100 transition-opacity">
                <button onClick={onAddRow} className="flex items-center gap-1.5 text-xs px-3 py-1.5 bg-gray-100 dark:bg-slate-700 hover:bg-gray-200 dark:hover:bg-slate-600 text-gray-600 dark:text-slate-300 rounded-lg transition-colors">
                    <Plus size={12} /> Fila
                </button>
                <button onClick={onAddCol} className="flex items-center gap-1.5 text-xs px-3 py-1.5 bg-gray-100 dark:bg-slate-700 hover:bg-gray-200 dark:hover:bg-slate-600 text-gray-600 dark:text-slate-300 rounded-lg transition-colors">
                    <Plus size={12} /> Columna
                </button>
            </div>
        </div>
    );
}

// ─── Block ────────────────────────────────────────────────────────────────────
function Block({
    block, active, menuOpen,
    onFocus, onChange, onRemove, onAddBlock, onToggleMenu, onFileUpload, onFontChange,
    onUpdateTableCell, onAddTableRow, onAddTableCol, onRemoveTableRow, onRemoveTableCol,
    onToggleTodo, readOnly,
}) {
    const editableRef = useRef(null);
    const isTextBlock = TEXT_BLOCK_TYPES.includes(block.type);
    const meta = getNormalizedMetadata(block.metadata);
    const fontFamily = meta?.fontFamily || FONTS[0].value;

    useEffect(() => {
        if (!editableRef.current || !isTextBlock) return;
        if (editableRef.current.innerHTML !== (block.content || '')) {
            editableRef.current.innerHTML = block.content || '';
        }
    }, [block.id]);

    useEffect(() => {
        if (active && editableRef.current) editableRef.current.focus();
    }, [active]);

    const handleInput = (e) => {
        onChange(e.currentTarget.innerHTML);
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter' && e.shiftKey) {
            e.preventDefault();
            onAddBlock?.(BLOCK_TYPES.TEXT);
            return;
        }
        if (e.key === 'Backspace') {
            const isEmpty = !editableRef.current?.textContent?.trim() && !editableRef.current?.innerHTML?.includes('<img');
            if (isEmpty) { e.preventDefault(); onRemove?.(); }
        }
    };

    const renderContent = () => {
        if (block.type === BLOCK_TYPES.DIVIDER) return <div className="h-px bg-gray-200 dark:bg-slate-700 my-8" />;
        if (block.type === BLOCK_TYPES.TABLE) {
            return (
                <TableBlock
                    block={block}
                    readOnly={readOnly}
                    onUpdateCell={onUpdateTableCell}
                    onAddRow={onAddTableRow}
                    onAddCol={onAddTableCol}
                    onRemoveRow={onRemoveTableRow}
                    onRemoveCol={onRemoveTableCol}
                />
            );
        }
        if (block.type === BLOCK_TYPES.IMAGE || block.type === BLOCK_TYPES.VIDEO) {
            const isVideo = block.type === BLOCK_TYPES.VIDEO;
            return (
                <div className="py-2">
                    {block.content ? (
                        <div className="relative group/media rounded-2xl overflow-hidden bg-gray-100 dark:bg-slate-800 border border-gray-200 dark:border-slate-700">
                            {isVideo
                                ? <video src={block.content} controls className="w-full h-auto max-h-[600px] object-contain bg-black" />
                                : <img src={block.content} alt="Content" className="w-full h-auto max-h-[600px] object-contain" />
                            }
                            {!readOnly && (
                                <button onClick={onRemove} className="absolute top-2 right-2 p-1.5 bg-black/50 text-white rounded-lg opacity-0 group-hover/media:opacity-100 transition-opacity hover:bg-red-500">
                                    <Trash2 size={14} />
                                </button>
                            )}
                        </div>
                    ) : (
                        <div className="relative border-2 border-dashed border-gray-200 dark:border-slate-700 rounded-xl p-8 hover:bg-gray-50 dark:hover:bg-slate-800 hover:border-blue-200 transition-colors group cursor-pointer text-center">
                            <input type="file" className="absolute inset-0 w-full h-full opacity-0 cursor-pointer" onChange={e => onFileUpload?.(e.target.files[0], block.type)} disabled={readOnly} />
                            {meta?.uploading ? (
                                <div className="space-y-3">
                                    <div className="animate-spin w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full mx-auto" />
                                    <p className="text-sm text-gray-500 dark:text-slate-400">Subiendo... {meta?.progress || 0}%</p>
                                </div>
                            ) : (
                                <div className="space-y-2">
                                    <div className="w-10 h-10 bg-gray-100 dark:bg-slate-700 rounded-full flex items-center justify-center mx-auto text-gray-400 group-hover:bg-blue-50 group-hover:text-blue-500 transition-colors">
                                        {isVideo ? <Video size={20} /> : <ImageIcon size={20} />}
                                    </div>
                                    <p className="text-sm font-medium text-gray-600 dark:text-slate-400">Haz clic para subir {isVideo ? 'video' : 'imagen'}</p>
                                    {meta?.error && <p className="text-xs text-red-500 bg-red-50 px-2 py-1 rounded">{meta.error}</p>}
                                </div>
                            )}
                        </div>
                    )}
                </div>
            );
        }
        if (readOnly) {
            return <div className={`w-full bg-transparent ${BLOCK_STYLES[block.type] || BLOCK_STYLES[BLOCK_TYPES.TEXT]}`} style={{ fontFamily, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }} dangerouslySetInnerHTML={{ __html: block.content || '' }} />;
        }
        return (
            <div
                ref={editableRef}
                contentEditable
                suppressContentEditableWarning
                onInput={handleInput}
                onKeyDown={handleKeyDown}
                onFocus={onFocus}
                data-placeholder={active ? "Escribe… Shift+Enter p/ nuevo bloque" : ''}
                className={`w-full bg-transparent outline-none min-h-[1.5em] empty:before:content-[attr(data-placeholder)] empty:before:text-gray-300 dark:empty:before:text-slate-600 ${BLOCK_STYLES[block.type] || BLOCK_STYLES[BLOCK_TYPES.TEXT]}`}
                style={{ fontFamily, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}
            />
        );
    };

    const Wrapper = readOnly ? 'div' : Reorder.Item;
    const wrapperProps = readOnly ? {} : { value: block, id: block.id, dragListener: false };
    const handleVisible = menuOpen || active;

    return (
        <Wrapper {...wrapperProps} className={`group/block relative flex items-start gap-2 py-0.5 ${active ? 'z-10' : ''}`}>
            {!readOnly && (
                <div data-block-menu className={`absolute -left-12 top-1 flex items-center gap-0.5 transition-opacity ${handleVisible ? 'opacity-100' : 'opacity-0 group-hover/block:opacity-100'}`}>
                    <button className="p-1 hover:bg-gray-100 dark:hover:bg-slate-700 rounded text-gray-400 cursor-grab"><GripVertical size={16} /></button>
                    <div className="relative" data-block-menu>
                        <button onClick={e => { e.stopPropagation(); onToggleMenu(); }} className={`p-1 rounded text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors ${menuOpen ? 'bg-gray-200 dark:bg-slate-700 text-gray-700 dark:text-slate-200' : ''}`}><MoreVertical size={16} /></button>
                        <AnimatePresence>
                            {menuOpen && (
                                <motion.div initial={{ opacity: 0, scale: 0.95, y: 6 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 6 }} className="absolute left-0 top-8 z-50 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-gray-100 dark:border-slate-700 w-56 overflow-hidden">
                                    <div className="p-2 space-y-0.5 max-h-72 overflow-y-auto">
                                        {BLOCK_MENU.map(item => (
                                            <button key={item.type} onClick={() => onAddBlock(item.type)} className="flex items-center gap-3 px-3 py-2 hover:bg-gray-50 dark:hover:bg-slate-700 rounded-lg text-gray-700 dark:text-slate-200 text-sm transition-colors w-full text-left">
                                                <span className="p-1.5 bg-gray-100 dark:bg-slate-700 rounded-md text-gray-600 dark:text-slate-300"><item.icon size={14} /></span>
                                                <span>{item.label}</span>
                                            </button>
                                        ))}
                                    </div>
                                    <div className="border-t border-gray-100 dark:border-slate-700 p-2">
                                        <button onClick={onRemove} className="flex items-center gap-3 px-3 py-2 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg text-red-500 text-sm transition-colors w-full text-left">
                                            <span className="p-1.5 bg-red-50 dark:bg-red-900/20 rounded-md"><Trash2 size={14} /></span>
                                            Eliminar bloque
                                        </button>
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>
                </div>
            )}
            {!readOnly && active && isTextBlock && <TextToolbar block={block} onFontChange={onFontChange} />}
            <div className="flex-1 min-w-0">
                {block.type === BLOCK_TYPES.BULLET
                    ? <div className="flex gap-2 items-start"><span className="text-gray-400 mt-1 select-none">•</span>{renderContent()}</div>
                    : block.type === BLOCK_TYPES.TODO
                        ? (
                            <div className="flex gap-3 items-start">
                                <button
                                    className={`mt-1 w-5 h-5 rounded border-2 flex items-center justify-center shrink-0 transition-colors ${meta?.checked ? 'bg-blue-500 border-blue-500' : 'border-gray-300 dark:border-slate-600 hover:border-blue-400'}`}
                                    onClick={() => !readOnly && onToggleTodo(!meta?.checked)}
                                >
                                    {meta?.checked && <span className="text-white text-xs">✓</span>}
                                </button>
                                <div className={meta?.checked ? 'line-through opacity-50 flex-1' : 'flex-1'}>{renderContent()}</div>
                            </div>
                        )
                        : renderContent()
                }
            </div>
        </Wrapper>
    );
}

// ─── MediaGallery / MediaItem / Lightbox ──────────────────────────────────────
function MediaGallery({ items, onOpenLightbox }) {
    if (!items?.length) return null;
    if (items.length === 1) return <div className="py-4 cursor-pointer" onClick={() => onOpenLightbox(0)}><MediaItem item={items[0]} className="w-full rounded-2xl max-h-[600px] object-contain hover:opacity-95 transition-opacity" /></div>;
    if (items.length === 2) return <div className="grid grid-cols-2 gap-2 h-[300px] py-4">{items.map((item, i) => <div key={item.id} className="relative h-full cursor-pointer overflow-hidden rounded-xl" onClick={() => onOpenLightbox(i)}><MediaItem item={item} className="w-full h-full object-cover hover:scale-105 transition-transform duration-300" /></div>)}</div>;
    const remaining = items.length - 3;
    return (
        <div className="grid grid-cols-2 gap-2 h-[400px] py-4">
            <div onClick={() => onOpenLightbox(0)} className="cursor-pointer rounded-xl overflow-hidden h-full"><MediaItem item={items[0]} className="w-full h-full object-cover" /></div>
            <div className="grid grid-rows-2 gap-2">
                <div onClick={() => onOpenLightbox(1)} className="cursor-pointer rounded-xl overflow-hidden"><MediaItem item={items[1]} className="w-full h-full object-cover" /></div>
                <div onClick={() => onOpenLightbox(2)} className="relative cursor-pointer rounded-xl overflow-hidden group">
                    <MediaItem item={items[2]} className="w-full h-full object-cover" />
                    {remaining > 0 && <div className="absolute inset-0 bg-black/60 flex items-center justify-center group-hover:bg-black/70 transition-colors"><span className="text-3xl font-bold text-white">+{remaining}</span></div>}
                </div>
            </div>
        </div>
    );
}

function MediaItem({ item, className }) {
    if (item.type === BLOCK_TYPES.VIDEO) return (
        <div className={`relative ${className} bg-black flex items-center justify-center group`}>
            <video src={item.content} className="w-full h-full object-contain pointer-events-none" />
            <div className="absolute inset-0 flex items-center justify-center bg-black/20 group-hover:bg-black/10 transition-colors"><div className="w-12 h-12 bg-white/20 backdrop-blur rounded-full flex items-center justify-center text-white"><Play fill="white" size={20} className="ml-0.5" /></div></div>
        </div>
    );
    return <img src={item.content} alt="" className={className} />;
}

function Lightbox({ items, currentIndex, onClose, onChangeIndex }) {
    const current = items[currentIndex];
    const isVideo = current?.type === BLOCK_TYPES.VIDEO;
    useEffect(() => {
        const h = (e) => {
            if (e.key === 'Escape') onClose();
            if (e.key === 'ArrowLeft') onChangeIndex(p => Math.max(0, p - 1));
            if (e.key === 'ArrowRight') onChangeIndex(p => Math.min(items.length - 1, p + 1));
        };
        window.addEventListener('keydown', h);
        return () => window.removeEventListener('keydown', h);
    }, [items.length, onChangeIndex, onClose]);
    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-[100] bg-black/95 flex items-center justify-center backdrop-blur-sm" onClick={onClose}>
            <button onClick={onClose} className="absolute top-6 right-6 p-2 bg-white/10 hover:bg-white/20 rounded-full text-white z-50"><X size={24} /></button>
            {currentIndex > 0 && <button onClick={e => { e.stopPropagation(); onChangeIndex(currentIndex - 1); }} className="absolute left-6 top-1/2 -translate-y-1/2 p-3 bg-white/10 hover:bg-white/20 rounded-full text-white z-50"><ChevronLeft size={32} /></button>}
            {currentIndex < items.length - 1 && <button onClick={e => { e.stopPropagation(); onChangeIndex(currentIndex + 1); }} className="absolute right-6 top-1/2 -translate-y-1/2 p-3 bg-white/10 hover:bg-white/20 rounded-full text-white z-50"><ChevronRight size={32} /></button>}
            <div className="w-full h-full flex items-center justify-center p-8 md:p-16" onClick={e => e.stopPropagation()}>
                {isVideo ? <video src={current.content} controls autoPlay className="max-w-full max-h-full rounded-lg shadow-2xl" /> : <img src={current.content} alt="" className="max-w-full max-h-full object-contain rounded-lg shadow-2xl" />}
            </div>
            {items.length > 1 && <div className="absolute bottom-6 left-0 right-0 text-center text-white/50 text-sm">{currentIndex + 1} / {items.length}</div>}
        </motion.div>
    );
}
