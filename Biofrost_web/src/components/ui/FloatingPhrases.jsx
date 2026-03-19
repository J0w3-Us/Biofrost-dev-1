import { useState, useEffect } from 'react';

const TESTIMONIALS = [
    {
        text: "Construye soluciones robustas y fluidas. La arquitectura moderna nos permite iterar mucho más rápido en tu nuevo proyecto.",
        tags: "#buildinpublic #DSM",
        handle: "@innovador_utm",
        avatar: "Felix"
    },
    {
        text: "Crea experiencias digitales increíbles. Es fascinante cómo las tecnologías modernas simplifican el trabajo para desarrolladores.",
        tags: "#coding #Byfrost",
        handle: "@dev_student",
        avatar: "Aneka"
    },
    {
        text: "Innova sin preocuparte por la infraestructura subyacente. Compartir y evaluar proyectos nunca había sido tan ágil.",
        tags: "#tech #innovation",
        handle: "@tech_builder",
        avatar: "Zoey"
    },
    {
        text: "Diseña el mañana colaborando de manera eficiente. Todo el flujo de trabajo está integrado en una sola plataforma.",
        tags: "#software #design",
        handle: "@code_ninja",
        avatar: "Jack"
    },
    {
        text: "Colabora con otros estudiantes y lleva tus ideas al siguiente nivel utilizando herramientas de vanguardia.",
        tags: "#teamwork #community",
        handle: "@dsm_creator",
        avatar: "Oliver"
    }
];

export function FloatingPhrases({ isDark }) {
    const [leftIndex, setLeftIndex] = useState(0);
    const [rightIndex, setRightIndex] = useState(1);
    
    const [leftVisible, setLeftVisible] = useState(true);
    const [rightVisible, setRightVisible] = useState(true);
    
    // Hide on tablets/mobile to prevent overlapping the login form
    const [isMobile, setIsMobile] = useState(window.innerWidth < 1100);

    useEffect(() => {
        const handleResize = () => setIsMobile(window.innerWidth < 1100);
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    useEffect(() => {
        // Change left phrase every 5 seconds
        const changeLeft = setInterval(() => {
            setLeftVisible(false);
            setTimeout(() => {
                setLeftIndex(prev => (prev + 2) % TESTIMONIALS.length);
                // Esperamos un momento breve antes de volver a mostrar para asegurar que el DOM actualizó el texto invisible
                setTimeout(() => {
                    setLeftVisible(true);
                }, 50); 
            }, 500); // 0.5s fade out duration coincidiendo con la transición CSS
        }, 5000);

        // Change right phrase every 7 seconds
        const changeRight = setInterval(() => {
            setRightVisible(false);
            setTimeout(() => {
                setRightIndex(prev => {
                    let next = (prev + 2) % TESTIMONIALS.length;
                    if (next === leftIndex) next = (next + 1) % TESTIMONIALS.length; // avoid duplicates
                    return next;
                });
                setTimeout(() => {
                    setRightVisible(true);
                }, 50);
            }, 500); // 0.5s fade out duration
        }, 7000);

        return () => {
            clearInterval(changeLeft);
            clearInterval(changeRight);
        };
    }, [leftIndex]);

    if (isMobile) return null;

    const textColor = isDark ? '#f9fafb' : '#111827';
    // Muted color for tags and handle
    const mutedColor = isDark ? '#9ca3af' : '#4b5563'; 
    // Faint color for the large background quote mark
    const quoteColor = isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)';

    const Card = ({ item, isVisible, position }) => {
        const isLeft = position === 'left';
        
        return (
            <div style={{
                position: 'absolute',
                top: isLeft ? '28%' : '42%',
                [isLeft ? 'left' : 'right']: '6%',
                width: '320px',
                opacity: isVisible ? 1 : 0,
                // Combine a slight vertical float with the fade
                transform: isVisible ? 'translateY(0)' : 'translateY(15px)',
                transition: 'opacity 0.5s ease-in-out, transform 0.5s ease-in-out',
                pointerEvents: 'none',
                zIndex: 5,
                display: 'flex',
                flexDirection: 'column'
            }}>
                {/* Large Background Quote Mark */}
                <div style={{
                    fontSize: '140px',
                    fontFamily: 'serif',
                    color: quoteColor,
                    position: 'absolute',
                    top: '-60px',
                    left: '-30px',
                    zIndex: -1,
                    lineHeight: 1,
                    userSelect: 'none',
                    fontWeight: 700
                }}>
                    “
                </div>
                
                {/* Main Phrase */}
                <p style={{
                    fontSize: '22px',
                    fontWeight: '500',
                    lineHeight: '1.45',
                    color: textColor,
                    margin: '0 0 8px 0',
                    letterSpacing: '-0.02em',
                    fontFamily: "'Inter', sans-serif"
                }}>
                    {item.text}
                </p>
                
                {/* Hashtags */}
                <p style={{
                    fontSize: '20px',
                    fontWeight: '500',
                    color: textColor,
                    margin: '0 0 24px 0',
                    fontFamily: "'Inter', sans-serif"
                }}>
                    {item.tags}
                </p>
                
                {/* User Info Row */}
                <div style={{ display: 'flex', alignItems: 'center' }}>
                    <div style={{
                        width: '40px',
                        height: '40px',
                        borderRadius: '50%',
                        backgroundColor: isDark ? '#374151' : '#e5e7eb',
                        overflow: 'hidden',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                    }}>
                        <img 
                            src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${item.avatar}`} 
                            alt="avatar" 
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
                        />
                    </div>
                    <span style={{
                        marginLeft: '12px',
                        fontSize: '15px',
                        fontWeight: '500',
                        color: textColor,
                        fontFamily: "'Inter', sans-serif"
                    }}>
                        {item.handle}
                    </span>
                </div>
            </div>
        );
    };

    return (
        <div style={{
            position: 'absolute',
            top: 0, left: 0, width: '100%', height: '100%', 
            pointerEvents: 'none',
            zIndex: 10
        }}>
            <Card item={TESTIMONIALS[leftIndex]} isVisible={leftVisible} position="left" />
            <Card item={TESTIMONIALS[rightIndex]} isVisible={rightVisible} position="right" />
        </div>
    );
}
