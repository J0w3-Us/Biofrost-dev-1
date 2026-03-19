using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace IntegradorHub.API.Features.Admin.Users;

[ApiController]
[Route("api/admin/users")]
public class UsersController : ControllerBase
{
    private readonly IMediator _mediator;

    public UsersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Obtener lista de alumnos, opcionalmente filtrados por grupo
    /// </summary>
    [HttpGet("students")]
    public async Task<ActionResult<List<StudentDto>>> GetStudents([FromQuery] string? grupoId = null)
    {
        var query = new ListStudentsQuery(grupoId);
        var students = await _mediator.Send(query);
        return Ok(students);
    }

    /// <summary>
    /// Obtener lista de docentes
    /// </summary>
    [HttpGet("teachers")]
    public async Task<ActionResult<List<TeacherDto>>> GetTeachers()
    {
        var query = new ListTeachersQuery();
        var teachers = await _mediator.Send(query);
        return Ok(teachers);
    }

    /// <summary>
    /// Actualizar grupo de un alumno
    /// </summary>
    [HttpPut("students/{userId}")]
    public async Task<ActionResult<UpdateStudentGroupResponse>> UpdateStudentGroup(
        string userId,
        [FromBody] UpdateStudentGroupRequest request)
    {
        var command = new UpdateStudentGroupCommand(userId, request.GrupoId);
        var response = await _mediator.Send(command);

        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }

    /// <summary>
    /// Actualizar asignaciones de un docente
    /// </summary>
    [HttpPut("teachers/{userId}")]
    public async Task<ActionResult<UpdateTeacherAssignmentsResponse>> UpdateTeacherAssignments(
        string userId,
        [FromBody] UpdateTeacherAssignmentsRequest request)
    {
        var command = new UpdateTeacherAssignmentsCommand(userId, request.Asignaciones);
        var response = await _mediator.Send(command);

        if (!response.Success)
        {
            return BadRequest(response);
        }

        return Ok(response);
    }
}

// Request DTOs
public record UpdateStudentGroupRequest(string GrupoId);

public record UpdateTeacherAssignmentsRequest(List<Shared.Domain.Entities.AsignacionDocente> Asignaciones);
