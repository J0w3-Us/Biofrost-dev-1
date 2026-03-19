import { Suspense, useEffect, useState, useRef, useMemo } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { useGLTF, Environment, Stars, PerspectiveCamera } from '@react-three/drei';
import * as THREE from 'three';
import { FloatingPhrases } from './FloatingPhrases';

// ─── Responsive config (valores calibrados con el modelo 4K) ───────────────
function getConfig(width) {
    if (width <= 640) {
        // Móvil: subimos más el edificio (posY menos negativo) y acercamos la cámara
        return { posX: 0, posY: -1.8, posZ: -0.3, rotX: 0, baseRotY: -1.4, rotZ: 0, scale: 9, cameraZ: 11, cameraY: 1.2 };
    }
    if (width <= 1024) {
        // Tablet
        return { posX: 0, posY: -1.8, posZ: -0.3, rotX: 0, baseRotY: -1.4, rotZ: 0, scale: 12, cameraZ: 10, cameraY: 1.2 };
    }
    // Desktop
    return { posX: 0, posY: -1.8, posZ: -0.3, rotX: 0, baseRotY: -1.4, rotZ: 0, scale: 14.3, cameraZ: 9.0, cameraY: 1.5 };
}

function useResponsiveConfig() {
    const [config, setConfig] = useState(() => getConfig(window.innerWidth));
    useEffect(() => {
        const onResize = () => setConfig(getConfig(window.innerWidth));
        window.addEventListener('resize', onResize);
        return () => window.removeEventListener('resize', onResize);
    }, []);
    return config;
}

// ─── Niebla atmosférica que oculta la base ─────────────────────────────────
function SceneFog({ isDark }) {
    const { scene } = useThree();
    useEffect(() => {
        // FogExp2 crea niebla exponencial que se acumula en la distancia/parte baja
        const fogColor = isDark ? '#020617' : '#dbeafe';
        scene.fog = new THREE.Fog(fogColor, 8, 22);
        return () => { scene.fog = null; };
    }, [isDark, scene]);
    return null;
}

// ─── Partículas flotantes (polvo de ciudad) ────────────────────────────────
function FloatingParticles({ isDark, count = 120 }) {
    const points = useRef();
    const positions = useMemo(() => {
        const arr = new Float32Array(count * 3);
        for (let i = 0; i < count; i++) {
            arr[i * 3]     = (Math.random() - 0.5) * 20;  // x
            arr[i * 3 + 1] = (Math.random() - 0.5) * 12;  // y
            arr[i * 3 + 2] = (Math.random() - 0.5) * 10;  // z
        }
        return arr;
    }, [count]);

    useFrame((state) => {
        if (!points.current) return;
        points.current.rotation.y = state.clock.elapsedTime * 0.02;
    });

    const color = isDark ? '#60a5fa' : '#93c5fd';

    return (
        <points ref={points}>
            <bufferGeometry>
                <bufferAttribute
                    attach="attributes-position"
                    array={positions}
                    count={count}
                    itemSize={3}
                />
            </bufferGeometry>
            <pointsMaterial
                size={0.045}
                color={color}
                transparent
                opacity={isDark ? 0.6 : 0.35}
                sizeAttenuation
            />
        </points>
    );
}

// ─── Plano reflectante de suelo (efecto piso mojado) ────────────────────────
function ReflectiveGround({ isDark }) {
    return (
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -4.5, 0]} receiveShadow>
            <planeGeometry args={[60, 60]} />
            <meshStandardMaterial
                color={isDark ? '#030712' : '#c7d5f0'}
                metalness={0.3}
                roughness={0.7}
                transparent
                opacity={0.0}
            />
        </mesh>
    );
}

