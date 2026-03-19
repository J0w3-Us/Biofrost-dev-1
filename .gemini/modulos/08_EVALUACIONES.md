# 📝 Módulo 08: Evaluaciones Docentes

> **Objetivo:** Sistema de feedback técnico de docentes  
> **Complejidad:** 🟡 Media  
> **Dependencias:** Módulos 05 y 06

---

## 🎯 Entregables

- [ ] Docente puede evaluar proyectos de SUS grupos
- [ ] Tipos: oficial / sugerencia
- [ ] Cola de proyectos pendientes
- [ ] Notificación al equipo

---

## 🔧 Flujo de Evaluación

```
Docente ve Dashboard
        │
        ▼
Lista de proyectos de SUS grupos
        │
        ▼
Click en proyecto → Ver Canvas
        │
        ▼
Escribir feedback (Markdown)
        │
        ▼
Marcar como "oficial" o "sugerencia"
        │
        ▼
Equipo ve notificación
```

---

## 🔧 Backend

**SubmitFeedbackCommand.cs**
```csharp
public record SubmitFeedbackCommand(
    string ProyectoId,
    string DocenteId,
    string Comentario,
    string Tipo // "oficial" | "sugerencia"
) : IRequest<string>;
```

**SubmitFeedbackHandler.cs**
```csharp
public async Task<string> Handle(SubmitFeedbackCommand req, CancellationToken ct)
{
    // Validar que docente tiene acceso al grupo del proyecto
    var project = await GetProject(req.ProyectoId);
    var docente = await GetUser(req.DocenteId);
    
    if (!docente.GruposDocente.Contains(project.GrupoContexto))
        throw new UnauthorizedAccessException("No tienes acceso a este grupo");
    
    var evaluation = new Evaluation
    {
        ProyectoId = req.ProyectoId,
        DocenteId = req.DocenteId,
        Comentario = req.Comentario,
        Tipo = req.Tipo,
        VistoPorEquipo = false,
        FechaCreacion = DateTime.UtcNow
    };
    
    var doc = await FirestoreContext.Evaluations.AddAsync(evaluation);
    return doc.Id;
}
```

---

## 🔧 Frontend

**EvaluationForm.jsx**
```jsx
export function EvaluationForm({ projectId, onSubmit }) {
  const [comentario, setComentario] = useState('');
  const [tipo, setTipo] = useState('sugerencia');

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <textarea
        value={comentario}
        onChange={(e) => setComentario(e.target.value)}
        placeholder="Escribe tu feedback técnico..."
        className="w-full h-32 p-3 border rounded-lg"
      />
      
      <div className="flex gap-4">
        <label>
          <input type="radio" value="sugerencia" checked={tipo === 'sugerencia'} onChange={() => setTipo('sugerencia')} />
          Sugerencia
        </label>
        <label>
          <input type="radio" value="oficial" checked={tipo === 'oficial'} onChange={() => setTipo('oficial')} />
          Oficial (Validación)
        </label>
      </div>
      
      <button type="submit" className="px-4 py-2 bg-utm-green text-white rounded-lg">
        Enviar Feedback
      </button>
    </form>
  );
}
```

---

## ✅ Verificación

| Test | Esperado |
|------|----------|
| Docente evalúa su grupo | ✅ Funciona |
| Docente evalúa otro grupo | ❌ Error 403 |
| Equipo ve feedback | Notificación visible |

---

## ➡️ Siguiente: [Módulo 09: Galería](./09_GALERIA_PUBLICA.md)
