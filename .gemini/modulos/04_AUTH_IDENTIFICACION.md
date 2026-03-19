# 🔐 Módulo 04: Auth & Identificación de Roles

> **Objetivo:** Implementar autenticación con Google y clasificación automática de roles por correo  
> **Complejidad:** 🔴 Alta  
> **Dependencias:** Módulos 02 y 03 completados

---

## 🎯 Entregables

- [ ] Login con Google (Firebase Auth)
- [ ] Regex de clasificación de correo institucional
- [ ] Flujo de primer registro (configurar grupo/matrícula)
- [ ] Middleware de autenticación en .NET
- [ ] Context de autenticación en React
- [ ] Redirección automática según rol

---

## 🧠 Lógica de Enrutamiento de Dominio

```
┌──────────────────────────────────────────────────────────────────┐
│                     Usuario ingresa correo                       │
└───────────────────────────┬──────────────────────────────────────┘
                            │
                            ▼
            ┌───────────────────────────────┐
            │ ¿Es @utmetropolitana.edu.mx? │
            └───────────────┬───────────────┘
                   Sí       │       No
            ┌───────────────┴───────────────┐
            ▼                               ▼
   ┌────────────────┐              ┌────────────────┐
   │ ¿Inicia con    │              │  ROL: INVITADO │
   │  8 dígitos?    │              │  (Solo lectura)│
   └───────┬────────┘              └────────────────┘
      Sí   │   No
   ┌───────┴───────┐
   ▼               ▼
┌─────────┐  ┌─────────┐
│ ALUMNO  │  │ DOCENTE │
│ Extraer │  │ Asignar │
│ Matrí.  │  │ Grupos  │
└─────────┘  └─────────┘
```

---

## 🔧 Backend: Feature Auth

### Estructura de Archivos
```
/Features/Auth/
├── /Login
│   ├── LoginEndpoint.cs
│   ├── LoginCommand.cs
│   ├── LoginHandler.cs
│   └── LoginValidator.cs
├── /IdentifyRole
│   ├── IdentifyRoleEndpoint.cs
│   ├── IdentifyRoleQuery.cs
│   └── IdentifyRoleHandler.cs
└── /Register
    ├── CompleteRegistrationCommand.cs
    └── CompleteRegistrationHandler.cs
```

### 1. Endpoint de Login

**`Login/LoginEndpoint.cs`**
```csharp
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace IntegradorHub.API.Features.Auth.Login;

[ApiController]
[Route("api/auth")]
public class LoginEndpoint : ControllerBase
{
    private readonly IMediator _mediator;

    public LoginEndpoint(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginCommand command)
    {
        var result = await _mediator.Send(command);
        return Ok(result);
    }
}
```

**`Login/LoginCommand.cs`**
```csharp
using MediatR;

namespace IntegradorHub.API.Features.Auth.Login;

public record LoginCommand(
    string IdToken,     // Token de Firebase
    string Email,
    string DisplayName,
    string? PhotoUrl
) : IRequest<LoginResponse>;

public record LoginResponse(
    string UserId,
    string Email,
    string Rol,
    bool RequiereConfiguracion,  // True si es primera vez
    string? GrupoId,
    string? Matricula
);
```

**`Login/LoginHandler.cs`**
```csharp
using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.ValueObjects;
using IntegradorHub.API.Shared.Infrastructure;
using FirebaseAdmin.Auth;

namespace IntegradorHub.API.Features.Auth.Login;

public class LoginHandler : IRequestHandler<LoginCommand, LoginResponse>
{
    public async Task<LoginResponse> Handle(
        LoginCommand request, 
        CancellationToken cancellationToken)
    {
        // 1. Verificar token de Firebase
        var decodedToken = await FirebaseAuth.DefaultInstance
            .VerifyIdTokenAsync(request.IdToken, cancellationToken);
        
        var uid = decodedToken.Uid;
        
        // 2. Buscar usuario existente
        var userDoc = await FirestoreContext.Users.Document(uid).GetSnapshotAsync();
        
        if (userDoc.Exists)
        {
            // Usuario ya registrado
            var user = userDoc.ConvertTo<User>();
            return new LoginResponse(
                UserId: uid,
                Email: user.Email,
                Rol: user.Rol,
                RequiereConfiguracion: false,
                GrupoId: user.GrupoId,
                Matricula: user.Matricula
            );
        }
        
        // 3. Nuevo usuario - Clasificar por email
        var email = Email.Create(request.Email);
        var rol = email.Type switch
        {
            EmailType.Alumno => "alumno",
            EmailType.Docente => "docente",
            _ => "invitado"
        };
        
        // 4. Crear usuario base
        var newUser = new User
        {
            Id = uid,
            Email = request.Email,
            NombreCompleto = request.DisplayName,
            Rol = rol,
            Matricula = email.Matricula,
            FotoUrl = request.PhotoUrl,
            FechaRegistro = DateTime.UtcNow
        };
        
        await FirestoreContext.Users.Document(uid).SetAsync(newUser);
        
        // 5. Determinar si requiere configuración adicional
        bool requiereConfig = rol switch
        {
            "alumno" => true,  // Debe seleccionar grupo
            "docente" => true, // Debe seleccionar grupos a cargo
            _ => false
        };
        
        return new LoginResponse(
            UserId: uid,
            Email: request.Email,
            Rol: rol,
            RequiereConfiguracion: requiereConfig,
            GrupoId: null,
            Matricula: email.Matricula
        );
    }
}
```

