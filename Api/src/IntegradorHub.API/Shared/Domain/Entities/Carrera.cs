using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Carrera
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;

    [FirestoreProperty("nombre")]
    public string Nombre { get; set; } = string.Empty; // Ej: "Desarrollo de Software Multiplataforma"

    [FirestoreProperty("nivel")]
    public string Nivel { get; set; } = "Ingeniería"; // TSU, Ingeniería, Licenciatura

    [FirestoreProperty("activo")]
    public bool Activo { get; set; } = true;
}
