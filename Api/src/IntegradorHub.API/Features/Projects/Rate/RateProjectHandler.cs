using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Features.Projects.Rate;

// === VALUE OBJECTS ===

[FirestoreData]
public class RubricVote
{
    [FirestoreProperty("ui_ux")]
    public int UIUX { get; set; }

    [FirestoreProperty("inovacion")]
    public int Inovacion { get; set; }

    [FirestoreProperty("presentacion")]
    public int Presentacion { get; set; }

    [FirestoreProperty("impacto")]
    public int Impacto { get; set; }

    // Total de puntos de este voto (cada criterio 1-5, cada punto = 2.5 pts)
    public double TotalPoints => (UIUX + Inovacion + Presentacion + Impacto) * 2.5;
}

// === COMMAND ===

public record RateProjectCommand(
    string ProjectId,
    string UserId,
    int UIUX,       // 1-5
    int Inovacion,  // 1-5
    int Presentacion, // 1-5
    int Impacto     // 1-5
) : IRequest<RateProjectResponse>;

public record RateProjectResponse(
    bool Success,
    string Message,
    double NewTotalPoints,
    double PuntosUIUX,
    double PuntosInovacion,
    double PuntosPresentacion,
    double PuntosImpacto
);

// === HANDLER ===

public class RateProjectHandler : IRequestHandler<RateProjectCommand, RateProjectResponse>
{
    private readonly IProjectRepository _projectRepository;

    public RateProjectHandler(IProjectRepository projectRepository)
    {
        _projectRepository = projectRepository;
    }

    public async Task<RateProjectResponse> Handle(RateProjectCommand request, CancellationToken cancellationToken)
    {
        // 1. Obtener el Proyecto
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null)
            throw new KeyNotFoundException("Proyecto no encontrado");

        // 2. El líder no puede votar por su propio proyecto
        if (project.LiderId == request.UserId)
            throw new InvalidOperationException("El líder del proyecto no puede votar por su propio proyecto.");

        // 3. Validar rúbrica (cada criterio debe ser entre 1 y 5)
        Validate(request.UIUX, "UI/UX");
        Validate(request.Inovacion, "Innovación");
        Validate(request.Presentacion, "Presentación");
        Validate(request.Impacto, "Impacto");

        // 4. Crear el nuevo voto de rúbrica
        var newVoteObj = new RubricVote
        {
            UIUX = request.UIUX,
            Inovacion = request.Inovacion,
            Presentacion = request.Presentacion,
            Impacto = request.Impacto
        };

        // Convertir explícitamente a Dictionary para que Firestore serialice correctamente
        var newVoteDict = new Dictionary<string, object>
        {
            { "ui_ux", request.UIUX },
            { "inovacion", request.Inovacion },
            { "presentacion", request.Presentacion },
            { "impacto", request.Impacto }
        };

        // 5. Si el usuario ya votó anteriormente, restar sus puntos anteriores antes de sumar los nuevos
        if (project.Votantes.ContainsKey(request.UserId))
        {
            var oldVoteObj = project.Votantes[request.UserId];
            RubricVote? oldRubric = TryParseRubricVote(oldVoteObj);
            if (oldRubric != null)
            {
                // Restar puntos del voto anterior (acumuladores desglosados)
                project.PuntosTotales    -= oldRubric.TotalPoints;
                project.PuntosUIUX       -= oldRubric.UIUX * 2.5;
                project.PuntosInovacion  -= oldRubric.Inovacion * 2.5;
                project.PuntosPresentacion -= oldRubric.Presentacion * 2.5;
                project.PuntosImpacto    -= oldRubric.Impacto * 2.5;
            }
            else
            {
                // Voto antiguo con formato int (estrellas simples), sólo resta del total
                if (oldVoteObj is long oldStars)
                    project.PuntosTotales -= oldStars * 10;
            }

            // Actualizar voto existente
            project.Votantes[request.UserId] = newVoteDict;
        }
        else
        {
            // Voto nuevo
            project.Votantes.Add(request.UserId, newVoteDict);
            project.ConteoVotos++;
        }

        // 6. Sumar puntos del nuevo voto a los acumuladores
        project.PuntosTotales      += newVoteObj.TotalPoints;
        project.PuntosUIUX         += newVoteObj.UIUX * 2.5;
        project.PuntosInovacion    += newVoteObj.Inovacion * 2.5;
        project.PuntosPresentacion += newVoteObj.Presentacion * 2.5;
        project.PuntosImpacto      += newVoteObj.Impacto * 2.5;

        // 7. Guardar cambios
        await _projectRepository.UpdateAsync(project);

        return new RateProjectResponse(
            true,
            "Voto registrado correctamente",
            project.PuntosTotales,
            project.PuntosUIUX,
            project.PuntosInovacion,
            project.PuntosPresentacion,
            project.PuntosImpacto
        );
    }

    // === Helpers ===

    private static void Validate(int value, string criterio)
    {
        if (value < 1 || value > 5)
            throw new ArgumentException($"La calificación de '{criterio}' debe ser entre 1 y 5.");
    }

    /// <summary>
    /// Intenta convertir un valor genérico de Firestore a RubricVote.
    /// Firestore devuelve mapas anidados como Dictionary<string, object>.
    /// </summary>
    private static RubricVote? TryParseRubricVote(object obj)
    {
        if (obj is RubricVote rv) return rv;
        if (obj is Dictionary<string, object> dict)
        {
            return new RubricVote
            {
                UIUX         = GetInt(dict, "ui_ux"),
                Inovacion    = GetInt(dict, "inovacion"),
                Presentacion = GetInt(dict, "presentacion"),
                Impacto      = GetInt(dict, "impacto")
            };
        }
        return null;
    }

    private static int GetInt(Dictionary<string, object> dict, string key)
        => dict.TryGetValue(key, out var v) && v is long l ? (int)l : 0;
}
