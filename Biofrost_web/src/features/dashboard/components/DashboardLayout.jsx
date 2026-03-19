import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Menu } from 'lucide-react';

export function DashboardLayout() {
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    return (
        <div className="flex h-screen overflow-hidden bg-white dark:bg-[#0f1117]">
            {/* Sidebar - Handle responsive states (Mobile Modal vs Desktop Hover) inside */}
            <Sidebar
                isOpen={isMobileMenuOpen}
                onClose={() => setIsMobileMenuOpen(false)}
            />

            {/* Main Content Area */}
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                {/* Mobile Header (Topbar visible only on sm/md screens) */}
                <header className="lg:hidden flex items-center justify-between p-4 border-b border-gray-200 dark:border-slate-700/50 bg-white dark:bg-[#151821] shrink-0">
                    <div className="flex items-center gap-3">
                        {/* Logo Icon */}
                        <div className="w-12 h-12 bg-white rounded-2xl p-1 shadow-sm border border-gray-200 dark:border-slate-700 overflow-hidden shrink-0 flex items-center justify-center">
                            <img
                                src="/byfrost-icon.png"
                                alt="Byfrost Logo"
                                className="w-full h-full object-cover rounded-xl"
                            />
                        </div>
                        <h1 className="text-xl font-bold text-gray-900 dark:text-white leading-tight">Byfrost®</h1>
                    </div>
                    <button
                        onClick={() => setIsMobileMenuOpen(true)}
                        className="p-2 -mr-2 text-gray-600 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-slate-700/50 rounded-lg transition-colors"
                        aria-label="Abrir menú"
                    >
                        <Menu size={24} />
                    </button>
                </header>

                <main className="flex-1 overflow-y-auto scroll-smooth bg-gray-50/30 dark:bg-[#0f1117]">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}