// ─── Modelo 3D con Animación de paneo ──────────────────────────────────────
function Model({ config, isRegister }) {
    const { scene } = useGLTF('/models/modern_office_building_4k.glb');
    const groupRef = useRef();

    const loginRotY   = config.baseRotY - 0.5;
    const loginPosY   = config.posY;
    const loginRotX   = config.rotX;

    const registerRotY = config.baseRotY + 0.6;
    const registerPosY = config.posY - 4.2;
    const registerRotX = config.rotX + 0.08;

    useFrame((state, delta) => {
        if (!groupRef.current) return;

        const targetRotY = isRegister ? registerRotY : loginRotY;
        const targetPosY = isRegister ? registerPosY : loginPosY;
        const targetRotX = isRegister ? registerRotX : loginRotX;

        groupRef.current.rotation.y = THREE.MathUtils.damp(groupRef.current.rotation.y, targetRotY, 3, delta);
        groupRef.current.rotation.x = THREE.MathUtils.damp(groupRef.current.rotation.x, targetRotX, 3, delta);
        groupRef.current.position.y = THREE.MathUtils.damp(groupRef.current.position.y, targetPosY, 3, delta);
    });

    return (
        <group
            ref={groupRef}
            position={[config.posX, loginPosY, config.posZ]}
            rotation={[loginRotX, loginRotY, config.rotZ]}
        >
            <primitive object={scene} scale={config.scale} />
        </group>
    );
}

useGLTF.preload('/models/modern_office_building_4k.glb');

// ─── Escena con iluminación cinematográfica ────────────────────────────────
function Scene({ isDark, config, isRegister }) {
    return (
        <>
            <PerspectiveCamera makeDefault position={[0, config.cameraY, config.cameraZ]} fov={42} />

            <SceneFog isDark={isDark} />

            {/* Luz ambiente base */}
            <ambientLight intensity={isDark ? 0.3 : 0.75} />

            {/* Luz principal direccional */}
            <directionalLight
                position={[8, 15, 12]}
                intensity={isDark ? 1.1 : 2.0}
                color={isDark ? '#e2e8f0' : '#ffffff'}
                castShadow
                shadow-mapSize={[2048, 2048]}
            />

            {/* Luz de relleno lateral izquierda — ilumina lado contrario */}
            <pointLight
                position={[-12, 6, 8]}
                intensity={isDark ? 1.0 : 1.4}
                color={isDark ? '#3b82f6' : '#e0eaff'}
                distance={55}
            />

            {/* Resplandor inferior — "ground bounce" */}
            <pointLight
                position={[0, -1, 6]}
                intensity={isDark ? 1.4 : 0.5}
                color={isDark ? '#60a5fa' : '#bfdbfe'}
                distance={28}
            />

            {/* Foco superior premium */}
            <spotLight
                position={[-4, 28, -2]}
                angle={0.35}
                penumbra={0.7}
                intensity={isDark ? 1.2 : 1.0}
                color={isDark ? '#818cf8' : '#dbeafe'}
                castShadow
            />

            {/* Luz de acento cálida — sólo en dark (neón urbano) */}
            {isDark && (
                <pointLight
                    position={[5, 0, 8]}
                    intensity={1.0}
                    color="#f59e0b"
                    distance={18}
                />
            )}

            {/* Luz de acento azul trasera para profundidad */}
            <pointLight
                position={[-2, 10, -8]}
                intensity={isDark ? 0.6 : 0.3}
                color={isDark ? '#1d4ed8' : '#93c5fd'}
                distance={40}
            />

            {/* Partículas flotantes */}
            <FloatingParticles isDark={isDark} count={100} />

            {/* Plano de suelo invisible (recibe sombras, se integra con la niebla) */}
            <ReflectiveGround isDark={isDark} />

            {/* Estrellas solo en dark */}
            {isDark && (
                <Stars radius={140} depth={60} count={7000} factor={5} saturation={0.3} fade speed={0.4} />
            )}

            <Suspense fallback={null}>
                <Model config={config} isRegister={isRegister} />
            </Suspense>

            <Environment preset={isDark ? 'night' : 'city'} />
        </>
    );
}

// ─── Loader esférico mientras carga el GLB ────────────────────────────────
function Loader() {
    return (
        <mesh>
            <sphereGeometry args={[0.4, 32, 32]} />
            <meshBasicMaterial color="#3b82f6" wireframe />
        </mesh>
    );
}

