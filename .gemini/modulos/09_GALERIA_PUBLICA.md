# 🖼️ Módulo 09: Galería Pública (Showcase)

> **Objetivo:** Vista pública para invitados y reclutadores  
> **Complejidad:** 🟡 Media  
> **Dependencias:** Módulo 05

---

## 🎯 Entregables

- [ ] Galería de proyectos públicos
- [ ] Filtro por Stack Tecnológico
- [ ] Búsqueda por título
- [ ] Vista de detalle (solo lectura)
- [ ] Acceso sin login

---

## 🔧 Backend

**GetPublicProjectsQuery.cs**
```csharp
public record GetPublicProjectsQuery(
    string? StackFilter,
    string? SearchTerm
) : IRequest<IEnumerable<ProjectSummary>>;
```

**GetPublicProjectsHandler.cs**
```csharp
public async Task<IEnumerable<ProjectSummary>> Handle(
    GetPublicProjectsQuery req, CancellationToken ct)
{
    var query = FirestoreContext.Projects
        .WhereEqualTo("estado", "publico");
    
    var snapshot = await query.GetSnapshotAsync();
    var projects = snapshot.Documents
        .Select(d => d.ConvertTo<Project>());
    
    // Filtrar en memoria por stack
    if (!string.IsNullOrEmpty(req.StackFilter))
    {
        projects = projects.Where(p => 
            p.StackTecnico.Contains(req.StackFilter, StringComparer.OrdinalIgnoreCase));
    }
    
    // Filtrar por título
    if (!string.IsNullOrEmpty(req.SearchTerm))
    {
        projects = projects.Where(p => 
            p.Titulo.Contains(req.SearchTerm, StringComparison.OrdinalIgnoreCase));
    }
    
    return projects.Select(ToSummary);
}
```

---

## 🔧 Frontend

**GalleryPage.jsx**
```jsx
export function GalleryPage() {
  const [projects, setProjects] = useState([]);
  const [stackFilter, setStackFilter] = useState('');
  const [search, setSearch] = useState('');
  const [allStacks, setAllStacks] = useState([]);

  useEffect(() => {
    loadProjects();
  }, [stackFilter, search]);

  const loadProjects = async () => {
    const data = await getPublicProjects({ stack: stackFilter, search });
    setProjects(data);
    
    // Extraer todos los stacks únicos
    const stacks = [...new Set(data.flatMap(p => p.stackTecnico))];
    setAllStacks(stacks);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b py-6">
        <div className="max-w-6xl mx-auto px-4">
          <h1 className="text-3xl font-bold text-gray-800">
            Proyectos Integradores DSM
          </h1>
          <p className="text-gray-600 mt-2">
            Explora el talento de nuestros estudiantes
          </p>
        </div>
      </header>

      {/* Filtros */}
      <div className="max-w-6xl mx-auto px-4 py-6">
        <div className="flex gap-4 flex-wrap">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar proyecto..."
            className="px-4 py-2 border rounded-lg"
          />
          
          <select
            value={stackFilter}
            onChange={(e) => setStackFilter(e.target.value)}
            className="px-4 py-2 border rounded-lg"
          >
            <option value="">Todos los stacks</option>
            {allStacks.map(s => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Grid de Proyectos */}
      <div className="max-w-6xl mx-auto px-4 pb-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {projects.map(p => (
            <PublicProjectCard key={p.id} project={p} />
          ))}
        </div>
      </div>
    </div>
  );
}
```

---

## ✅ Verificación

| Test | Esperado |
|------|----------|
| Sin login | Galería visible |
| Filtrar "React" | Solo proyectos con React |
| Click en proyecto | Detalle en solo-lectura |

---

## ➡️ Siguiente: [Módulo 10: Admin](./10_ADMIN_PANEL.md)
