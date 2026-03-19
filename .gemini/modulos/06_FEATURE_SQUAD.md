# 👥 Módulo 06: Feature Squad Management

> **Objetivo:** Gestión de miembros del equipo con filtrado por grupo  
> **Complejidad:** 🔴 Alta  
> **Dependencias:** Módulo 05

---

## 🎯 Entregables

- [ ] Buscar compañeros (filtrado por grupo)
- [ ] Tooltip con matrícula al hover
- [ ] Agregar/eliminar miembros (máx 5)
- [ ] Asignar docente (filtrado por grupos)

---

## 🧠 Lógica de Filtrado

```
Líder del 5B crea proyecto
        │
        ▼
Sistema inyecta grupo_id = "5B"
        │
        ▼
Buscador SOLO muestra alumnos del 5B
        │
        ▼
Selector de docente SOLO muestra
docentes con "5B" en grupos_docente
```

---

## 🔧 Backend: AddMember

**AddMemberCommand.cs**
```csharp
public record AddMemberCommand(
    string ProjectId,
    string MemberId,
    string RequesterId
) : IRequest<bool>;
```

**AddMemberHandler.cs**
```csharp
public async Task<bool> Handle(AddMemberCommand req, CancellationToken ct)
{
    var project = await GetProject(req.ProjectId);
    var member = await GetUser(req.MemberId);
    var leader = await GetUser(project.LiderId);
    
    // Validar mismo grupo
    if (member.GrupoId != leader.GrupoId)
        throw new Exception("El miembro debe ser del mismo grupo");
    
    // Validar máximo 5 miembros
    if (project.Miembros.Count >= 5)
        throw new Exception("Máximo 5 miembros por equipo");
    
    project.Miembros.Add(req.MemberId);
    await UpdateProject(project);
    return true;
}
```

---

## 🔧 Frontend: MemberSearch

**MemberSearch.jsx**
```jsx
export function MemberSearch({ grupoId, onSelect }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [hoveredUser, setHoveredUser] = useState(null);

  useEffect(() => {
    if (query.length >= 2) {
      searchMembers(grupoId, query).then(setResults);
    }
  }, [query, grupoId]);

  return (
    <div className="relative">
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Buscar compañero..."
        className="w-full p-3 border rounded-lg"
      />
      
      {results.length > 0 && (
        <ul className="absolute w-full bg-white border rounded-lg mt-1 shadow-lg z-10">
          {results.map(user => (
            <li
              key={user.id}
              className="p-3 hover:bg-gray-50 cursor-pointer relative"
              onMouseEnter={() => setHoveredUser(user)}
              onMouseLeave={() => setHoveredUser(null)}
              onClick={() => onSelect(user)}
            >
              <span>{user.nombreCompleto}</span>
              
              {/* Tooltip de Matrícula */}
              {hoveredUser?.id === user.id && (
                <MatriculaTooltip user={user} />
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

**MatriculaTooltip.jsx**
```jsx
export function MatriculaTooltip({ user }) {
  return (
    <div className="absolute left-full ml-2 top-0 bg-gray-900 text-white p-3 rounded-lg shadow-lg z-20 min-w-[200px]">
      <div className="flex items-center gap-3">
        {user.fotoUrl && (
          <img src={user.fotoUrl} className="w-10 h-10 rounded-full" />
        )}
        <div>
          <p className="font-medium">{user.nombreCompleto}</p>
          <p className="text-sm text-gray-300">
            Matrícula: <strong>{user.matricula}</strong>
          </p>
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
| Buscar en mismo grupo | Solo aparecen del 5B |
| Hover en nombre | Tooltip muestra matrícula |
| Agregar 6to miembro | Error "máximo 5" |

---

## ➡️ Siguiente: [Módulo 07: Canvas](./07_CANVAS_EDITOR.md)