// ─── Componente exportado ──────────────────────────────────────────────────
export function CityBackground({ isDark = false, isRegister = false }) {
    const config = useResponsiveConfig();

    return (
        <>
        <div style={{
            position: 'fixed',
            top: 0, left: 0,
            width: '100vw', height: '100vh',
            zIndex: 0,
            overflow: 'hidden',
            pointerEvents: 'none',
            background: isDark
                ? 'linear-gradient(160deg, #020617 0%, #0a1628 45%, #0c1a3a 75%, #060c1a 100%)'
                : 'linear-gradient(160deg, #e8f0fe 0%, #dbeafe 40%, #eff6ff 75%, #f0f4ff 100%)',
            transition: 'background 1.2s cubic-bezier(0.4, 0, 0.2, 1)',
        }}>
            <Canvas shadows dpr={[1, 2]} style={{ pointerEvents: 'none' }}>
                <Suspense fallback={<Loader />}>
                    <Scene isDark={isDark} config={config} isRegister={isRegister} />
                </Suspense>
            </Canvas>

            {/* ── Gradiente inferior reforzado: oculta la base del edificio ── */}
            <div style={{
                position: 'absolute',
                bottom: 0, left: 0,
                width: '100%',
                height: '40%',
                background: isDark
                    ? 'linear-gradient(to top, #020617 0%, rgba(6,12,26,0.92) 30%, rgba(10,22,40,0.65) 65%, transparent 100%)'
                    : 'linear-gradient(to top, #dbeafe 0%, rgba(219,234,254,0.95) 30%, rgba(224,238,254,0.6) 65%, transparent 100%)',
                pointerEvents: 'none',
            }} />

            {/* ── Gradiente superior: funde el cielo ── */}
            <div style={{
                position: 'absolute',
                top: 0, left: 0,
                width: '100%',
                height: '20%',
                background: isDark
                    ? 'linear-gradient(to bottom, rgba(2,6,23,0.5) 0%, transparent 100%)'
                    : 'linear-gradient(to bottom, rgba(232,240,254,0.4) 0%, transparent 100%)',
                pointerEvents: 'none',
            }} />

            {/* ── Viñeta lateral para enfocar en el centro ── */}
            <div style={{
                position: 'absolute',
                top: 0, left: 0,
                width: '100%', height: '100%',
                background: isDark
                    ? 'radial-gradient(ellipse at 58% 42%, transparent 30%, rgba(2,6,23,0.5) 100%)'
                    : 'radial-gradient(ellipse at 58% 42%, transparent 30%, rgba(200,220,254,0.35) 100%)',
                pointerEvents: 'none',
            }} />

            {/* ── Brillo de horizonte (línea de luz en la base oculta) ── */}
            <div style={{
                position: 'absolute',
                bottom: '38%',
                left: 0,
                width: '100%',
                height: '80px',
                background: isDark
                    ? 'linear-gradient(to top, transparent 0%, rgba(59,130,246,0.06) 50%, transparent 100%)'
                    : 'linear-gradient(to top, transparent 0%, rgba(147,197,253,0.08) 50%, transparent 100%)',
                pointerEvents: 'none',
            }} />

            {/* ── Destellos decorativos de luz (modo oscuro) ── */}
            {isDark && (
                <>
                    <div style={{
                        position: 'absolute',
                        top: '15%', left: '8%',
                        width: '200px', height: '200px',
                        background: 'radial-gradient(circle, rgba(59,130,246,0.08) 0%, transparent 70%)',
                        pointerEvents: 'none',
                        borderRadius: '50%',
                    }} />
                    <div style={{
                        position: 'absolute',
                        top: '20%', right: '10%',
                        width: '160px', height: '160px',
                        background: 'radial-gradient(circle, rgba(129,140,248,0.07) 0%, transparent 70%)',
                        pointerEvents: 'none',
                        borderRadius: '50%',
                    }} />
                </>
            )}

            {/* ── Destellos decorativos de luz (modo claro) ── */}
            {!isDark && (
                <>
                    <div style={{
                        position: 'absolute',
                        top: '10%', left: '5%',
                        width: '280px', height: '280px',
                        background: 'radial-gradient(circle, rgba(147,197,253,0.15) 0%, transparent 70%)',
                        pointerEvents: 'none',
                        borderRadius: '50%',
                    }} />
                    <div style={{
                        position: 'absolute',
                        bottom: '30%', right: '5%',
                        width: '200px', height: '200px',
                        background: 'radial-gradient(circle, rgba(199,210,254,0.2) 0%, transparent 70%)',
                        pointerEvents: 'none',
                        borderRadius: '50%',
                    }} />
                </>
            )}
        </div>
        
        {/* Mensajes flotantes estilo testimonio - Montados fuera del contenedor de la ciudad para no verse afectados por el z-index general de 0 */}
        <FloatingPhrases isDark={isDark} />
        </>
    );
}

export default CityBackground;
