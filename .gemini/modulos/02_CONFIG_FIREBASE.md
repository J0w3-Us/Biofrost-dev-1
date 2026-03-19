# 🔥 Módulo 02: Configuración de Firebase

> **Objetivo:** Configurar Firebase Admin SDK (Backend) y Firebase Client SDK (Frontend)  
> **Complejidad:** 🟡 Media  
> **Dependencias:** Módulo 01 completado

---

## 🎯 Entregables

- [ ] Proyecto Firebase creado en la consola
- [ ] Firebase Admin SDK configurado en .NET
- [ ] Firebase Client SDK configurado en React
- [ ] Firestore habilitado con colecciones base
- [ ] Firebase Storage habilitado
- [ ] Google Auth Provider habilitado

---

## 🔧 Configuración de la Consola Firebase

### 1. Crear Proyecto
1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto: `integrador-hub-dsm`
3. Habilitar Google Analytics (opcional)

### 2. Habilitar Servicios

#### Authentication
- Ir a **Authentication → Sign-in method**
- Habilitar **Google** como proveedor
- Configurar dominio autorizado: `localhost`

#### Firestore Database
- Ir a **Firestore Database → Create database**
- Seleccionar modo **Production**
- Ubicación: `us-central1` (o la más cercana)

#### Storage
- Ir a **Storage → Get started**
- Configurar reglas iniciales

---

## 📁 Estructura de Colecciones Firestore

```
/public/data/
├── /users                 # Perfiles de usuarios
│   └── {uid}
│       ├── nombre_completo: string
│       ├── rol: enum ['alumno', 'docente', 'invitado', 'admin']
│       ├── email: string
│       ├── matricula: string (solo alumnos)
│       ├── grupo_id: string (ej: "5B")
│       ├── especialidad: string
│       ├── organizacion: string (solo invitados)
│       ├── grupos_docente: array [string]
│       └── prioridad_docente: boolean
│
├── /projects              # Proyectos integradores
│   └── {projectId}
│       ├── titulo: string
│       ├── slug: string
│       ├── lider_id: string
│       ├── miembros: array [uid]
│       ├── grupo_contexto: string
│       ├── docente_asignado: uid
│       ├── estado: enum ['borrador', 'privado', 'publico', 'historico']
│       ├── content_blocks: array [object]
│       ├── stack_tecnico: array [string]
│       └── fecha_creacion: timestamp
│
├── /evaluations           # Feedback de docentes
│   └── {evalId}
│       ├── proyecto_id: string
│       ├── docente_id: uid
│       ├── comentario: string
│       ├── tipo: enum ['oficial', 'sugerencia']
│       └── visto_por_equipo: boolean
│
├── /groups                # Catálogo de grupos
│   └── {groupId}
│       ├── nombre: string (ej: "5B")
│       ├── carrera: string ("DSM")
│       └── cuatrimestre: string
│
└── /materias              # Catálogo de materias (Admin)
    └── {materiaId}
        ├── nombre: string
        ├── clave: string
        └── activa: boolean
```

---

## 🔧 Backend: Firebase Admin SDK (.NET)

### 1. Descargar Service Account Key
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Guardar como `firebase-admin-key.json`

> ⚠️ **IMPORTANTE:** Este archivo NUNCA debe subirse a Git

### 2. Configurar en .NET

**Crear archivo: `Shared/Infrastructure/FirestoreContext.cs`**
```csharp
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Infrastructure;

public class FirestoreContext
{
    private static FirestoreDb? _db;
    
    public static FirestoreDb GetDatabase()
    {
        if (_db == null)
        {
            // Configurar credenciales
            Environment.SetEnvironmentVariable(
                "GOOGLE_APPLICATION_CREDENTIALS", 
                "firebase-admin-key.json"
            );
            
            _db = FirestoreDb.Create("integrador-hub-dsm");
        }
        
        return _db;
    }
    
    // Colecciones principales
    public static CollectionReference Users => 
        GetDatabase().Collection("public/data/users");
    
    public static CollectionReference Projects => 
        GetDatabase().Collection("public/data/projects");
    
    public static CollectionReference Evaluations => 
        GetDatabase().Collection("public/data/evaluations");
    
    public static CollectionReference Groups => 
        GetDatabase().Collection("public/data/groups");
}
```

**Agregar a `appsettings.json`:**
```json
{
  "Firebase": {
    "ProjectId": "integrador-hub-dsm"
  }
}
```

**Agregar a `.gitignore`:**
```
firebase-admin-key.json
appsettings.Development.json
```

---

## 🔧 Frontend: Firebase Client SDK (React)

### 1. Obtener Configuración Web
1. Firebase Console → Project Settings → Your apps → Web
2. Registrar app: `integrador-hub-frontend`
3. Copiar configuración

### 2. Crear Archivo de Configuración

**Crear: `src/lib/firebase.js`**
```javascript
import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

// Inicializar Firebase
const app = initializeApp(firebaseConfig);

// Servicios
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

// Proveedores
export const googleProvider = new GoogleAuthProvider();
googleProvider.setCustomParameters({
  prompt: 'select_account'
});

export default app;
```

### 3. Variables de Entorno

**Crear: `.env.local`**
```env
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=integrador-hub-dsm.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=integrador-hub-dsm
VITE_FIREBASE_STORAGE_BUCKET=integrador-hub-dsm.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
```

**Agregar a `.gitignore`:**
```
.env.local
.env.*.local
```

---

## 🔒 Reglas de Seguridad Firestore (Iniciales)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper: Verificar si está autenticado
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper: Verificar rol
    function hasRole(role) {
      return get(/databases/$(database)/documents/public/data/users/$(request.auth.uid)).data.rol == role;
    }
    
    // Usuarios
    match /public/data/users/{userId} {
      allow read: if isAuthenticated();
      allow write: if request.auth.uid == userId || hasRole('admin');
    }
    
    // Proyectos (reglas simplificadas iniciales)
    match /public/data/projects/{projectId} {
      allow read: if true; // Públicos legibles
      allow write: if isAuthenticated();
    }
    
    // Evaluaciones
    match /public/data/evaluations/{evalId} {
      allow read: if isAuthenticated();
      allow write: if hasRole('docente') || hasRole('admin');
    }
  }
}
```

---

## ✅ Verificación

| Verificación | Método | Resultado Esperado |
|--------------|--------|-------------------|
| Firestore conecta (.NET) | Ejecutar query de prueba | Sin errores |
| Firebase Auth funciona | Intentar login con Google | Token recibido |
| Colecciones existen | Ver en Firebase Console | Colecciones visibles |

### Test de Conexión Backend
```csharp
// Agregar endpoint temporal para probar
[HttpGet("test-firestore")]
public async Task<IActionResult> TestFirestore()
{
    var users = FirestoreContext.Users;
    var snapshot = await users.Limit(1).GetSnapshotAsync();
    return Ok($"Conexión exitosa. Documentos: {snapshot.Count}");
}
```

---

## ➡️ Siguiente Módulo

Continuar con [**Módulo 03: Dominio y Entidades**](./03_DOMINIO_ENTIDADES.md)
