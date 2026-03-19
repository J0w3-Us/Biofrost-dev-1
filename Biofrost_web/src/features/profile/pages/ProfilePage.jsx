import { useState, useRef, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useAuth } from '../../auth/hooks/useAuth';
import { UserAvatar } from '../../../components/UserAvatar';
import { GlobeBanner } from '../components/GlobeBanner';
import { Mail, Phone, MapPin, Calendar, Camera, Edit2, Shield, User as UserIcon, BookOpen, GraduationCap, Briefcase, Building, Loader2, Link as LinkIcon, Github, Linkedin, Twitter, Globe, Plus, Trash2, X, Save, Youtube } from 'lucide-react';
import api from '../../../lib/axios';

export function ProfilePage() {
    const { userData: authData, refreshUserData } = useAuth();
    const { userId } = useParams();
    const isOwnProfile = !userId || (authData && userId === authData.userId);

    const [publicData, setPublicData] = useState(null);
    const [loadingPublic, setLoadingPublic] = useState(false);

    useEffect(() => {
        if (!isOwnProfile && userId) {
            setLoadingPublic(true);
            api.get(`/api/users/${userId}/profile`)
                .then(res => {
                    const data = res.data;
                    setPublicData({
                        userId: data.id,
                        email: data.email,
                        nombre: data.nombre,
                        apellidoPaterno: data.apellidoPaterno,
                        apellidoMaterno: data.apellidoMaterno,
                        fotoUrl: data.fotoUrl,
                        rol: data.rol,
                        matricula: data.matricula,
                        grupoId: data.grupoId,
                        carreraId: data.carreraId,
                        profesion: data.profesion,
                        especialidadDocente: data.especialidadDocente,
                        organizacion: data.organizacion,
                        createdAt: data.createdAt,
                        redesSociales: data.redesSociales || {}
                    });
                })
                .catch(err => {
                    console.error("Error fetching public profile:", err);
                    setPublicData(null);
                })
                .finally(() => setLoadingPublic(false));
        }
    }, [userId, isOwnProfile]);

    const userData = isOwnProfile ? authData : publicData;

    const fileInputRef = useRef(null);
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);

    // --- Social Links State ---
    const [isEditingSocial, setIsEditingSocial] = useState(false);
    const [socialLinks, setSocialLinks] = useState(userData?.redesSociales || {});
    const [savingSocial, setSavingSocial] = useState(false);
    const [newPlatform, setNewPlatform] = useState('github');
    const [newUrl, setNewUrl] = useState('');
    const [carreraNombre, setCarreraNombre] = useState('Cargando...');

    useEffect(() => {
        if (userData?.redesSociales) {
            setSocialLinks(userData.redesSociales);
        }
    }, [userData]);

    useEffect(() => {
        if (!userData) return;
        const rawId = userData.carreraId;
        if (!rawId) {
            setCarreraNombre('Sin carrera');
            return;
        }

        const carreraNamesAbbr = {
            'IDGS': 'Ing. Desarrollo y Gestión de Software',
            'IDGSI': 'Ing. Desarrollo y Gestión de Software',
            'IMT': 'Ing. Mecatrónica',
            'IER': 'Ing. Energías Renovables',
            'IMTC': 'Ing. Mecatrónica',
            'IERE': 'Ing. Energías Renovables',
            'IIND': 'Ing. Industrial',
            'IGAE': 'Ing. Gestión y Automatización',
        };

        const upper = rawId.toUpperCase();
        if (carreraNamesAbbr[upper]) {
            setCarreraNombre(carreraNamesAbbr[upper]);
            return;
        }

        // Si parece un ID generado por Firebase (largo > 10) consultamos el backend
        if (rawId.length > 10) {
            api.get('/api/admin/carreras')
                .then(res => {
                    const carrera = res.data?.find(c => c.id === rawId);
                    if (carrera) {
                        setCarreraNombre(carrera.nombre);
                    } else {
                        setCarreraNombre('Carrera asignada');
                    }
                })
                .catch(() => setCarreraNombre('Carrera asignada'));
        } else {
            setCarreraNombre(rawId);
        }
    }, [userData?.carreraId]);

    if (loadingPublic) {
        return (
            <div className="flex justify-center items-center py-20 min-h-[50vh]">
                <Loader2 size={40} className="animate-spin text-blue-600" />
            </div>
        );
    }

    if (!userData) {
        return (
            <div className="flex justify-center flex-col items-center py-20 min-h-[50vh]">
                <h2 className="text-2xl font-bold text-slate-800">Perfil no encontrado</h2>
                <p className="text-slate-500 mt-2">El usuario que buscas no existe o no tienes permisos para verlo.</p>
            </div>
        );
    }

    // Higher quality name resolution for the header
    const hasRealName = userData.nombre && userData.nombre !== 'Usuario';

    const displayNombre = hasRealName ? userData.nombre.replace(/^\d+\s+/, '') : (userData.email ? userData.email.split('@')[0] : 'Usuario');
    const fullName = `${displayNombre} ${userData.apellidoPaterno || ''} ${userData.apellidoMaterno || ''}`.trim();

    // --- "Miembro desde" dynamic formatting ---
    const memberSince = (() => {
        if (!userData.createdAt) return 'Fecha no disponible';
        try {
            const date = new Date(userData.createdAt);
            if (isNaN(date.getTime())) return 'Fecha no disponible';
            const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
            return `${months[date.getMonth()]} ${date.getFullYear()}`;
        } catch {
            return 'Fecha no disponible';
        }
    })();

    // --- Profile Photo Upload ---
    const handlePhotoUpload = async (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Validate
        if (!file.type.startsWith('image/')) {
            return alert('Por favor, selecciona una imagen (JPG, PNG, WebP).');
        }
        if (file.size > 5 * 1024 * 1024) {
            return alert('La imagen no puede pesar más de 5MB.');
        }

        setUploading(true);
        setUploadProgress(0);

        try {
            // Step 1: Upload to Supabase Storage via existing endpoint
            const formData = new FormData();
            formData.append('file', file);

            const uploadResponse = await api.post('/api/storage/upload?folder=avatars', formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
                onUploadProgress: (progressEvent) => {
                    const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
                    setUploadProgress(percent);
                }
            });

            const photoUrl = uploadResponse.data.url;
            if (!photoUrl) throw new Error('No URL returned from storage');

            // Step 2: Persist URL to Firestore via new endpoint
            await api.put(`/api/users/${userData.userId}/photo`, {
                fotoUrl: photoUrl
            });

            // Step 3: Refresh user data globally so all components update
            await refreshUserData();

        } catch (error) {
            console.error('Error uploading profile photo:', error);
            const msg = error.response?.data?.error || error.message || 'Error al subir la foto';
            alert(`Error: ${msg}`);
        } finally {
            setUploading(false);
            setUploadProgress(0);
            // Reset file input
            if (fileInputRef.current) fileInputRef.current.value = '';
        }
    };

    // --- Social Links Upload ---
    const handleSaveSocialLinks = async () => {
        setSavingSocial(true);

        let finalLinks = { ...socialLinks };
        // Auto-agregar si el usuario escribió un enlace pero olvidó presionar '+'
        if (newUrl.trim()) {
            let urlValue = newUrl.trim();
            if (!/^https?:\/\//i.test(urlValue)) {
                urlValue = `https://${urlValue}`; // Auto-append https
            }
            finalLinks[newPlatform] = urlValue;
            setSocialLinks(finalLinks);
            setNewUrl(''); // limpiar input
        }

        try {
            await api.put(`/api/users/${userData.userId}/social`, {
                redesSociales: finalLinks
            });
            await refreshUserData();
            setIsEditingSocial(false);
        } catch (error) {
            console.error('Error saving social links:', error);
            alert('Error al guardar las redes sociales.');
        } finally {
            setSavingSocial(false);
        }
    };

    const handleAddSocialLink = () => {
        if (!newUrl.trim()) return;
        // Basic URL validation
        let urlValue = newUrl.trim();
        if (!/^https?:\/\//i.test(urlValue)) {
            urlValue = `https://${urlValue}`; // Auto-append https
        }

        setSocialLinks(prev => ({
            ...prev,
            [newPlatform]: urlValue
        }));
        setNewUrl('');
    };

    const handleRemoveSocialLink = (platformToRemove) => {
        setSocialLinks(prev => {
            const copy = { ...prev };
            delete copy[platformToRemove];
            return copy;
        });
    };

    const getSocialIconAndColor = (platform) => {
        const size = 20;
        let icon;
        let colorClass;
        let bgClass = 'bg-white border-slate-200 hover:border-slate-300 hover:bg-slate-50 hover:shadow-sm text-slate-700';

        switch (platform.toLowerCase()) {
            case 'github':
                icon = <Github size={size} />;
                colorClass = 'text-slate-800 group-hover:text-black';
                break;
            case 'linkedin':
                icon = <Linkedin size={size} />;
                colorClass = 'text-[#0A66C2] group-hover:text-[#004182]';
                break;
            case 'twitter':
            case 'x':
                icon = <Twitter size={size} />;
                colorClass = 'text-slate-800 group-hover:text-black';
                break;
            case 'youtube':
                icon = <Youtube size={size} />;
                colorClass = 'text-[#FF0000] group-hover:text-[#cc0000]';
                break;
            default:
                icon = <LinkIcon size={size} />;
                colorClass = 'text-blue-500 group-hover:text-blue-600';
                break;
        }

        return { icon, colorClass, bgClass };
    };

    // --- Cancel Edit Social ---
    const handleCancelEditSocial = () => {
        setSocialLinks(userData.redesSociales || {});
        setIsEditingSocial(false);
        setNewUrl('');
    };

    return (
        <div className="flex flex-col gap-8 pb-10">
            {/* Hidden File Input */}
            <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp,image/gif"
                className="hidden"
                onChange={handlePhotoUpload}
            />

            {/* Main Neumorphic Card */}
            <div className="neu-flat rounded-[3rem] overflow-hidden relative dark:bg-[#1a1d27]">

                {/* Cover with Animated Geometric Pattern and Gradients */}
                <div className="h-72 w-full relative overflow-hidden group bg-slate-900">
                    {/* Modern mesh gradient background */}
                    <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-950"></div>

                    {/* Animated gradient orbs */}
                    <div className="absolute -top-32 -left-20 w-[30rem] h-[30rem] bg-blue-600/20 rounded-full mix-blend-screen filter blur-[80px] group-hover:scale-110 transition-transform duration-1000"></div>
                    <div className="absolute top-10 right-0 w-[25rem] h-[25rem] bg-indigo-500/10 rounded-full mix-blend-screen filter blur-[60px] group-hover:-translate-x-10 transition-transform duration-1000"></div>

                    {/* Geometric Hexagon Grid overlay (CSS only approach) */}
                    <div className="absolute inset-0 opacity-[0.08]" style={{
                        backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M30 0l25.98 15v30L30 60 4.02 45V15z' fill-rule='evenodd' stroke='%23ffffff' stroke-width='1' fill='none'/%3E%3C/svg%3E")`,
                        backgroundSize: '40px 40px'
                    }}></div>

                    <GlobeBanner />

                    <div className="absolute inset-0 bg-gradient-to-t from-slate-950/90 to-transparent"></div>
                </div>

                {/* Profile Header Content */}
                <div className="px-8 sm:px-12 lg:px-16 pb-12 relative">
                    <div className="flex flex-col md:flex-row gap-6 items-start -mt-20">

                        {/* Avatar with upload */}
                        <div className="relative group shrink-0">
                            <div className="w-44 h-44 rounded-full neu-flat p-2 bg-[#e0e5ec] dark:bg-slate-800 flex items-center justify-center">
                                <UserAvatar
                                    src={userData.fotoUrl}
                                    name={userData.nombre}
                                    size="xl"
                                    className="shadow-inner"
                                />
                            </div>
                            {isOwnProfile && (
                                <button
                                    onClick={() => fileInputRef.current?.click()}
                                    disabled={uploading}
                                    className="absolute bottom-2 right-2 rounded-full flex items-center justify-center w-10 h-10 bg-[#e0e5ec] text-slate-900 shadow-lg border border-white/40 hover:bg-white transition-all disabled:opacity-50"
                                >
                                    {uploading ? (
                                        <Loader2 size={18} className="animate-spin" />
                                    ) : (
                                        <Camera size={18} />
                                    )}
                                </button>
                            )}

                            {/* Upload progress ring */}
                            {uploading && uploadProgress > 0 && (
                                <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                                    <svg className="w-44 h-44 rotate-[-90deg]" viewBox="0 0 44 44">
                                        <circle cx="22" cy="22" r="20" fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="2" />
                                        <circle cx="22" cy="22" r="20" fill="none" stroke="#3b82f6" strokeWidth="2.5"
                                            strokeDasharray={`${uploadProgress * 1.256}, 125.6`} strokeLinecap="round"
                                            className="transition-all duration-300"
                                        />
                                    </svg>
                                </div>
                            )}
                        </div>

                        {/* Name & Role */}
                        <div className="flex-1 mt-4 md:mt-20 flex flex-col md:flex-row md:items-center justify-between gap-4">
                            <div>
                                <h1 className="text-4xl font-black text-slate-900 dark:text-white tracking-tight">
                                    {fullName}
                                </h1>
                                <div className="flex items-center gap-3 mt-2">
                                    <span className="px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-sm ring-1 ring-slate-800 dark:ring-white/20">
                                        {userData.rol}
                                    </span>
                                    <div className="flex items-center gap-1.5 text-slate-500 dark:text-slate-400 text-xs font-bold">
                                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                                        En línea
                                    </div>
                                </div>
                            </div>

                            {/* Edit Button */}
                            {isOwnProfile && (
                                <button className="px-6 py-3 bg-white dark:bg-slate-800 rounded-xl font-black text-slate-700 dark:text-slate-200 shadow-sm border border-slate-200 dark:border-slate-600 hover:bg-slate-50 dark:hover:bg-slate-700 hover:text-slate-900 dark:hover:text-white transition-all flex items-center gap-2 uppercase text-[10px] tracking-widest shrink-0">
                                    <Edit2 size={16} />
                                    <span>Configurar</span>
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* 2-Column Social/Portfolio Layout */}
            <div className="grid grid-cols-1 xl:grid-cols-12 gap-8">

                {/* Left Column (Contact & Social) */}
                <div className="xl:col-span-4 flex flex-col gap-6">

                    {/* Social Links Card */}
                    <div className="bg-white dark:bg-[#1a1d27] border border-slate-100 dark:border-slate-700/50 rounded-3xl p-6 shadow-sm">
                        <div className="flex items-center justify-between mb-6">
                            <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2 uppercase tracking-tighter">
                                <span className="w-1 h-5 bg-blue-600 rounded-full"></span>
                                Redes y Enlaces
                            </h2>
                            {!isEditingSocial && isOwnProfile && (
                                <button onClick={() => setIsEditingSocial(true)} className="p-2 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="Editar enlaces">
                                    <Edit2 size={16} />
                                </button>
                            )}
                        </div>

                        {isEditingSocial ? (
                            <div className="space-y-4">
                                {/* Formulario para agregar */}
                                <div className="flex gap-2">
                                    <select
                                        value={newPlatform}
                                        onChange={(e) => setNewPlatform(e.target.value)}
                                        className="bg-slate-50 border border-slate-200 text-slate-700 text-sm rounded-xl px-2 py-2 outline-none focus:ring-2 focus:ring-blue-500"
                                    >
                                        <option value="github">GitHub</option>
                                        <option value="linkedin">LinkedIn</option>
                                        <option value="twitter">X (Twitter)</option>
                                        <option value="portfolio">Portafolio</option>
                                        <option value="youtube">YouTube</option>
                                        <option value="otro">Otro</option>
                                    </select>
                                    <input
                                        type="url"
                                        placeholder="https://..."
                                        value={newUrl}
                                        onChange={(e) => setNewUrl(e.target.value)}
                                        className="flex-1 min-w-0 bg-slate-50 border border-slate-200 text-slate-900 text-sm rounded-xl px-3 py-2 outline-none focus:ring-2 focus:ring-blue-500 placeholder:text-slate-400"
                                    />
                                    <button
                                        onClick={handleAddSocialLink}
                                        className="bg-slate-900 text-white p-2 rounded-xl hover:bg-blue-600 transition-colors shrink-0"
                                    >
                                        <Plus size={20} />
                                    </button>
                                </div>

                                {/* Lista de links en edición */}
                                <div className="space-y-2 mt-4 max-h-48 overflow-y-auto pr-1">
                                    {Object.entries(socialLinks).map(([platform, url]) => {
                                        const { icon, colorClass, bgClass } = getSocialIconAndColor(platform);
                                        return (
                                            <div key={platform} className={`flex items-center justify-between p-2 rounded-lg border transition-all group ${bgClass}`}>
                                                <div className="flex items-center gap-3 overflow-hidden">
                                                    <div className={`p-1.5 bg-slate-950 rounded-md shadow-sm transition-colors ${colorClass}`}>
                                                        {icon}
                                                    </div>
                                                    <div className="flex flex-col min-w-0">
                                                        <span className={`text-xs font-bold capitalize transition-colors text-white group-hover:text-slate-200`}>{platform}</span>
                                                        <span className="text-[10px] text-slate-400 truncate">{url}</span>
                                                    </div>
                                                </div>
                                                <button
                                                    onClick={() => handleRemoveSocialLink(platform)}
                                                    className="text-red-400 hover:text-red-500 p-1.5 hover:bg-slate-800 rounded-md transition-colors shrink-0"
                                                    title="Eliminar"
                                                >
                                                    <Trash2 size={14} />
                                                </button>
                                            </div>
                                        );
                                    })}
                                    {Object.keys(socialLinks).length === 0 && (
                                        <p className="text-center text-slate-400 text-xs py-4">No hay enlaces agregados aún.</p>
                                    )}
                                </div>

                                <div className="flex items-center justify-end gap-2 pt-4 border-t border-slate-100 mt-4">
                                    <button
                                        onClick={handleCancelEditSocial}
                                        className="px-4 py-2 text-xs font-bold text-slate-500 hover:text-slate-700 transition-colors"
                                    >
                                        Cancelar
                                    </button>
                                    <button
                                        onClick={handleSaveSocialLinks}
                                        disabled={savingSocial}
                                        className="px-4 py-2 bg-blue-600 text-white text-xs font-bold rounded-lg shadow-sm hover:bg-blue-700 transition-colors flex items-center gap-2 disabled:opacity-50"
                                    >
                                        {savingSocial ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
                                        Guardar
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <div className="flex flex-wrap gap-3">
                                {Object.entries(socialLinks).length > 0 ? (
                                    Object.entries(socialLinks).map(([platform, url]) => {
                                        const { icon, colorClass, bgClass } = getSocialIconAndColor(platform);
                                        return (
                                            <a
                                                key={platform}
                                                href={url}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className={`flex items-center justify-center p-3 rounded-xl border transition-all shadow-sm group ${bgClass}`}
                                                title={url}
                                            >
                                                <div className={`group-hover:scale-110 transition-transform ${colorClass}`}>
                                                    {icon}
                                                </div>
                                            </a>
                                        );
                                    })
                                ) : (
                                    <div className="w-full text-center py-6 border-2 border-dashed border-slate-200 rounded-xl bg-slate-50/50">
                                        <p className="text-slate-400 text-sm mb-2">Sin redes sociales</p>
                                        {isOwnProfile && (
                                            <button
                                                onClick={() => setIsEditingSocial(true)}
                                                className="text-xs font-bold text-blue-600 hover:text-blue-700"
                                            >
                                                + Agregar Enlaces
                                            </button>
                                        )}
                                    </div>
                                )}
                            </div>
                        )}
                    </div>

                    {/* Contact Info Card */}
                    <div className="bg-white dark:bg-[#1a1d27] border border-slate-100 dark:border-slate-700/50 rounded-3xl p-6 shadow-sm">
                        <h2 className="text-lg font-black text-slate-900 dark:text-white mb-6 flex items-center gap-2 uppercase tracking-tighter">
                            <span className="w-1 h-5 bg-slate-800 rounded-full"></span>
                            Contacto
                        </h2>
                        <div className="space-y-4">
                            <ContactRow icon={<Mail size={16} />} label="Email" value={userData.email} />
                            {userData.telefono && <ContactRow icon={<Phone size={16} />} label="Teléfono" value={userData.telefono} />}
                            {userData.direccion && <ContactRow icon={<MapPin size={16} />} label="Ubicación" value={userData.direccion} />}
                            <ContactRow icon={<Calendar size={16} />} label="Miembro" value={memberSince} />
                        </div>
                    </div>
                </div>

                {/* Right Column (Academic/Professional Info) */}
                <div className="xl:col-span-8 flex flex-col gap-6">
                    <div className="bg-white dark:bg-[#1a1d27] border border-slate-100 dark:border-slate-700/50 rounded-3xl p-8 shadow-sm h-full">
                        <h2 className="text-xl font-black text-slate-900 dark:text-white mb-8 flex items-center gap-3 uppercase tracking-tighter">
                            <span className="w-1.5 h-6 bg-slate-900 rounded-full"></span>
                            Información Académica / Profesional
                        </h2>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 border-b border-slate-100 dark:border-slate-700/50 pb-8">
                            {/* Academic/Professional Fields based on Role */}
                            {userData.rol === 'Alumno' && (
                                <>
                                    <InfoCard icon={<UserIcon size={20} />} label="Matrícula" value={userData.matricula || 'N/A'} color="text-blue-600 bg-blue-50" />
                                    <InfoCard icon={<GraduationCap size={20} />} label="Carrera" value={carreraNombre} color="text-indigo-600 bg-indigo-50" />
                                    {userData.grupoNombre && <InfoCard icon={<BookOpen size={20} />} label="Grupo" value={userData.grupoNombre} color="text-emerald-600 bg-emerald-50" />}
                                </>
                            )}

                            {userData.rol === 'Docente' && (
                                <>
                                    <InfoCard icon={<Briefcase size={20} />} label="Profesión" value={userData.profesion || 'No especificado'} color="text-purple-600 bg-purple-50" />
                                    {userData.especialidadDocente && <InfoCard icon={<Shield size={20} />} label="Especialidad" value={userData.especialidadDocente} color="text-indigo-600 bg-indigo-50" />}
                                    <InfoCard icon={<UserIcon size={20} />} label="Nómina / ID" value={userData.matricula || 'N/A'} color="text-blue-600 bg-blue-50" />
                                </>
                            )}

                            {userData.rol === 'Invitado' && userData.organizacion && (
                                <InfoCard icon={<Building size={20} />} label="Organización" value={userData.organizacion} color="text-slate-700 bg-slate-100" />
                            )}
                        </div>

                        {/* Premium Status Inside Academic */}
                        <div className="mt-8 flex flex-col sm:flex-row items-center sm:items-start gap-6 bg-slate-50 dark:bg-[#1e2230] border border-slate-100 dark:border-slate-700/50 rounded-3xl p-6 relative overflow-hidden">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-blue-100 dark:bg-blue-600/10 rounded-full blur-3xl opacity-50 -translate-y-10 translate-x-10 pointer-events-none"></div>
                            <div className="w-20 h-20 shrink-0 relative flex items-center justify-center bg-white dark:bg-[#0f111a] rounded-full shadow-sm z-10 p-1 transition-colors">
                                <svg className="w-full h-full rotate-[-90deg]" viewBox="0 0 36 36">
                                    <circle cx="18" cy="18" r="16" fill="none" className="stroke-slate-100 dark:stroke-slate-800" strokeWidth="3" />
                                    <circle cx="18" cy="18" r="16" fill="none" stroke="#2563eb" strokeWidth="3" strokeDasharray="95, 100" strokeLinecap="round" />
                                </svg>
                                <span className="absolute text-base font-black text-slate-900 dark:text-white">95%</span>
                            </div>
                            <div className="text-center sm:text-left z-10 w-full">
                                <h3 className="text-xl font-bold text-slate-900 dark:text-white tracking-tight flex items-center gap-2 justify-center sm:justify-start">
                                    Perfil Premium <Shield size={16} className="text-blue-600" />
                                </h3>
                                <p className="text-slate-500 dark:text-slate-400 mt-2 text-sm max-w-lg">
                                    Tu perfil casi está completo. Agregar redes sociales públicas aumentará tu visibilidad y te permitirá conectar de mejor forma dentro de la plataforma.
                                </p>
                            </div>
                        </div>

                    </div>
                </div>

            </div>
        </div>
    );
}

function ContactRow({ icon, label, value }) {
    if (!value) return null;
    return (
        <div className="flex items-center gap-3 group">
            <div className="w-8 h-8 rounded-full bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 flex items-center justify-center text-slate-500 dark:text-slate-400 shrink-0 group-hover:bg-blue-50 dark:group-hover:bg-blue-900/30 group-hover:text-blue-600 transition-colors">
                {icon}
            </div>
            <div className="flex flex-col min-w-0">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-wider">{label}</span>
                <span className="text-sm font-medium text-slate-700 dark:text-slate-300 truncate" title={value}>{value}</span>
            </div>
        </div>
    );
}

function InfoCard({ icon, label, value, color, fullWidth = false }) {
    return (
        <div className={`bg-white dark:bg-slate-800/50 border border-slate-100 dark:border-slate-700/50 shadow-sm rounded-2xl p-4 flex items-center gap-4 group hover:border-slate-200 dark:hover:border-slate-600 transition-all ${fullWidth ? 'md:col-span-2' : ''}`}>
            <div className={`w-12 h-12 rounded-full flex items-center justify-center shrink-0 ${color}`}>
                {icon}
            </div>
            <div className="min-w-0 flex-1">
                <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest">{label}</p>
                <p className={`text-slate-900 dark:text-white font-bold ${fullWidth ? 'break-all text-sm' : 'break-words text-sm'}`} title={value}>
                    {value}
                </p>
            </div>
        </div>
    );
}