### 2. Completar Registro (Selección de Grupo)

**`Register/CompleteRegistrationCommand.cs`**
```csharp
using MediatR;

namespace IntegradorHub.API.Features.Auth.Register;

public record CompleteRegistrationCommand(
    string UserId,
    string? GrupoId,               // Para alumnos
    List<string>? GruposDocente,   // Para docentes
    string? Especialidad
) : IRequest<bool>;
```

**`Register/CompleteRegistrationHandler.cs`**
```csharp
using MediatR;
using IntegradorHub.API.Shared.Infrastructure;
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Features.Auth.Register;

public class CompleteRegistrationHandler 
    : IRequestHandler<CompleteRegistrationCommand, bool>
{
    public async Task<bool> Handle(
        CompleteRegistrationCommand request, 
        CancellationToken cancellationToken)
    {
        var updates = new Dictionary<string, object>();
        
        if (!string.IsNullOrEmpty(request.GrupoId))
        {
            updates["grupo_id"] = request.GrupoId;
        }
        
        if (request.GruposDocente?.Any() == true)
        {
            updates["grupos_docente"] = request.GruposDocente;
        }
        
        if (!string.IsNullOrEmpty(request.Especialidad))
        {
            updates["especialidad"] = request.Especialidad;
        }
        
        await FirestoreContext.Users
            .Document(request.UserId)
            .UpdateAsync(updates);
        
        return true;
    }
}
```

---

## 🔧 Frontend: Auth Feature

### Estructura de Archivos
```
/src/features/auth/
├── /components
│   ├── LoginButton.jsx
│   ├── GoogleLoginButton.jsx
│   └── GroupSelector.jsx
├── /hooks
│   └── useAuth.js
└── /api
    └── authApi.js
```

### 1. Hook de Autenticación

**`hooks/useAuth.js`**
```javascript
import { useState, useEffect, createContext, useContext } from 'react';
import { 
  onAuthStateChanged, 
  signInWithPopup, 
  signOut 
} from 'firebase/auth';
import { auth, googleProvider } from '../../../lib/firebase';
import { loginUser, completeRegistration } from '../api/authApi';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [requiresSetup, setRequiresSetup] = useState(false);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        // Obtener token y hacer login en backend
        const idToken = await firebaseUser.getIdToken();
        
        try {
          const response = await loginUser({
            idToken,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL
          });
          
          setUser({
            ...response,
            firebaseUser
          });
          setRequiresSetup(response.requiereConfiguracion);
        } catch (error) {
          console.error('Error en login:', error);
        }
      } else {
        setUser(null);
        setRequiresSetup(false);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const loginWithGoogle = async () => {
    try {
      await signInWithPopup(auth, googleProvider);
    } catch (error) {
      console.error('Error en Google login:', error);
      throw error;
    }
  };

  const logout = async () => {
    await signOut(auth);
    setUser(null);
  };

  const completeSetup = async (data) => {
    await completeRegistration({
      userId: user.userId,
      ...data
    });
    setRequiresSetup(false);
    // Refrescar datos del usuario
    window.location.reload();
  };

  return (
    <AuthContext.Provider value={{
      user,
      loading,
      requiresSetup,
      isAlumno: user?.rol === 'alumno',
      isDocente: user?.rol === 'docente',
      isAdmin: user?.rol === 'admin',
      isInvitado: user?.rol === 'invitado',
      loginWithGoogle,
      logout,
      completeSetup
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth debe usarse dentro de AuthProvider');
  }
  return context;
};
```

### 2. Componente de Login

**`components/GoogleLoginButton.jsx`**
```jsx
import { useAuth } from '../hooks/useAuth';

export function GoogleLoginButton() {
  const { loginWithGoogle } = useAuth();

  const handleLogin = async () => {
    try {
      await loginWithGoogle();
    } catch (error) {
      console.error('Error al iniciar sesión:', error);
    }
  };

  return (
    <button
      onClick={handleLogin}
      className="flex items-center gap-3 px-6 py-3 bg-white border border-gray-300 rounded-lg shadow-sm hover:shadow-md transition-all"
    >
      <img 
        src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" 
        alt="Google" 
        className="w-5 h-5"
      />
      <span className="text-gray-700 font-medium">
        Continuar con Google
      </span>
    </button>
  );
}
```

