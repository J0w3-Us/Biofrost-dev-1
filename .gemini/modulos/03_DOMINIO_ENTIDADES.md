# 📦 Módulo 03: Dominio y Entidades

> **Objetivo:** Definir las entidades de dominio (User, Project, Group, CanvasBlock) y Value Objects  
> **Complejidad:** 🟡 Media  
> **Dependencias:** Módulo 01 completado

---

## 🎯 Entregables

- [ ] Entidad `User` con validación de dominio
- [ ] Entidad `Project` (Aggregate Root)
- [ ] Entidad `Group`
- [ ] Entidad `CanvasBlock`
- [ ] Entidad `Evaluation`
- [ ] Value Object `Email` con lógica de Regex
- [ ] Enums para roles y estados
- [ ] Interfaces de repositorio

---

## 📁 Estructura de Archivos

```
/backend/src/IntegradorHub.API/Shared/Domain/
├── /Entities
│   ├── User.cs
│   ├── Project.cs
│   ├── Group.cs
│   ├── CanvasBlock.cs
│   └── Evaluation.cs
├── /ValueObjects
│   └── Email.cs
├── /Enums
│   ├── UserRole.cs
│   └── ProjectState.cs
└── /Interfaces
    ├── IUserRepository.cs
    └── IProjectRepository.cs
```

---

## 🔧 Implementación de Entidades

### 1. Enums

**`Enums/UserRole.cs`**
```csharp
namespace IntegradorHub.API.Shared.Domain.Enums;

public enum UserRole
{
    Alumno,
    Docente,
    Invitado,
    Admin
}
```

**`Enums/ProjectState.cs`**
```csharp
namespace IntegradorHub.API.Shared.Domain.Enums;

public enum ProjectState
{
    Borrador,   // Solo visible por el líder
    Privado,    // Visible por Squad y Docente
    Publico,    // Visible para todos
    Historico   // Solo lectura (archivo)
}
```

---

### 2. Value Objects

**`ValueObjects/Email.cs`**
```csharp
using System.Text.RegularExpressions;

namespace IntegradorHub.API.Shared.Domain.ValueObjects;

public record Email
{
    public string Value { get; }
    public EmailType Type { get; }
    public string? Matricula { get; }

    // Regex para clasificación de correos UTM
    private static readonly Regex AlumnoRegex = 
        new(@"^(\d{8})@utmetropolitana\.edu\.mx$", RegexOptions.Compiled);
    
    private static readonly Regex DocenteRegex = 
        new(@"^[a-zA-Z.]+@utmetropolitana\.edu\.mx$", RegexOptions.Compiled);

    private Email(string value, EmailType type, string? matricula = null)
    {
        Value = value;
        Type = type;
        Matricula = matricula;
    }

    public static Email Create(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("El correo no puede estar vacío");

        email = email.ToLowerInvariant().Trim();

        // Verificar si es alumno
        var matchAlumno = AlumnoRegex.Match(email);
        if (matchAlumno.Success)
        {
            return new Email(email, EmailType.Alumno, matchAlumno.Groups[1].Value);
        }

        // Verificar si es docente
        if (DocenteRegex.IsMatch(email))
        {
            return new Email(email, EmailType.Docente);
        }

        // Es un correo externo (invitado)
        return new Email(email, EmailType.Invitado);
    }

    public bool IsInstitutional => 
        Type == EmailType.Alumno || Type == EmailType.Docente;
}

public enum EmailType
{
    Alumno,
    Docente,
    Invitado
}
```

---

### 3. Entidades

**`Entities/User.cs`**
```csharp
using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Enums;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class User
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("nombre_completo")]
    public string NombreCompleto { get; set; } = string.Empty;
    
    [FirestoreProperty("email")]
    public string Email { get; set; } = string.Empty;
    
    [FirestoreProperty("rol")]
    public string Rol { get; set; } = "invitado";
    
    [FirestoreProperty("matricula")]
    public string? Matricula { get; set; }
    
    [FirestoreProperty("grupo_id")]
    public string? GrupoId { get; set; }
    
    [FirestoreProperty("especialidad")]
    public string? Especialidad { get; set; }
    
    [FirestoreProperty("organizacion")]
    public string? Organizacion { get; set; }
    
    [FirestoreProperty("grupos_docente")]
    public List<string>? GruposDocente { get; set; }
    
    [FirestoreProperty("prioridad_docente")]
    public bool PrioridadDocente { get; set; } = false;
    
    [FirestoreProperty("foto_url")]
    public string? FotoUrl { get; set; }
    
    [FirestoreProperty("fecha_registro")]
    public DateTime FechaRegistro { get; set; } = DateTime.UtcNow;

    // Métodos de dominio
    public bool EsAlumno() => Rol == "alumno";
    public bool EsDocente() => Rol == "docente";
    public bool EsAdmin() => Rol == "admin";
    public bool TieneGrupoAsignado(string grupoId) => 
        GruposDocente?.Contains(grupoId) ?? false;
}
```

