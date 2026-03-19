import { useState } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Clock, Users } from 'lucide-react';
import { motion } from 'framer-motion';

export function CalendarPage() {
    const [currentDate] = useState(new Date());
    
    // Get current month info
    const monthNames = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    const dayNames = ["L", "M", "M", "J", "V", "S", "D"];
    
    const currentMonth = currentDate.getMonth();
    const currentYear = currentDate.getFullYear();
    const today = currentDate.getDate();
    
    // Calculate days in month
    const firstDay = new Date(currentYear, currentMonth, 1).getDay();
    const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
    const adjustedFirstDay = firstDay === 0 ? 6 : firstDay - 1; // Adjust for Monday start
    
    // Generate calendar days
    const calendarDays = [];
    for (let i = 0; i < adjustedFirstDay; i++) {
        calendarDays.push(null);
    }
    for (let day = 1; day <= daysInMonth; day++) {
        calendarDays.push(day);
    }
    
    // Mock events
    const events = {
        15: { title: "Entrega Hito 1", color: "blue" },
        22: { title: "Revisión", color: "green" },
        28: { title: "Presentación", color: "indigo" }
    };

    return (
        <div className="space-y-6 h-full flex flex-col">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Agenda</h1>
                    <p className="text-gray-500">Próximas entregas y reuniones de equipo.</p>
                </div>
                <div className="flex gap-2">
                    <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                        <ChevronLeft size={20} className="text-gray-600" />
                    </button>
                    <button className="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-medium shadow-sm hover:bg-gray-50 transition-colors">
                        Hoy
                    </button>
                    <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                        <ChevronRight size={20} className="text-gray-600" />
                    </button>
                </div>
            </div>

            {/* Calendar Card */}
            <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex-1 bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden p-6"
            >
                {/* Calendar Header */}
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-bold text-gray-900">
                        {monthNames[currentMonth]} {currentYear}
                    </h2>
                    <div className="flex items-center gap-2">
                        <div className="flex items-center gap-2 text-xs">
                            <div className="flex items-center gap-1">
                                <div className="w-2 h-2 rounded-full bg-blue-500"></div>
                                <span className="text-gray-600">Entregas</span>
                            </div>
                            <div className="flex items-center gap-1">
                                <div className="w-2 h-2 rounded-full bg-green-500"></div>
                                <span className="text-gray-600">Reuniones</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Calendar Grid */}
                <div className="grid grid-cols-7 gap-2">
                    {/* Day Headers */}
                    {dayNames.map((day, idx) => (
                        <div key={idx} className="text-center text-xs font-semibold text-gray-500 py-2">
                            {day}
                        </div>
                    ))}
                    
                    {/* Calendar Days */}
                    {calendarDays.map((day, idx) => {
                        const isToday = day === today;
                        const hasEvent = day && events[day];
                        
                        return (
                            <motion.div
                                key={idx}
                                whileHover={day ? { scale: 1.05 } : {}}
                                className={`
                                    aspect-square flex flex-col items-center justify-center rounded-lg text-sm
                                    transition-all duration-200 relative
                                    ${!day ? 'invisible' : ''}
                                    ${isToday 
                                        ? 'bg-blue-600 text-white font-bold shadow-lg shadow-blue-200' 
                                        : hasEvent
                                        ? 'bg-blue-50 text-blue-600 font-semibold hover:bg-blue-100 cursor-pointer'
                                        : 'text-gray-700 hover:bg-gray-50 cursor-pointer'
                                    }
                                `}
                            >
                                {day}
                                {hasEvent && !isToday && (
                                    <div className={`absolute bottom-1 w-1 h-1 rounded-full ${
                                        hasEvent.color === 'blue' ? 'bg-blue-600' :
                                        hasEvent.color === 'green' ? 'bg-green-600' :
                                        'bg-indigo-600'
                                    }`} />
                                )}
                            </motion.div>
                        );
                    })}
                </div>

                {/* Upcoming Events */}
                <div className="mt-8 pt-6 border-t border-gray-100">
                    <h3 className="text-sm font-semibold text-gray-900 mb-4">Próximos Eventos</h3>
                    <div className="space-y-3">
                        <motion.div 
                            whileHover={{ x: 4 }}
                            className="p-4 border border-gray-100 rounded-xl flex items-center gap-3 bg-gradient-to-r from-blue-50 to-transparent hover:border-blue-200 transition-all cursor-pointer"
                        >
                            <div className="p-2 bg-blue-100 text-blue-600 rounded-lg">
                                <Clock size={16} />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-gray-900 text-sm">Entrega Final</p>
                                <p className="text-xs text-gray-500">25 Nov, 2026</p>
                            </div>
                            <ChevronRight size={16} className="text-gray-400" />
                        </motion.div>
                        
                        <motion.div 
                            whileHover={{ x: 4 }}
                            className="p-4 border border-gray-100 rounded-xl flex items-center gap-3 bg-gradient-to-r from-green-50 to-transparent hover:border-green-200 transition-all cursor-pointer"
                        >
                            <div className="p-2 bg-green-100 text-green-600 rounded-lg">
                                <Users size={16} />
                            </div>
                            <div className="flex-1">
                                <p className="font-semibold text-gray-900 text-sm">Revisión Semanal</p>
                                <p className="text-xs text-gray-500">Viernes, 10:00 AM</p>
                            </div>
                            <ChevronRight size={16} className="text-gray-400" />
                        </motion.div>
                    </div>
                </div>
            </motion.div>
        </div>
    );
}


