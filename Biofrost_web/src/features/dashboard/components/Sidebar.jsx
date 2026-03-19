import { NavLink } from 'react-router-dom';
import { FolderOpen, Users, Calendar, LogOut, LayoutDashboard, Rocket, Trophy, X, Moon, Sun } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import { UserAvatar } from '../../../components/UserAvatar';
import { useTheme } from '../../../context/ThemeContext';

export function Sidebar({ isOpen, onClose }) {
  const { userData, logout } = useAuth();
  const { isDark, toggleTheme } = useTheme();

  const menuGroups = [
    {
      title: 'PRINCIPAL',
      items: [
        { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
        { label: 'Galería', path: '/showcase', icon: Rocket },
        { label: 'Ranking', path: '/ranking', icon: Trophy },
      ]
    },
    {
      title: 'GESTIÓN',
      items: [
        // Items exclusivos para Estudiantes (y Admins para debug)
        ...(['Alumno', 'Admin', 'admin', 'SuperAdmin'].includes(userData?.rol) ? [
          { label: 'Mis Proyectos', path: '/projects', icon: FolderOpen },
          { label: 'Mi Equipo', path: '/team', icon: Users },
        ] : []),

        // Items exclusivos para Docentes
        ...(userData?.rol === 'Docente' ? [
          { label: 'Evaluaciones', path: '/evaluations', icon: FolderOpen },
        ] : []),
      ]
    },
    ...(userData?.rol === 'admin' || userData?.rol === 'SuperAdmin' ? [{
      title: 'ADMINISTRACIÓN',
      items: [
        { label: 'Panel Admin', path: '/admin', icon: Users }
      ]
    }] : [])
  ];

  return (
    <>
      {/* Mobile Overlay Background */}
      {isOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-40 transition-opacity"
          onClick={onClose}
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={`
          fixed lg:relative inset-y-0 left-0 z-50 flex flex-col bg-white dark:bg-[#151821] border-r border-gray-200 dark:border-slate-700/50 font-sans h-full shrink-0
          transition-all duration-300 ease-[cubic-bezier(0.4,0,0.2,1)]
          /* Mobile classes */
          ${isOpen ? 'translate-x-0 w-72' : '-translate-x-full w-72'} 
          /* Desktop classes: Collapsed by default (w-20), Expanded on hover (w-72) */
          lg:translate-x-0 lg:w-20 lg:hover:w-72 group
        `}
      >
        {/* Header / Logo Brand */}
        <div className="flex items-center justify-between p-6 lg:p-4 lg:group-hover:p-6 transition-all duration-300 border-b border-gray-100 dark:border-slate-700/50 overflow-hidden shrink-0">
          <div className="flex items-center gap-3">
            {/* Logo Icon */}
            <div className="w-12 h-12 bg-white rounded-2xl p-1 shadow-sm border border-gray-100 dark:border-slate-700 overflow-hidden shrink-0 flex items-center justify-center">
              <img
                src="/byfrost-icon.png"
                alt="Byfrost Logo"
                className="w-full h-full object-cover rounded-xl"
              />
            </div>
            {/* Text logo (hidden when collapsed on desktop, visible on hover/mobile) */}
            <div className="transition-opacity duration-300 lg:opacity-0 lg:group-hover:opacity-100 whitespace-nowrap">
              <h1 className="text-xl font-bold text-gray-900 dark:text-white leading-tight">
                Byfrost®
              </h1>
              <p className="text-xs text-gray-500 dark:text-slate-400 font-medium mt-0.5">Repositorio de Proyectos</p>
            </div>
          </div>

          {/* Mobile Close Button */}
          <button
            onClick={onClose}
            className="lg:hidden p-2 text-gray-400 dark:text-slate-500 hover:text-gray-600 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-slate-700/50 rounded-lg transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-3 py-6 space-y-8 overflow-y-auto overflow-x-hidden custom-scrollbar">
          {menuGroups.map((group, idx) => (
            <div key={idx}>
              {/* Group Title - hidden on desktop collapsed, visible on hover/mobile */}
              <h3 className="px-5 mb-3 text-[11px] font-bold text-gray-400 dark:text-slate-500 uppercase tracking-widest transition-opacity duration-300 lg:opacity-0 lg:group-hover:opacity-100 h-4 overflow-hidden">
                <span className="lg:hidden lg:group-hover:inline-block whitespace-nowrap">{group.title}</span>
              </h3>

              <div className="space-y-1">
                {group.items.map((item) => {
                  const Icon = item.icon;
                  return (
                    <NavLink
                      key={item.path}
                      to={item.path}
                      onClick={() => {
                        // Close sidebar on mobile when a link is clicked
                        if (window.innerWidth < 1024) onClose();
                      }}
                      className={({ isActive }) => `
                        flex items-center relative transition-all duration-300 group/navitem rounded-xl
                        /* Mobile Padding */
                        px-3 py-2.5
                        /* Desktop Collapsed */
                        lg:px-1 lg:py-3 lg:justify-center
                        /* Desktop Expanded */
                        lg:group-hover:px-4 lg:group-hover:py-3 lg:group-hover:justify-start
                        ${isActive
                          ? 'bg-gray-100 dark:bg-slate-700/50 text-gray-900 dark:text-white font-semibold'
                          : 'text-gray-500 dark:text-slate-400 font-medium hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-slate-700/30'
                        }
                      `}
                      // Tooltip for collapsed state
                      title={item.label}
                    >
                      {({ isActive }) => (
                        <>
                          <div className={`flex items-center justify-center shrink-0 transition-all duration-300
                            /* Mobile Size */
                            w-8 h-8 rounded-lg
                            /* Desktop Collapsed Size */
                            lg:w-11 lg:h-11 lg:rounded-xl
                            /* Desktop Expanded Size */
                            lg:group-hover:w-9 lg:group-hover:h-9 lg:group-hover:rounded-lg
                            ${isActive ? 'text-gray-900 dark:text-white' : 'text-gray-400 dark:text-slate-500 group-hover/navitem:text-gray-700 dark:group-hover/navitem:text-white'}
                          `}>
                            <Icon
                              className="transition-all duration-300 w-[18px] h-[18px] lg:w-[22px] lg:h-[22px] lg:group-hover:w-5 lg:group-hover:h-5 group-hover/navitem:scale-125 group-hover/navitem:animate-[icon-shake_0.4s_ease-out]"
                              strokeWidth={isActive ? 2.5 : 2}
                            />
                          </div>

                          {/* Label Text */}
                          <div className={`
                            whitespace-nowrap transition-all duration-300 overflow-hidden flex items-center
                            /* Mobile */
                            ml-3
                            /* Desktop Collapsed */
                            lg:max-w-0 lg:opacity-0 lg:ml-0
                            /* Desktop Expanded */
                            lg:group-hover:max-w-xs lg:group-hover:opacity-100 lg:group-hover:ml-3
                          `}>
                            <span className={isActive ? 'text-gray-900 dark:text-white' : 'text-gray-600 dark:text-slate-300'}>
                              {item.label}
                            </span>
                          </div>
                        </>
                      )}
                    </NavLink>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        {/* Footer with User Info + Theme Toggle */}
        <div className="p-3 shrink-0 border-t border-gray-100 dark:border-slate-700/50 py-4">
          {/* Theme Toggle Button */}
          <button
            onClick={toggleTheme}
            title={isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'}
            className="w-full flex items-center transition-all duration-300 group/theme rounded-xl text-gray-500 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-slate-700/40 mb-2
              /* Mobile Padding */
              p-3
              /* Desktop Collapsed */
              lg:p-3 lg:justify-center
              /* Desktop Expanded */
              lg:group-hover:px-4 lg:group-hover:justify-start
            "
          >
            <div className="shrink-0 flex items-center justify-center transition-all duration-300
              /* Mobile */
              w-6 h-6
              /* Desktop Collapsed */
              lg:w-8 lg:h-8
              /* Desktop Expanded */
              lg:group-hover:w-6 lg:group-hover:h-6
            ">
              {isDark
                ? <Sun className="transition-all duration-300 group-hover/theme:scale-125 group-hover/theme:animate-[icon-shake_0.4s_ease-out] w-[18px] h-[18px] lg:w-5 lg:h-5 lg:group-hover:w-[18px] lg:group-hover:h-[18px] text-amber-400" strokeWidth={2} />
                : <Moon className="transition-all duration-300 group-hover/theme:scale-125 group-hover/theme:animate-[icon-shake_0.4s_ease-out] w-[18px] h-[18px] lg:w-5 lg:h-5 lg:group-hover:w-[18px] lg:group-hover:h-[18px]" strokeWidth={2} />
              }
            </div>
            <div className={`
              transition-all duration-300 overflow-hidden flex items-center
              /* Mobile */
              ml-3
              /* Desktop Collapsed */
              lg:max-w-0 lg:opacity-0 lg:ml-0
              /* Desktop Expanded */
              lg:group-hover:max-w-xs lg:group-hover:opacity-100 lg:group-hover:ml-3
            `}>
              <span className="text-xs font-bold whitespace-nowrap">{isDark ? 'Modo Claro' : 'Modo Oscuro'}</span>
            </div>
          </button>

          {/* User Profile Link */}
          <NavLink
            to="/profile"
            onClick={() => { if (window.innerWidth < 1024) onClose(); }}
            className="bg-slate-900 rounded-2xl border border-slate-800 flex items-center transition-all hover:bg-black group/profile overflow-hidden
              /* Mobile Padding */
              p-2
              /* Desktop Collapsed */
              lg:p-1.5 lg:justify-center
              /* Desktop Expanded */
              lg:group-hover:p-2 lg:group-hover:justify-start
            "
            title="Ir a Perfil"
          >
            <div className="shrink-0 relative transition-all duration-300 lg:scale-110 lg:group-hover:scale-100">
              <UserAvatar src={userData?.fotoUrl} name={userData?.nombre} size="sm" className="border border-slate-700 shadow-md group-hover/profile:scale-105 transition-transform" />
              {/* Status indicator */}
              <div className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-green-500 border-2 border-slate-900 rounded-full"></div>
            </div>

            <div className={`
              min-w-0 flex-col justify-center transition-all duration-300 overflow-hidden
              /* Mobile */
              ml-3 flex
              /* Desktop Collapsed */
              lg:max-w-0 lg:opacity-0 lg:ml-0
              /* Desktop Expanded */
              lg:group-hover:max-w-xs lg:group-hover:opacity-100 lg:group-hover:flex lg:group-hover:ml-3
            `}>
              <p className="text-sm font-bold text-white truncate tracking-tight">
                {(userData?.nombre && userData?.nombre !== 'Usuario')
                  ? userData.nombre.replace(/^\d+\s+/, '').split(' ')[0]
                  : (userData?.email ? userData.email.split('@')[0] : 'Usuario')}
              </p>
              <p className="text-[10px] text-slate-400 font-bold truncate uppercase tracking-widest mt-0.5">
                {userData?.rol || 'Alumno'}
              </p>
            </div>
          </NavLink>

          <div className="mt-2 text-center">
            <button
              onClick={logout}
              title="Cerrar Sesión"
              className="w-full flex items-center transition-all duration-300 group/logout rounded-xl text-slate-500 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-slate-700/40
                /* Mobile Padding */
                p-3
                /* Desktop Collapsed */
                lg:p-3 lg:justify-center
                /* Desktop Expanded */
                lg:group-hover:px-4 lg:group-hover:justify-start
              "
            >
              <div className="shrink-0 flex items-center justify-center transition-all duration-300
                /* Mobile */
                w-6 h-6
                /* Desktop Collapsed */
                lg:w-8 lg:h-8
                /* Desktop Expanded */
                lg:group-hover:w-6 lg:group-hover:h-6
              ">
                <LogOut className="group-hover/logout:scale-125 group-hover/logout:animate-[icon-shake_0.4s_ease-out] transition-all duration-300 w-[18px] h-[18px] lg:w-5 lg:h-5 lg:group-hover:w-[18px] lg:group-hover:h-[18px]" strokeWidth={2} />
              </div>
              <div className={`
                transition-all duration-300 overflow-hidden flex items-center
                /* Mobile */
                ml-3
                /* Desktop Collapsed */
                lg:max-w-0 lg:opacity-0 lg:ml-0
                /* Desktop Expanded */
                lg:group-hover:max-w-xs lg:group-hover:opacity-100 lg:group-hover:ml-3
              `}>
                <span className="text-xs font-bold whitespace-nowrap">Cerrar Sesión</span>
              </div>
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
