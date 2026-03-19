# 📁 Módulo 01: Estructura Base del Proyecto

> **Objetivo:** Crear la estructura de carpetas y configurar los proyectos base de .NET y React.  
> **Complejidad:** 🟢 Baja  
> **Dependencias:** Ninguna

---

## 🎯 Entregables

- [ ] Estructura de carpetas `/backend` y `/frontend`
- [ ] Solución .NET 8/9 con proyecto Web API
- [ ] Proyecto React 18 + Vite configurado
- [ ] Tailwind CSS instalado
- [ ] Archivos de configuración base

---

## 📂 Estructura de Carpetas a Crear

```
/IntegradorHub-Root
│
├── /backend
│   └── /src
│       └── /IntegradorHub.API
│           ├── /Features
│           │   ├── /Auth
│           │   ├── /Projects
│           │   └── /Evaluations
│           ├── /Shared
│           │   ├── /Domain
│           │   ├── /Infrastructure
│           │   └── /Abstractions
│           ├── Program.cs
│           └── appsettings.json
│
├── /frontend
│   └── /src
│       ├── /features
│       │   ├── /auth
│       │   ├── /project-canvas
│       │   └── /showcase
│       ├── /components
│       │   ├── /ui
│       │   └── /feedback
│       ├── /lib
│       ├── /routes
│       ├── App.jsx
│       └── main.jsx
│
└── /docs
    ├── /architecture
    └── /user-manuals
```

---

## 🔧 Tareas de Implementación

### 1. Backend (.NET 8/9)

#### 1.1 Crear Solución y Proyecto
```bash
# Navegar a la carpeta del proyecto
cd /Users/uzielcastillo/Development/IntegradorHub

# Crear carpeta backend
mkdir -p backend/src

# Crear solución
dotnet new sln -n IntegradorHub -o backend

# Crear proyecto Web API
dotnet new webapi -n IntegradorHub.API -o backend/src/IntegradorHub.API

# Agregar proyecto a la solución
cd backend
dotnet sln add src/IntegradorHub.API/IntegradorHub.API.csproj
```

#### 1.2 Instalar Paquetes NuGet Esenciales
```bash
cd src/IntegradorHub.API

# MediatR para CQRS
dotnet add package MediatR
dotnet add package MediatR.Extensions.Microsoft.DependencyInjection

# FluentValidation
dotnet add package FluentValidation
dotnet add package FluentValidation.DependencyInjectionExtensions

# Firebase Admin SDK
dotnet add package FirebaseAdmin
dotnet add package Google.Cloud.Firestore

# Swagger (ya incluido en webapi template)
# CORS
dotnet add package Microsoft.AspNetCore.Cors
```

#### 1.3 Crear Estructura de Carpetas Backend
```bash
mkdir -p Features/Auth/Login
mkdir -p Features/Auth/IdentifyRole
mkdir -p Features/Projects/Create
mkdir -p Features/Projects/EditCanvas
mkdir -p Features/Projects/GetByGroup
mkdir -p Features/Projects/AddMember
mkdir -p Features/Evaluations/SubmitFeedback
mkdir -p Shared/Domain
mkdir -p Shared/Infrastructure
mkdir -p Shared/Abstractions
mkdir -p Shared/Behaviors
```

---

### 2. Frontend (React 18 + Vite)

#### 2.1 Crear Proyecto Vite
```bash
cd /Users/uzielcastillo/Development/IntegradorHub

# Crear proyecto con Vite
npm create vite@latest frontend -- --template react

# Instalar dependencias
cd frontend
npm install
```

#### 2.2 Instalar Dependencias Esenciales
```bash
# Tailwind CSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Routing
npm install react-router-dom

# HTTP Client
npm install axios

# Firebase Client SDK
npm install firebase

# Iconos
npm install lucide-react

# Estado Global (opcional)
npm install zustand
```

#### 2.3 Configurar Tailwind CSS

**tailwind.config.js:**
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Colores institucionales UTM
        'utm-green': '#00843D',
        'utm-dark': '#003B23',
        'dsm-blue': '#0078D4',
        'dsm-light': '#4DA6FF',
      },
    },
  },
  plugins: [],
}
```

**src/index.css:**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Estilos base estilo Teams/Notion */
:root {
  --color-primary: #0078D4;
  --color-secondary: #00843D;
  --sidebar-width: 250px;
}
```

#### 2.4 Crear Estructura de Carpetas Frontend
```bash
cd src

# Features
mkdir -p features/auth/components
mkdir -p features/auth/hooks
mkdir -p features/project-canvas/components
mkdir -p features/project-canvas/api
mkdir -p features/project-canvas/hooks
mkdir -p features/showcase/components

# Componentes genéricos
mkdir -p components/ui
mkdir -p components/feedback
mkdir -p components/layout

# Infraestructura
mkdir -p lib
mkdir -p routes
mkdir -p utils
```

---

## ✅ Verificación

| Verificación | Comando | Resultado Esperado |
|--------------|---------|-------------------|
| Backend compila | `dotnet build` | Build succeeded |
| Frontend inicia | `npm run dev` | Vite server running |
| Estructura correcta | `tree backend/src` | Carpetas visibles |

---

## 📝 Archivos Base a Crear

### Backend: `Program.cs` (Esqueleto)
```csharp
using MediatR;

var builder = WebApplication.CreateBuilder(args);

// Servicios
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly));

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### Frontend: `App.jsx` (Esqueleto)
```jsx
import { BrowserRouter, Routes, Route } from 'react-router-dom'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<div>IntegradorHub - DSM Edition</div>} />
        <Route path="/login" element={<div>Login</div>} />
        <Route path="/dashboard" element={<div>Dashboard</div>} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
```

---

## ➡️ Siguiente Módulo

Una vez completado, continuar con [**Módulo 02: Configuración Firebase**](./02_CONFIG_FIREBASE.md)
