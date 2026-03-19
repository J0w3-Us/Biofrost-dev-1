import { createContext, useContext, useState, useEffect } from 'react';

const ThemeContext = createContext();

export function ThemeProvider({ children }) {
    const [theme, setTheme] = useState(() => {
        // 1. Revisar localStorage primero
        const saved = localStorage.getItem('theme');
        if (saved === 'dark' || saved === 'light') return saved;
        // 2. Luego preferencia del sistema
        if (window.matchMedia?.('(prefers-color-scheme: dark)').matches) return 'dark';
        // 3. Default: light
        return 'light';
    });

    useEffect(() => {
        const root = document.documentElement;
        if (theme === 'dark') {
            root.classList.add('dark');
        } else {
            root.classList.remove('dark');
        }
        localStorage.setItem('theme', theme);
    }, [theme]);

    const toggleTheme = () => setTheme(prev => prev === 'dark' ? 'light' : 'dark');
    const isDark = theme === 'dark';

    return (
        <ThemeContext.Provider value={{ theme, toggleTheme, isDark }}>
            {children}
        </ThemeContext.Provider>
    );
}

export function useTheme() {
    const context = useContext(ThemeContext);
    if (!context) {
        // Fallback seguro: si se usa fuera del Provider, no crashea
        return { theme: 'light', toggleTheme: () => { }, isDark: false };
    }
    return context;
}