### 3. Selector de Grupo (Primera vez)

**`components/GroupSelector.jsx`**
```jsx
import { useState, useEffect } from 'react';
import { useAuth } from '../hooks/useAuth';
import { getGroups } from '../api/authApi';

export function GroupSelector() {
  const { user, completeSetup, isAlumno, isDocente } = useAuth();
  const [groups, setGroups] = useState([]);
  const [selectedGroup, setSelectedGroup] = useState('');
  const [selectedGroups, setSelectedGroups] = useState([]);
  const [especialidad, setEspecialidad] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const loadGroups = async () => {
      const data = await getGroups();
      setGroups(data);
    };
    loadGroups();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    await completeSetup({
      grupoId: isAlumno ? selectedGroup : null,
      gruposDocente: isDocente ? selectedGroups : null,
      especialidad
    });
    
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white p-8 rounded-xl shadow-lg max-w-md w-full">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">
          Completa tu perfil
        </h2>
        
        {user?.matricula && (
          <p className="text-sm text-gray-600 mb-4">
            Matrícula detectada: <strong>{user.matricula}</strong>
          </p>
        )}
        
        <form onSubmit={handleSubmit} className="space-y-4">
          {isAlumno && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Selecciona tu grupo
              </label>
              <select
                value={selectedGroup}
                onChange={(e) => setSelectedGroup(e.target.value)}
                required
                className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-dsm-blue"
              >
                <option value="">-- Seleccionar --</option>
                {groups.map(g => (
                  <option key={g.id} value={g.id}>{g.nombre}</option>
                ))}
              </select>
            </div>
          )}
          
          {isDocente && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Grupos que atiendes este cuatrimestre
              </label>
              <div className="space-y-2">
                {groups.map(g => (
                  <label key={g.id} className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      value={g.id}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedGroups([...selectedGroups, g.id]);
                        } else {
                          setSelectedGroups(selectedGroups.filter(x => x !== g.id));
                        }
                      }}
                      className="rounded text-dsm-blue"
                    />
                    {g.nombre}
                  </label>
                ))}
              </div>
            </div>
          )}
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Especialidad / Rol técnico
            </label>
            <input
              type="text"
              value={especialidad}
              onChange={(e) => setEspecialidad(e.target.value)}
              placeholder="Ej: Fullstack Developer, UI/UX Designer"
              className="w-full p-3 border rounded-lg"
            />
          </div>
          
          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-dsm-blue text-white rounded-lg font-medium hover:bg-dsm-blue/90 disabled:opacity-50"
          >
            {loading ? 'Guardando...' : 'Continuar'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

### 4. API de Autenticación

**`api/authApi.js`**
```javascript
import axios from '../../../lib/axios';

export const loginUser = async (data) => {
  const response = await axios.post('/api/auth/login', data);
  return response.data;
};

export const completeRegistration = async (data) => {
  const response = await axios.post('/api/auth/complete-registration', data);
  return response.data;
};

export const getGroups = async () => {
  const response = await axios.get('/api/groups');
  return response.data;
};
```

---

## 🛡️ Protección de Rutas

**`/src/routes/ProtectedRoute.jsx`**
```jsx
import { Navigate } from 'react-router-dom';
import { useAuth } from '../features/auth/hooks/useAuth';
import { GroupSelector } from '../features/auth/components/GroupSelector';

export function ProtectedRoute({ children, allowedRoles = [] }) {
  const { user, loading, requiresSetup } = useAuth();

  if (loading) {
    return <div>Cargando...</div>;
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (requiresSetup) {
    return <GroupSelector />;
  }

  if (allowedRoles.length > 0 && !allowedRoles.includes(user.rol)) {
    return <Navigate to="/unauthorized" replace />;
  }

  return children;
}
```

---

## ✅ Verificación

| Verificación | Método | Resultado Esperado |
|--------------|--------|-------------------|
| Login Google | Click en botón | Popup de Google aparece |
| Detección Alumno | Login con matrícula@utm | Rol = alumno, matrícula extraída |
| Detección Docente | Login con nombre@utm | Rol = docente |
| Detección Invitado | Login con @gmail | Rol = invitado |
| Flujo primer registro | Nuevo usuario | Aparece GroupSelector |

---

## ➡️ Siguiente Módulo

Continuar con [**Módulo 05: Feature Projects CRUD**](./05_FEATURE_PROJECTS.md)
