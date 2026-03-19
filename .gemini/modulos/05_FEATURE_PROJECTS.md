# 📋 Módulo 05: Feature Projects CRUD

> **Objetivo:** Implementar creación, edición y gestión de proyectos  
> **Complejidad:** 🔴 Alta  
> **Dependencias:** Módulos 03 y 04

---

## 🎯 Entregables

- [ ] Crear proyecto (solo Líder)
- [ ] Obtener proyectos por grupo
- [ ] Cambiar estado del proyecto
- [ ] Vista de listado y detalle

---

## 📁 Estructura Backend

```
/Features/Projects/
├── /Create
├── /GetByGroup
├── /GetById
├── /Update
└── /ChangeState
```

---

## 🔧 Implementación Clave

### CreateProjectCommand.cs
```csharp
public record CreateProjectCommand(
    string Titulo,
    string LiderId,
    string GrupoContexto,
    List<string>? StackTecnico
) : IRequest<CreateProjectResponse>;
```

### CreateProjectHandler.cs
```csharp
public async Task<CreateProjectResponse> Handle(
    CreateProjectCommand request, 
    CancellationToken ct)
{
    var slug = GenerateSlug(request.Titulo);
    
    var project = new Project
    {
        Titulo = request.Titulo,
        Slug = slug,
        LiderId = request.LiderId,
        GrupoContexto = request.GrupoContexto,
        StackTecnico = request.StackTecnico ?? new(),
        Estado = "borrador",
        FechaCreacion = DateTime.UtcNow
    };
    
    var docRef = await FirestoreContext.Projects.AddAsync(project);
    return new CreateProjectResponse(docRef.Id, slug, "borrador");
}
```

---

## 🔧 Frontend: API

**projectApi.js**
```javascript
export const createProject = (data) => 
  axios.post('/api/projects', data);

export const getProjectsByGroup = (grupoId) => 
  axios.get(`/api/projects/by-group/${grupoId}`);

export const changeProjectState = (id, estado) => 
  axios.patch(`/api/projects/${id}/state`, { estado });
```

---

## ✅ Verificación

| Test | Método | Esperado |
|------|--------|----------|
| Crear | POST /api/projects | Proyecto con slug |
| Listar | GET /api/projects/by-group/:id | Solo del grupo |

---

## ➡️ Siguiente: [Módulo 06: Squad](./06_FEATURE_SQUAD.md)
