# ⚙️ Módulo 10: Admin Panel

> **Objetivo:** Panel de control para Super Admin  
> **Complejidad:** 🟡 Media  
> **Dependencias:** Módulo 04

---

## 🎯 Entregables

- [ ] Gestión de materias (CRUD)
- [ ] Gestión de grupos (CRUD)
- [ ] Promover docentes (prioridad)
- [ ] Cerrar ciclo académico (archivar)
- [ ] Hard-delete de registros erróneos

---

## 🔐 Control de Acceso

Solo usuarios con `rol = "admin"` pueden acceder.

**Super Admins definidos:**
- Uziel Isaac
- Yael Lopez

---

## 🔧 Backend: Features

### Gestión de Materias

**CreateMateriaCommand.cs**
```csharp
public record CreateMateriaCommand(
    string Nombre,
    string Clave
) : IRequest<string>;
```

### Cerrar Ciclo Académico

**CloseCycleCommand.cs**
```csharp
public record CloseCycleCommand(
    string Cuatrimestre  // ej: "Enero-Abril 2026"
) : IRequest<int>; // Retorna cantidad de proyectos archivados
```

**CloseCycleHandler.cs**
```csharp
public async Task<int> Handle(CloseCycleCommand req, CancellationToken ct)
{
    // Obtener todos los proyectos públicos
    var snapshot = await FirestoreContext.Projects
        .WhereEqualTo("estado", "publico")
        .GetSnapshotAsync();
    
    var batch = FirestoreContext.GetDatabase().StartBatch();
    int count = 0;
    
    foreach (var doc in snapshot.Documents)
    {
        batch.Update(doc.Reference, new Dictionary<string, object>
        {
            ["estado"] = "historico",
            ["cuatrimestre_archivo"] = req.Cuatrimestre,
            ["fecha_archivo"] = DateTime.UtcNow
        });
        count++;
    }
    
    await batch.CommitAsync();
    return count;
}
```

---

## 🔧 Frontend: AdminDashboard

**AdminDashboard.jsx**
```jsx
import { useAuth } from '../../auth/hooks/useAuth';
import { Navigate } from 'react-router-dom';

export function AdminDashboard() {
  const { isAdmin } = useAuth();

  if (!isAdmin) {
    return <Navigate to="/" replace />;
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-6xl mx-auto py-8 px-4">
        <h1 className="text-2xl font-bold mb-8">Panel de Administración</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <AdminCard
            title="Materias"
            description="Gestionar catálogo de materias DSM"
            link="/admin/materias"
            icon="📚"
          />
          <AdminCard
            title="Grupos"
            description="Administrar grupos del cuatrimestre"
            link="/admin/grupos"
            icon="👥"
          />
          <AdminCard
            title="Docentes"
            description="Promover y gestionar prioridades"
            link="/admin/docentes"
            icon="👨‍🏫"
          />
          <AdminCard
            title="Cerrar Ciclo"
            description="Archivar proyectos del cuatrimestre"
            link="/admin/cerrar-ciclo"
            icon="📦"
            variant="warning"
          />
        </div>
      </div>
    </div>
  );
}
```

---

## ⚠️ Acciones Críticas

### Cerrar Ciclo
```jsx
function CloseCycleConfirmation() {
  const [confirmed, setConfirmed] = useState(false);
  
  const handleClose = async () => {
    if (!confirmed) return;
    
    const result = await closeCycle({ cuatrimestre: 'Enero-Abril 2026' });
    alert(`Se archivaron ${result.count} proyectos`);
  };

  return (
    <div className="bg-yellow-50 border border-yellow-200 p-6 rounded-lg">
      <h3 className="text-lg font-bold text-yellow-800">⚠️ Cerrar Ciclo</h3>
      <p className="text-yellow-700 mb-4">
        Esta acción archivará TODOS los proyectos públicos.
        Los proyectos serán de solo lectura.
      </p>
      <label className="flex items-center gap-2 mb-4">
        <input
          type="checkbox"
          checked={confirmed}
          onChange={() => setConfirmed(!confirmed)}
        />
        Entiendo que esta acción es irreversible
      </label>
      <button
        onClick={handleClose}
        disabled={!confirmed}
        className="px-4 py-2 bg-yellow-600 text-white rounded-lg disabled:opacity-50"
      >
        Archivar Proyectos
      </button>
    </div>
  );
}
```

---

## ✅ Verificación

| Test | Esperado |
|------|----------|
| Usuario normal | No ve Admin Panel |
| Admin accede | Dashboard visible |
| Cerrar ciclo | Proyectos pasan a "historico" |

---

## 🎉 ¡Proyecto Completo!

Con este módulo completado, IntegradorHub está listo para producción.