**`Entities/Project.cs`**
```csharp
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Project
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("titulo")]
    public string Titulo { get; set; } = string.Empty;
    
    [FirestoreProperty("slug")]
    public string Slug { get; set; } = string.Empty;
    
    [FirestoreProperty("lider_id")]
    public string LiderId { get; set; } = string.Empty;
    
    [FirestoreProperty("miembros")]
    public List<string> Miembros { get; set; } = new();
    
    [FirestoreProperty("grupo_contexto")]
    public string GrupoContexto { get; set; } = string.Empty;
    
    [FirestoreProperty("docente_asignado")]
    public string? DocenteAsignado { get; set; }
    
    [FirestoreProperty("estado")]
    public string Estado { get; set; } = "borrador";
    
    [FirestoreProperty("content_blocks")]
    public List<CanvasBlock> ContentBlocks { get; set; } = new();
    
    [FirestoreProperty("stack_tecnico")]
    public List<string> StackTecnico { get; set; } = new();
    
    [FirestoreProperty("materia_id")]
    public string? MateriaId { get; set; }
    
    [FirestoreProperty("video_pitch_url")]
    public string? VideoPitchUrl { get; set; }
    
    [FirestoreProperty("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    
    [FirestoreProperty("fecha_actualizacion")]
    public DateTime FechaActualizacion { get; set; } = DateTime.UtcNow;

    // --- Métodos de Dominio ---
    
    public bool EsLider(string userId) => LiderId == userId;
    
    public bool EsMiembro(string userId) => 
        LiderId == userId || Miembros.Contains(userId);
    
    public bool PuedeEditar(string userId) => 
        Estado != "historico" && EsMiembro(userId);
    
    public bool PuedeAgregarMiembro() => 
        Miembros.Count < 5; // Máximo 5 miembros + líder
    
    public void AgregarMiembro(string userId)
    {
        if (!PuedeAgregarMiembro())
            throw new InvalidOperationException("El equipo ya tiene el máximo de miembros");
        
        if (EsMiembro(userId))
            throw new InvalidOperationException("El usuario ya es miembro del equipo");
        
        Miembros.Add(userId);
        FechaActualizacion = DateTime.UtcNow;
    }
    
    public void RemoverMiembro(string userId)
    {
        if (userId == LiderId)
            throw new InvalidOperationException("No se puede remover al líder del proyecto");
        
        Miembros.Remove(userId);
        FechaActualizacion = DateTime.UtcNow;
    }
    
    public void CambiarEstado(string nuevoEstado)
    {
        var estadosValidos = new[] { "borrador", "privado", "publico", "historico" };
        if (!estadosValidos.Contains(nuevoEstado))
            throw new ArgumentException("Estado no válido");
        
        Estado = nuevoEstado;
        FechaActualizacion = DateTime.UtcNow;
    }
}
```

**`Entities/CanvasBlock.cs`**
```csharp
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class CanvasBlock
{
    [FirestoreProperty("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();
    
    [FirestoreProperty("type")]
    public string Type { get; set; } = "text"; // text, image, video, code, heading
    
    [FirestoreProperty("content")]
    public string Content { get; set; } = string.Empty;
    
    [FirestoreProperty("order")]
    public int Order { get; set; }
    
    [FirestoreProperty("metadata")]
    public Dictionary<string, object>? Metadata { get; set; }
}
```

**`Entities/Group.cs`**
```csharp
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Group
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("nombre")]
    public string Nombre { get; set; } = string.Empty; // ej: "5B"
    
    [FirestoreProperty("carrera")]
    public string Carrera { get; set; } = "DSM";
    
    [FirestoreProperty("cuatrimestre")]
    public string Cuatrimestre { get; set; } = string.Empty; // ej: "Enero-Abril 2026"
    
    [FirestoreProperty("activo")]
    public bool Activo { get; set; } = true;
}
```

**`Entities/Evaluation.cs`**
```csharp
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Evaluation
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("proyecto_id")]
    public string ProyectoId { get; set; } = string.Empty;
    
    [FirestoreProperty("docente_id")]
    public string DocenteId { get; set; } = string.Empty;
    
    [FirestoreProperty("comentario")]
    public string Comentario { get; set; } = string.Empty;
    
    [FirestoreProperty("tipo")]
    public string Tipo { get; set; } = "sugerencia"; // oficial, sugerencia
    
    [FirestoreProperty("visto_por_equipo")]
    public bool VistoPorEquipo { get; set; } = false;
    
    [FirestoreProperty("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
```

---

### 4. Interfaces de Repositorio

**`Interfaces/IUserRepository.cs`**
```csharp
using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Shared.Domain.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(string id);
    Task<User?> GetByEmailAsync(string email);
    Task<IEnumerable<User>> GetByGrupoAsync(string grupoId);
    Task<IEnumerable<User>> GetDocentesByGrupoAsync(string grupoId);
    Task CreateAsync(User user);
    Task UpdateAsync(User user);
}
```

**`Interfaces/IProjectRepository.cs`**
```csharp
using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Shared.Domain.Interfaces;

public interface IProjectRepository
{
    Task<Project?> GetByIdAsync(string id);
    Task<IEnumerable<Project>> GetByGrupoAsync(string grupoId);
    Task<IEnumerable<Project>> GetPublicosAsync();
    Task<IEnumerable<Project>> GetByMiembroAsync(string userId);
    Task CreateAsync(Project project);
    Task UpdateAsync(Project project);
    Task DeleteAsync(string id);
}
```

---

## ✅ Verificación

| Verificación | Método | Resultado Esperado |
|--------------|--------|-------------------|
| Email parsing | Unit test de `Email.Create()` | Clasificación correcta |
| Entidades compilan | `dotnet build` | Sin errores |
| Firestore attributes | Verificar decoradores | Atributos presentes |

### Test de Email Value Object
```csharp
// Ejemplo de test
var emailAlumno = Email.Create("23060925@utmetropolitana.edu.mx");
Assert.Equal(EmailType.Alumno, emailAlumno.Type);
Assert.Equal("23060925", emailAlumno.Matricula);

var emailDocente = Email.Create("roberto.perez@utmetropolitana.edu.mx");
Assert.Equal(EmailType.Docente, emailDocente.Type);

var emailExterno = Email.Create("reclutador@empresa.com");
Assert.Equal(EmailType.Invitado, emailExterno.Type);
```

---

## ➡️ Siguiente Módulo

Continuar con [**Módulo 04: Auth & Identificación**](./04_AUTH_IDENTIFICACION.md)
