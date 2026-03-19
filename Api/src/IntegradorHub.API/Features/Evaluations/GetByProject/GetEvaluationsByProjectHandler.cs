using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Evaluations.GetByProject;

// === QUERY ===
public record GetEvaluationsByProjectQuery(string ProjectId) : IRequest<IEnumerable<EvaluationDto>>;



// === HANDLER ===
public class GetEvaluationsByProjectHandler : IRequestHandler<GetEvaluationsByProjectQuery, IEnumerable<EvaluationDto>>
{
    private readonly IEvaluationRepository _evaluationRepository;

    public GetEvaluationsByProjectHandler(IEvaluationRepository evaluationRepository)
    {
        _evaluationRepository = evaluationRepository;
    }

    public async Task<IEnumerable<EvaluationDto>> Handle(GetEvaluationsByProjectQuery request, CancellationToken cancellationToken)
    {
        var evaluations = await _evaluationRepository.GetByProjectIdAsync(request.ProjectId);

        return evaluations.Select(e => new EvaluationDto(
            e.Id,
            e.ProjectId,
            e.DocenteId,
            e.DocenteNombre,
            e.Tipo,
            e.Contenido,
            e.Calificacion,
            e.GetCreatedAtAsDateTime(),
            e.EsPublico,
            e.PuntosOtorgados
        ));
    }
}

public record EvaluationDto(
    string Id,
    string ProjectId,
    string DocenteId,
    string DocenteNombre,
    string Tipo,
    string Contenido,
    double? Calificacion,
    DateTime CreatedAt,
    bool EsPublico,
    object? PuntosOtorgados = null
);
