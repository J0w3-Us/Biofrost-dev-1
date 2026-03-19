import { useState, useEffect } from 'react';
import { X, Search, Check, ArrowRight, Layout, Video } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import { UserAvatar } from '../../../components/UserAvatar';
import api from '../../../lib/axios';
import { motion, AnimatePresence } from 'framer-motion';

export function CreateProjectForm({ onClose, onSuccess }) {
    const { userData } = useAuth();
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    // Data Sources
    const [availableTeachers, setAvailableTeachers] = useState([]);
    const [availableStudents, setAvailableStudents] = useState([]);
    const [isLoadingResources, setIsLoadingResources] = useState(true);

    // Form State
    const [form, setForm] = useState({
        titulo: '',
        materia: '',
        materiaId: '',
        docenteId: '',
        ciclo: '2026-1',
        stackTecnologico: '',
        miembrosIds: []
    });

    const [videoFile, setVideoFile] = useState(null);
    const [uploadProgress, setUploadProgress] = useState(0);

    const [studentSearch, setStudentSearch] = useState('');
    const [teacherSearch, setTeacherSearch] = useState('');


    useEffect(() => {
        if (userData?.grupoId) {
            fetchResources();
        } else {
            setIsLoadingResources(false);
            setError('Debe estar asignado a un grupo para crear proyectos.');
        }
    }, [userData]);

    const fetchResources = async () => {
        try {
            setIsLoadingResources(true);

            // Construir query params para filtrar docentes por carrera si está disponible
            const teacherParams = new URLSearchParams({ groupId: userData.grupoId });
            if (userData.carreraId) {
                teacherParams.append('carreraId', userData.carreraId);
            }

            const [teachersRes, studentsRes] = await Promise.all([
                api.get(`/api/teams/available-teachers?${teacherParams.toString()}`),
                api.get(`/api/teams/available-students?groupId=${userData.grupoId}`)
            ]);
            setAvailableTeachers(teachersRes.data);
            setAvailableStudents(studentsRes.data);
        } catch (err) {
            console.error('Error fetching resources:', err);
            setError('Error al cargar listas.');
        } finally {
            setIsLoadingResources(false);
        }
    };

    const toggleStudent = (studentId) => {
        setForm(prev => {
            const currentMembers = prev.miembrosIds;
            if (currentMembers.includes(studentId)) {
                return { ...prev, miembrosIds: currentMembers.filter(id => id !== studentId) };
            } else {
                if (currentMembers.length >= 4) return prev;
                return { ...prev, miembrosIds: [...currentMembers, studentId] };
            }
        });
    };

    const handleSubmit = async () => {
        setLoading(true);
        setError('');

        if (!form.docenteId) {
            setError('Debes seleccionar un docente asesor.');
            setLoading(false);
            return;
        }

        try {
            let videoUrl = null;

            if (videoFile) {
                const formData = new FormData();
                formData.append('file', videoFile);

                const uploadRes = await api.post('/api/storage/upload?folder=project-promos', formData, {
                    headers: { 'Content-Type': 'multipart/form-data' },
                    onUploadProgress: (progressEvent) => {
                        const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
                        setUploadProgress(percentCompleted);
                    }
                });
                videoUrl = uploadRes.data.url;
            }

            const selectedTeacher = availableTeachers.find(t => t.id === form.docenteId);

            // Fix: Map fields to match Backend 'CreateProjectRequest' DTO
            await api.post('/api/projects', {
                titulo: form.titulo,
                materia: selectedTeacher?.asignatura || form.materia,
                materiaId: selectedTeacher?.materiaId || 'MAT-DEFAULT',
                docenteId: form.docenteId,
                ciclo: form.ciclo,
                userId: userData.userId, // Was 'liderId'
                userGroupId: userData.grupoId, // Was 'grupoId'
                stackTecnologico: form.stackTecnologico.split(',').map(s => s.trim()).filter(Boolean),
                miembrosIds: form.miembrosIds,
                videoUrl: videoUrl,
                repositorioUrl: '' // Added explicitly to avoid null issues if strict
            });
            onSuccess();
        } catch (err) {
            console.error('Error creating project:', err);
            setError(err.response?.data?.message || err.response?.data?.error || 'Error al crear proyecto');
        } finally {
            setLoading(false);
            setUploadProgress(0);
        }
    };

    const nextStep = () => {
        if (!form.titulo) {
            setError('El título es obligatorio');
            return;
        }
        setError('');
        setStep(2);
    };

    const filteredStudents = availableStudents
        .filter(s => s.id !== userData.userId)
        .filter(s => s.nombreCompleto.toLowerCase().includes(studentSearch.toLowerCase()) ||
            s.matricula.toLowerCase().includes(studentSearch.toLowerCase()));

    const filteredTeachers = availableTeachers.filter(t =>
        t.nombreCompleto.toLowerCase().includes(teacherSearch.toLowerCase()) &&
        (!form.materia || t.asignatura === form.materia)
    );

    return (
        <div className="flex flex-col h-full bg-white rounded-xl overflow-hidden">
            {/* Header */}
            <div className="px-8 py-6 border-b border-gray-100 flex items-center justify-between bg-gray-50">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900">
                        {step === 1 ? 'Nuevo Proyecto' : 'Selecciona tu Equipo'}
                    </h2>
                    <p className="text-sm text-gray-500 mt-2 font-medium">
                        {step === 1 ? 'Información del proyecto y docente asesor' : 'Busca e invita a tus compañeros'}
                    </p>
                </div>
                <button
                    onClick={onClose}
                    className="p-2 rounded-lg hover:bg-gray-200 text-gray-500 transition-colors"
                >
                    <X size={22} />
                </button>
            </div>

            <div className="flex-1 overflow-y-auto px-8 py-8">
                <AnimatePresence mode="wait">
                    {step === 1 ? (
                        <motion.div
                            key="step1"
                            initial={{ opacity: 0, x: -20 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: 20 }}
                            className="space-y-8 max-w-2xl"
                        >
                            {/* Project Name */}
                            <div>
                                <label className="block text-sm font-semibold text-gray-900 mb-3">Nombre del Proyecto</label>
                                <div className="relative">
                                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                        <Layout size={18} className="text-gray-400" />
                                    </div>
                                    <input
                                        type="text"
                                        value={form.titulo}
                                        onChange={e => setForm({ ...form, titulo: e.target.value })}
                                        placeholder="Ej: Sistema de Gestión Empresarial"
                                        className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl bg-white placeholder-gray-400 focus:outline-none focus:border-gray-900 focus:ring-2 focus:ring-gray-900/10 transition-all duration-200 text-base"
                                        autoFocus
                                    />
                                </div>
                            </div>

                            {/* Subject & Teacher Mapping */}
                            {/* Logic: Get unique subjects from available teachers to filter the list */}
                            {(() => {
                                const uniqueSubjects = [...new Set(availableTeachers.map(t => t.asignatura))].sort();

                                return (
                                    <div>
                                        <label className="block text-sm font-semibold text-gray-900 mb-3">Materia</label>
                                        <div className="relative">
                                            <select
                                                value={form.materia}
                                                onChange={e => {
                                                    setForm({
                                                        ...form,
                                                        materia: e.target.value,
                                                        docenteId: '' // Reset teacher when subject changes
                                                    });
                                                }}
                                                className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl bg-white focus:outline-none focus:border-gray-900 focus:ring-2 focus:ring-gray-900/10 transition-all duration-200 text-base appearance-none"
                                            >
                                                <option value="">Selecciona una materia...</option>
                                                {uniqueSubjects.map(subject => (
                                                    <option key={subject} value={subject}>{subject}</option>
                                                ))}
                                            </select>
                                            <div className="absolute inset-y-0 right-0 flex items-center px-4 pointer-events-none text-gray-500">
                                                <svg className="w-4 h-4 fill-current" viewBox="0 0 20 20">
                                                    <path d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" fillRule="evenodd"></path>
                                                </svg>
                                            </div>
                                        </div>
                                    </div>
                                );
                            })()}

                            {/* Video Upload */}
                            <div>
                                <label className="block text-sm font-semibold text-gray-900 mb-3">Video Pitch <span className="font-normal text-gray-500">(Opcional)</span></label>
                                <div className="flex justify-center px-6 pt-8 pb-8 border-2 border-dashed border-gray-300 rounded-xl hover:bg-gray-50 transition-all duration-200 cursor-pointer relative group">
                                    <div className="space-y-3 text-center">
                                        <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mx-auto group-hover:bg-blue-50 group-hover:text-blue-600 transition-colors text-gray-400">
                                            <Video size={24} />
                                        </div>
                                        <div className="text-sm">
                                            <label htmlFor="file-upload" className="relative cursor-pointer font-semibold text-gray-900 hover:text-gray-700 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-blue-500">
                                                <span>Haz clic para subir un video</span>
                                                <input
                                                    id="file-upload"
                                                    name="file-upload"
                                                    type="file"
                                                    className="sr-only"
                                                    accept="video/*"
                                                    onChange={(e) => {
                                                        const file = e.target.files[0];
                                                        if (!file) return;
                                                        if (!file.type.startsWith('video/')) {
                                                            alert('Por favor sube un archivo de video válido');
                                                            return;
                                                        }
                                                        if (file.size > 100 * 1024 * 1024) { // 100MB
                                                            alert('El video no puede superar los 100MB');
                                                            return;
                                                        }
                                                        setVideoFile(file);
                                                    }}
                                                />
                                            </label>
                                            <p className="text-gray-500 mt-1">o arrastra y suelta</p>
                                        </div>
                                        <p className="text-xs text-gray-500 font-medium">MP4, WebM, MOV hasta 100MB</p>
                                    </div>
                                    {videoFile && (
                                        <div className="absolute inset-0 bg-white/95 backdrop-blur-sm flex flex-col items-center justify-center rounded-xl border-2 border-green-500">
                                            <div className="w-10 h-10 bg-green-100 text-green-600 rounded-full flex items-center justify-center mb-2">
                                                <Check size={20} />
                                            </div>
                                            <p className="text-green-700 font-semibold text-sm max-w-[80%] truncate">
                                                {videoFile.name}
                                            </p>
                                            <button
                                                onClick={(e) => {
                                                    e.preventDefault();
                                                    setVideoFile(null);
                                                }}
                                                className="mt-2 text-xs text-red-500 hover:text-red-700 font-medium hover:underline"
                                            >
                                                Cambiar archivo
                                            </button>
                                        </div>
                                    )}
                                </div>
                                {uploadProgress > 0 && uploadProgress < 100 && (
                                    <div className="mt-3 space-y-1">
                                        <div className="flex justify-between text-xs font-medium text-gray-500">
                                            <span>Subiendo...</span>
                                            <span>{uploadProgress}%</span>
                                        </div>
                                        <div className="w-full bg-gray-100 rounded-full h-2 overflow-hidden">
                                            <div
                                                className="bg-blue-600 h-full rounded-full transition-all duration-300 ease-out"
                                                style={{ width: `${uploadProgress}%` }}
                                            ></div>
                                        </div>
                                    </div>
                                )}
                            </div>

                            {/* Teacher Selection */}
                            <div>
                                <label className="block text-sm font-semibold text-gray-900 mb-3">Docente Asesor</label>
                                <div className="relative mb-4">
                                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                        <Search size={18} className="text-gray-400" />
                                    </div>
                                    <input
                                        type="text"
                                        value={teacherSearch}
                                        onChange={e => setTeacherSearch(e.target.value)}
                                        placeholder="Buscar docente..."
                                        className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl bg-white placeholder-gray-400 focus:outline-none focus:border-gray-900 focus:ring-2 focus:ring-gray-900/10 transition-all duration-200 text-base"
                                    />
                                </div>

                                <div className="border-2 border-gray-200 rounded-xl max-h-60 overflow-y-auto divide-y divide-gray-100">
                                    {isLoadingResources ? (
                                        <div className="p-6 text-center text-sm text-gray-500">Cargando docentes...</div>
                                    ) : filteredTeachers.length === 0 ? (
                                        <div className="p-6 text-center text-sm text-gray-500">No se encontraron docentes</div>
                                    ) : (
                                        filteredTeachers.map(teacher => (
                                            <div
                                                key={teacher.id}
                                                onClick={() => setForm({
                                                    ...form,
                                                    docenteId: teacher.id,
                                                    materia: teacher.asignatura // Auto-select subject
                                                })}
                                                className={`p-4 cursor-pointer transition-all flex items-center justify-between
                                                    ${form.docenteId === teacher.id ? 'bg-gray-100 text-gray-900' : 'hover:bg-gray-50 text-gray-700'}
                                                `}
                                            >
                                                <div>
                                                    <p className="text-sm font-semibold flex items-center gap-2">
                                                        {teacher.nombreCompleto}
                                                        {teacher.esAltaPrioridad && (
                                                            <span className="text-[11px] bg-amber-100 text-amber-800 px-2 py-0.5 rounded-full font-bold">
                                                                ★ Asesor
                                                            </span>
                                                        )}
                                                    </p>
                                                    <p className="text-xs text-gray-500 mt-1">{teacher.asignatura}</p>
                                                </div>
                                                {form.docenteId === teacher.id && <Check size={18} className="text-gray-900" />}
                                            </div>
                                        ))
                                    )}
                                </div>
                            </div>
                        </motion.div>
                    ) : (
                        <motion.div
                            key="step2"
                            initial={{ opacity: 0, x: 20 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -20 }}
                            className="space-y-8 max-w-2xl"
                        >
                            {/* Student Search */}
                            <div className="relative">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                    <Search size={18} className="text-gray-400" />
                                </div>
                                <input
                                    type="text"
                                    value={studentSearch}
                                    onChange={e => setStudentSearch(e.target.value)}
                                    placeholder="Busca por nombre o matrícula..."
                                    className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl bg-white placeholder-gray-400 focus:outline-none focus:border-gray-900 focus:ring-2 focus:ring-gray-900/10 transition-all duration-200 text-base"
                                    autoFocus
                                />
                            </div>

                            <div className="space-y-4">
                                {/* Leader (Me) */}
                                <div className="p-5 bg-gray-50 rounded-xl border-2 border-gray-200 flex items-center gap-4">
                                    <UserAvatar src={userData?.fotoUrl} name={userData?.nombre} size="md" className="bg-gray-900" />
                                    <div className="flex-1 min-w-0">
                                        <p className="text-sm font-bold text-gray-900 truncate">{userData?.nombre || 'Usuario'}</p>
                                        <p className="text-xs text-gray-500 mt-1 font-medium">Líder del Proyecto</p>
                                    </div>
                                    <span className="px-3 py-1.5 bg-gray-900 text-white text-xs font-semibold rounded-lg flex-shrink-0">Líder</span>
                                </div>

                                {/* Results */}
                                {filteredStudents.map(student => {
                                    const isSelected = form.miembrosIds.includes(student.id);
                                    return (
                                        <div key={student.id} className="p-5 rounded-xl border-2 border-gray-200 hover:border-gray-300 hover:bg-gray-50 flex items-center gap-4 transition-all duration-200">
                                            <UserAvatar src={student.fotoUrl} name={student.nombreCompleto} size="md" />
                                            <div className="flex-1 min-w-0">
                                                <p className="text-sm font-semibold text-gray-900 truncate">
                                                    {student.nombreCompleto}
                                                </p>
                                                <p className="text-xs text-gray-500 font-mono mt-1">
                                                    {student.matricula}
                                                </p>
                                            </div>
                                            <button
                                                onClick={() => toggleStudent(student.id)}
                                                className={`px-4 py-2 rounded-lg text-xs font-semibold transition-all flex-shrink-0 ${isSelected
                                                    ? 'bg-red-100 text-red-700 hover:bg-red-200'
                                                    : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-gray-300'
                                                    }`}
                                            >
                                                {isSelected ? 'Quitar' : 'Añadir'}
                                            </button>
                                        </div>
                                    );
                                })}

                                {filteredStudents.length === 0 && (
                                    <div className="text-center py-12 text-gray-500 text-sm font-medium">
                                        No se encontraron alumnos
                                    </div>
                                )}
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>

                {error && (
                    <div className="mt-6 p-4 bg-red-50 border-2 border-red-200 text-red-700 text-sm rounded-xl font-medium text-center">
                        {error}
                    </div>
                )}
            </div>

            {/* Footer Buttons */}
            <div className="px-8 py-6 border-t border-gray-100 bg-gray-50 flex items-center justify-end gap-3">
                {step === 2 && (
                    <button
                        onClick={() => setStep(1)}
                        className="px-6 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-200 rounded-lg transition-all duration-200"
                    >
                        Atrás
                    </button>
                )}

                {step === 1 ? (
                    <button
                        onClick={nextStep}
                        className="px-6 py-2.5 bg-gray-900 text-white text-sm font-semibold rounded-lg hover:bg-gray-800 transition-all duration-200 flex items-center gap-2 active:scale-95"
                    >
                        Siguiente
                        <ArrowRight size={18} />
                    </button>
                ) : (
                    <button
                        onClick={handleSubmit}
                        disabled={loading}
                        className="px-6 py-2.5 bg-gray-900 text-white text-sm font-semibold rounded-lg hover:bg-gray-800 transition-all duration-200 flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed active:scale-95"
                    >
                        {loading ? 'Creando...' : 'Crear Proyecto'}
                        <Check size={18} />
                    </button>
                )}
            </div>
        </div>
    );
}
