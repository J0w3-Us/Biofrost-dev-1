using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Materia
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("nombre")]
    public string Nombre { get; set; } = string.Empty; // Ej: "Proyecto Integrador I"
    
    [FirestoreProperty("clave")]
    public string Clave { get; set; } = string.Empty; // Ej: "PI1", "BD2"
    
    [FirestoreProperty("carrera_id")]
    public string CarreraId { get; set; } = string.Empty; // ID de la carrera a la que pertenece
    
    [FirestoreProperty("cuatrimestre")]
    public int Cuatrimestre { get; set; } // 1-10
    
    [FirestoreProperty("is_active")]
    public bool IsActive { get; set; } = true;
    
    [FirestoreProperty("es_alta_prioridad")]
    public bool EsAltaPrioridad { get; set; } = false;
    
    [FirestoreProperty("created_at")]
    public Timestamp CreatedAt { get; set; }
}
