import createGlobe from "cobe";
import { useEffect, useRef } from "react";

export function GlobeBanner() {
    const canvasRef = useRef();

    useEffect(() => {
        let phi = 0;
        const size = 260;

        const globe = createGlobe(canvasRef.current, {
            devicePixelRatio: 1,
            width: size,
            height: size,
            phi: 0,
            theta: 0.1,
            dark: 1,
            diffuse: 1.2,
            mapSamples: 8000,
            mapBrightness: 6,
            baseColor: [0.1, 0.2, 0.4],
            markerColor: [0.1, 0.5, 1],
            glowColor: [0.05, 0.1, 0.35],
            markers: [
                { location: [20.9674, -89.6227], size: 0.08 }, // Mérida
                { location: [19.4326, -99.1332], size: 0.05 }, // CDMX
                { location: [37.7749, -122.4194], size: 0.05 } // SF
            ],
            onRender: (state) => {
                state.phi = phi;
                phi += 0.002;
            },
        });

        return () => {
            globe.destroy();
        };
    }, []);

    return (
        // Posicionado en la mitad derecha del banner, centrado verticalmente
        // Sin overflow hidden ni transforms que lo corten
        <div
            className="absolute inset-0 flex items-center justify-end pr-16 pointer-events-none"
            style={{ mixBlendMode: 'screen' }}
        >
            <canvas
                ref={canvasRef}
                style={{
                    width: 260,
                    height: 260,
                    opacity: 0.92,
                }}
            />
        </div>
    );
}
