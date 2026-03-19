using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Features.Evaluations.Create;
using IntegradorHub.API.Features.Evaluations.GetByProject;
using IntegradorHub.API.Features.Evaluations.Visibility;

namespace IntegradorHub.API.Features.Evaluations;

[ApiController]
[Route("api/[controller]")]
public class EvaluationsController : ControllerBase
{
    private readonly IMediator _mediator;

    public EvaluationsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Crea una nueva evaluación para un proyecto.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<CreateEvaluationResponse>> Create([FromBody] CreateEvaluationRequest request)
    {
        var command = new CreateEvaluationCommand(
            request.ProjectId,
            request.DocenteId,
            request.DocenteNombre,
            request.Tipo,
            request.Contenido,
            request.Calificacion
        );

        try
        {
            var response = await _mediator.Send(command);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex) { return Forbid(ex.Message); }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        catch (ArgumentException ex) { return BadRequest(ex.Message); }
    }

    /// <summary>
    /// Obtiene todas las evaluaciones de un proyecto.
    /// </summary>
    [HttpGet("project/{projectId}")]
    public async Task<ActionResult<IEnumerable<EvaluationDto>>> GetByProject(string projectId)
    {
        var query = new GetEvaluationsByProjectQuery(projectId);
        var evaluations = await _mediator.Send(query);
        return Ok(evaluations);
    }
    /// <summary>
    /// Cambia la visibilidad de una evaluación (Público/Privado).
    /// </summary>
    [HttpPatch("{id}/visibility")]
    public async Task<ActionResult<UpdateEvaluationVisibilityResponse>> ChangeVisibility(string id, [FromBody] ChangeVisibilityRequest request)
    {
        var command = new UpdateEvaluationVisibilityCommand(id, request.UserId, request.EsPublico);
        try
        {
            var response = await _mediator.Send(command);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex) { return Forbid(ex.Message); }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
    }
}

public record ChangeVisibilityRequest(string UserId, bool EsPublico);

public record CreateEvaluationRequest(
    string ProjectId,
    string DocenteId,
    string DocenteNombre,
    string Tipo,
    string Contenido,
    int? Calificacion
);
