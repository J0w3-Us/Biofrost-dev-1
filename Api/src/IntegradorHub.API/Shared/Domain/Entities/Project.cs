using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Enums;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Project
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("titulo")]
    public string Titulo { get; set; } = string.Empty;
    
    [FirestoreProperty("materia")]
    public string Materia { get; set; } = string.Empty;
    
    [FirestoreProperty("materia_id")]
    public string MateriaId { get; set; } = string.Empty;
    
    [FirestoreProperty("ciclo")]
    public string Ciclo { get; set; } = string.Empty;
    
    [FirestoreProperty("grupo_id")]
    public string GrupoId { get; set; } = string.Empty;
    
    [FirestoreProperty("lider_id")]
    public string LiderId { get; set; } = string.Empty;
    
    [FirestoreProperty("miembros_ids")]
    public List<string> MiembrosIds { get; set; } = new();
    
    [FirestoreProperty("docente_id")]
    public string? DocenteId { get; set; }
    
    [FirestoreProperty("estado")]
    public string Estado { get; set; } = nameof(ProjectState.Borrador);
    
    [FirestoreProperty("stack_tecnologico")]
    public List<string> StackTecnologico { get; set; } = new();
    
    [FirestoreProperty("repositorio_url")]
    public string? RepositorioUrl { get; set; }
    
    [FirestoreProperty("video_url")]
    public string? VideoUrl { get; set; }
    
    [FirestoreProperty("demo_url")]
    public string? DemoUrl { get; set; }
    
    [FirestoreProperty("thumbnail_url")]
    public string? ThumbnailUrl { get; set; }
    
    [FirestoreProperty("canvas_blocks")]
    public List<CanvasBlock> CanvasBlocks { get; set; } = new();
    
    [FirestoreProperty("created_at")]
    public object? CreatedAt { get; set; }
    
    [FirestoreProperty("updated_at")]
    public object? UpdatedAt { get; set; }

    public DateTime GetCreatedAtAsDateTime()
    {
        if (CreatedAt is Timestamp ts) return ts.ToDateTime();
        if (CreatedAt is string s && DateTime.TryParse(s, out var dt)) return dt;
        return DateTime.MinValue;
    }

    public DateTime GetUpdatedAtAsDateTime()
    {
        if (UpdatedAt is Timestamp ts) return ts.ToDateTime();
        if (UpdatedAt is string s && DateTime.TryParse(s, out var dt)) return dt;
        return DateTime.MinValue;
    }

    // --- Nuevos Campos Requeridos ---
    [FirestoreProperty("calificacion")]
    public double? Calificacion { get; set; } // 0.0 - 100.0

    [FirestoreProperty("comentarios_docente")]
    public string? ComentariosDocente { get; set; }

    [FirestoreProperty("es_publico")]
    public bool EsPublico { get; set; } = false; // Privado por defecto

    // --- Ranking System Fields ---
    [FirestoreProperty("puntos_totales")]
    public double PuntosTotales { get; set; } = 0;

    [FirestoreProperty("conteo_votos")]
    public int ConteoVotos { get; set; } = 0;

    // --- Acumuladores por Criterio (para Dashboard) ---
    [FirestoreProperty("puntos_uiux")]
    public double PuntosUIUX { get; set; } = 0;

    [FirestoreProperty("puntos_inovacion")]
    public double PuntosInovacion { get; set; } = 0;

    [FirestoreProperty("puntos_presentacion")]
    public double PuntosPresentacion { get; set; } = 0;

    [FirestoreProperty("puntos_impacto")]
    public double PuntosImpacto { get; set; } = 0;

    // Votantes: userId -> RubricVote (objeto). Lectura híbrida en el handler.
    [FirestoreProperty("votantes")]
    public Dictionary<string, object> Votantes { get; set; } = new();
}

[FirestoreData]
public class CanvasBlock
{
    [FirestoreProperty("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();
    
    [FirestoreProperty("type")]
    public string Type { get; set; } = "text"; // text, heading, image, video, code
    
    [FirestoreProperty("content")]
    public string Content { get; set; } = string.Empty;
    
    [FirestoreProperty("order")]
    public int Order { get; set; }
    
    [FirestoreProperty("metadata")]
    public Dictionary<string, object>? Metadata { get; set; }
}
