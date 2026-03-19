using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Group
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("nombre")]
    public string Nombre { get; set; } = string.Empty; // Ej: "5A", "5B", "6A"
    
    [FirestoreProperty("carrera")]
    public string Carrera { get; set; } = "DSM"; // Desarrollo de Software Multiplataforma
    
    [FirestoreProperty("turno")]
    public string Turno { get; set; } = string.Empty; // Matutino, Vespertino
    
    [FirestoreProperty("ciclo_activo")]
    public string CicloActivo { get; set; } = string.Empty; // Ej: "2024-2"
    
    [FirestoreProperty("docentes_ids")]
    public List<string> DocentesIds { get; set; } = new();
    
    [FirestoreProperty("is_active")]
    public bool IsActive { get; set; } = true;
    
    [FirestoreProperty("created_at")]
    public Timestamp CreatedAt { get; set; }
}
