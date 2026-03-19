using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

/// <summary>
/// Representa una asignación de un docente a una materia en grupos específicos de una carrera
/// </summary>
[FirestoreData]
public class AsignacionDocente
{
    [FirestoreProperty("carrera_id")]
    public string CarreraId { get; set; } = string.Empty;
    
    [FirestoreProperty("materia_id")]
    public string MateriaId { get; set; } = string.Empty;
    
    [FirestoreProperty("grupos_ids")]
    public List<string> GruposIds { get; set; } = new();
}
