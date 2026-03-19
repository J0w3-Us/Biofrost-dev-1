using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Enums;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class User
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("email")]
    public string Email { get; set; } = string.Empty;
    
    [FirestoreProperty("nombre")]
    public string Nombre { get; set; } = string.Empty;
    
    [FirestoreProperty("apellido_paterno")]
    public string ApellidoPaterno { get; set; } = string.Empty;
    
    [FirestoreProperty("apellido_materno")]
    public string ApellidoMaterno { get; set; } = string.Empty;
    
    [FirestoreProperty("matricula")]
    public string? Matricula { get; set; }
    
    [FirestoreProperty("foto_url")]
    public string? FotoUrl { get; set; }
    
    [FirestoreProperty("rol")]
    public string Rol { get; set; } = nameof(UserRole.Invitado);
    
    [FirestoreProperty("grupo_id")]
    public string? GrupoId { get; set; }
    
    [FirestoreProperty("carrera_id")]
    public string? CarreraId { get; set; } // Para alumnos

    [FirestoreProperty("project_id")]
    public string? ProjectId { get; set; } // ID del proyecto/equipo al que pertenece (Exclusividad)

    // --- Docente ---
    [FirestoreProperty("asignaciones")]
    public List<AsignacionDocente>? Asignaciones { get; set; } // Asignaciones de Carrera -> Materia -> Grupos
    
    [FirestoreProperty("profesion")]
    public string? Profesion { get; set; } // Ej: "Ingeniero en Sistemas"

    [FirestoreProperty("especialidad_docente")]
    public string? EspecialidadDocente { get; set; }
    
    // --- Invitado ---
    [FirestoreProperty("organizacion")]
    public string? Organizacion { get; set; } // Ej: "Google", "Freelance"
    
    [FirestoreProperty("created_at")]
    public object? CreatedAt { get; set; }
    
    [FirestoreProperty("updated_at")]
    public object? UpdatedAt { get; set; }

    public string? GetCreatedAtAsString() => CreatedAt switch {
        Timestamp t => t.ToDateTime().ToString("o"),
        string s => s,
        _ => null
    };

    public string? GetUpdatedAtAsString() => UpdatedAt switch {
        Timestamp t => t.ToDateTime().ToString("o"),
        string s => s,
        _ => null
    };
    
    [FirestoreProperty("is_first_login")]
    public bool IsFirstLogin { get; set; } = true;
    
    [FirestoreProperty("redes_sociales")]
    public Dictionary<string, string>? RedesSociales { get; set; } = new();
}
