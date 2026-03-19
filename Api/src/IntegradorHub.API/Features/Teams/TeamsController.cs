using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Features.Teams.GetAvailableStudents;
using IntegradorHub.API.Features.Teams.GetAvailableTeachers;

namespace IntegradorHub.API.Features.Teams;

[ApiController]
[Route("api/[controller]")]
public class TeamsController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IntegradorHub.API.Shared.Domain.Interfaces.IUserRepository _userRepository;

    public TeamsController(IMediator mediator, IntegradorHub.API.Shared.Domain.Interfaces.IUserRepository userRepository)
    {
        _mediator = mediator;
        _userRepository = userRepository;
    }

    /// <summary>
    /// Retorna alumnos del mismo grupo que NO tienen equipo asignado.
    /// </summary>
    [HttpGet("available-students")]
    public async Task<ActionResult<List<StudentDto>>> GetAvailableStudents([FromQuery] string groupId)
    {
        if (string.IsNullOrEmpty(groupId)) return BadRequest("El groupId es requerido");

        var query = new GetAvailableStudentsQuery(groupId);
        var students = await _mediator.Send(query);
        
        return Ok(students);
    }

    [HttpGet("debug-user/{matricula}")]
    public async Task<ActionResult> DebugUser(string matricula)
    {
        var users = await _userRepository.GetByRoleAsync("Alumno");
        var user = users.FirstOrDefault(u => u.Matricula == matricula);
        if (user == null) return NotFound("User not found");
        return Ok(user);
    }

    /// <summary>
    /// Retorna docentes asignados a este grupo.
    /// </summary>
    [HttpGet("available-teachers")]
    public async Task<ActionResult<List<TeacherDto>>> GetAvailableTeachers([FromQuery] string groupId)
    {
        if (string.IsNullOrEmpty(groupId)) return BadRequest("El groupId es requerido");

        var query = new GetAvailableTeachersQuery(groupId);
        var teachers = await _mediator.Send(query);
        
        return Ok(teachers);
    }
}
