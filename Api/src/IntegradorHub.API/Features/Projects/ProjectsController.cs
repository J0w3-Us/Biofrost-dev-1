using IntegradorHub.API.Features.Projects.Delete;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Features.Projects.Create;
using IntegradorHub.API.Features.Projects.GetByGroup;
using IntegradorHub.API.Features.Projects.AddMember;
using IntegradorHub.API.Features.Projects.RemoveMember;
using IntegradorHub.API.Features.Projects.GetDetails;
using IntegradorHub.API.Features.Projects.UpdateCanvas;
using IntegradorHub.API.Features.Projects.Update;
using IntegradorHub.API.Features.Projects.Rate; 
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Features.Projects.GetPublic;
using IntegradorHub.API.Features.Projects.GetByMember;

namespace IntegradorHub.API.Features.Projects;

[ApiController]
[Route("api/[controller]")]
public class ProjectsController : ControllerBase
{
    private readonly IMediator _mediator;

    public ProjectsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Obtiene todos los proyectos públicos para la galería.
    /// </summary>
    [HttpGet("public")]
    public async Task<ActionResult<IEnumerable<PublicProjectDto>>> GetPublic()
    {
        var query = new GetPublicProjectsQuery();
        var projects = await _mediator.Send(query);
        return Ok(projects);
    }

    /// <summary>
    /// Crea un nuevo proyecto. Requiere rol de Alumno.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<CreateProjectResponse>> Create([FromBody] CreateProjectRequest request)
    {
        var command = new CreateProjectCommand(
            request.Titulo,
            request.Materia,
            request.MateriaId,
            request.Ciclo,
            request.StackTecnologico,
            request.RepositorioUrl,
            request.VideoUrl,
            request.UserId,
            request.UserGroupId,
            request.DocenteId,
            request.MiembrosIds ?? new List<string>()
        );

        try 
        {
            var response = await _mediator.Send(command);
            return CreatedAtAction(nameof(GetById), new { id = response.ProjectId }, response);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
    }

    /// <summary>
    /// Obtiene proyectos de un grupo específico.
    /// </summary>
    [HttpGet("group/{groupId}")]
    public async Task<ActionResult<List<ProjectDto>>> GetByGroup(string groupId)
    {
        var query = new GetProjectsByGroupQuery(groupId);
        var response = await _mediator.Send(query);
        return Ok(response);
    }


    /// <summary>
    /// Obtiene proyectos asignados a un docente.
    /// </summary>
    [HttpGet("teacher/{teacherId}")]
    public async Task<ActionResult<List<GetByTeacher.ProjectDto>>> GetByTeacher(string teacherId)
    {
        var query = new GetByTeacher.GetProjectsByTeacherQuery(teacherId);
        var response = await _mediator.Send(query);
        return Ok(response);
    }

    /// <summary>
    /// Obtiene detalles completos del proyecto.
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<ProjectDetailsDto>> GetById(string id)
    {
        var query = new GetProjectDetailsQuery(id);
        try
        {
            var response = await _mediator.Send(query);
            return Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
    }

    /// <summary>
    /// Agrega un miembro al proyecto (Solo Líder).
    /// </summary>
    [HttpPost("{id}/members")]
    public async Task<ActionResult<AddMemberResponse>> AddMember(string id, [FromBody] AddMemberRequest request)
    {
        var command = new AddMemberCommand(id, request.EmailOrMatricula, request.LeaderId);
        try 
        {
            var response = await _mediator.Send(command);
            if (!response.Success) return BadRequest(response);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex) { return Forbid(ex.Message); }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
    }

    /// <summary>
    /// Elimina un miembro del proyecto.
    /// </summary>
    [HttpDelete("{id}/members/{memberId}")]
    public async Task<ActionResult<RemoveMemberResponse>> RemoveMember(string id, string memberId, [FromQuery] string requestingUserId)
    {
        var command = new RemoveMemberCommand(id, memberId, requestingUserId);
        try
        {
            var response = await _mediator.Send(command);
            if (!response.Success) return BadRequest(response);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex) { return Forbid(ex.Message); }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
    }

    /// <summary>
    /// Actualiza el contenido del canvas del proyecto.
    /// </summary>
    [HttpPut("{id}/canvas")]
    public async Task<ActionResult<UpdateCanvasResponse>> UpdateCanvas(string id, [FromBody] UpdateCanvasRequest request)
    {
        var command = new UpdateProjectCanvasCommand(id, request.Blocks, request.UserId);
        try
        {
            var response = await _mediator.Send(command);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex) { return Forbid(ex.Message); }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
    }

    /// <summary>
    /// Elimina un proyecto completamente y libera a sus miembros. (Solo Líder)
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<ActionResult<DeleteProjectResponse>> Delete(string id, [FromQuery] string requestingUserId)
    {
        var command = new DeleteProjectCommand(id, requestingUserId);
        try
        {
            var response = await _mediator.Send(command);
            if (!response.Success) return BadRequest(response);
            return Ok(response);
        }
        catch (UnauthorizedAccessException ex) { return Forbid(ex.Message); }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
    }

    /// <summary>
    /// Actualiza un proyecto (Título, Video, Canvas).
    /// </summary>
    [HttpPut("{id}")]
    public async Task<ActionResult<UpdateProjectResponse>> Update(string id, [FromBody] UpdateProjectRequest request)
    {
        var command = new UpdateProjectCommand(
            id,
            request.Titulo,
            request.VideoUrl,
            request.CanvasBlocks ?? new List<CanvasBlock>(), 
            request.EsPublico,
            "temp-user-id" 
        );

        try
        {
            var response = await _mediator.Send(command);
            if (!response.Success) return BadRequest(response);
            return Ok(response);
        }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        catch (UnauthorizedAccessException ex) { return Forbid(ex.Message); }
    }

    /// <summary>
    /// Obtiene el proyecto del usuario actual (si tiene).
    /// </summary>
    [HttpGet("my-project")]
    public async Task<ActionResult<ProjectDetailsDto>> GetMyProject([FromQuery] string userId)
    {
        var query = new GetProjectByMemberQuery(userId);
        var response = await _mediator.Send(query);
        
        if (response == null) 
            return NotFound("No tienes un proyecto asignado.");
            
        return Ok(response);
    }

    /// <summary>
    /// Califica un proyecto con rúbrica (UI/UX, Innovación, Presentación, Impacto).
    /// </summary>
    [HttpPost("{id}/rate")]
    public async Task<ActionResult<RateProjectResponse>> RateProject(string id, [FromBody] RateProjectRequest request)
    {
        var command = new RateProjectCommand(id, request.UserId, request.UIUX, request.Inovacion, request.Presentacion, request.Impacto);
        try
        {
            var response = await _mediator.Send(command);
            return Ok(response);
        }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        catch (ArgumentException ex) { return BadRequest(ex.Message); }
    }
}

public record RateProjectRequest(string UserId, int UIUX, int Inovacion, int Presentacion, int Impacto);

public record UpdateProjectRequest(
    string Titulo,
    string? VideoUrl,
    List<CanvasBlock>? CanvasBlocks,
    bool? EsPublico
);

public record UpdateCanvasRequest(List<CanvasBlock> Blocks, string UserId);

public record CreateProjectRequest(
    string Titulo,
    string Materia,
    string MateriaId,
    string Ciclo,
    List<string> StackTecnologico,
    string? RepositorioUrl,
    string? VideoUrl,
    string UserId,
    string UserGroupId,
    string? DocenteId,
    List<string>? MiembrosIds 
);

public record AddMemberRequest(string LeaderId, string EmailOrMatricula);
