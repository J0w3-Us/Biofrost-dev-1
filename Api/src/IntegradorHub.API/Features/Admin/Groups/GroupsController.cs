using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Features.Admin.Groups;

[ApiController]
[Route("api/admin/groups")]
public class GroupsController : ControllerBase
{
    private readonly IGroupRepository _repository;

    public GroupsController(IGroupRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<List<Group>>> GetAll()
    {
        var groups = await _repository.GetAllActiveAsync();
        return Ok(groups.ToList());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Group>> GetById(string id)
    {
        var group = await _repository.GetByIdAsync(id);
        if (group == null)
            return NotFound();
            
        return Ok(group);
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateGroupRequest request)
    {
        var group = new Group
        {
            Nombre = request.Nombre,
            Carrera = request.Carrera ?? "DSM",
            Turno = request.Turno,
            CicloActivo = request.CicloActivo,
            DocentesIds = new List<string>(),
            IsActive = true,
            CreatedAt = Timestamp.GetCurrentTimestamp()
        };
        
        await _repository.CreateAsync(group);
        return Ok(group);
    }
    
    [HttpPut("{id}")]
    public async Task<ActionResult> Update(string id, [FromBody] UpdateGroupRequest request)
    {
        var group = await _repository.GetByIdAsync(id);
        if (group == null)
        {
            return NotFound();
        }

        group.Nombre = request.Nombre;
        group.Carrera = request.Carrera ?? "DSM";
        group.Turno = request.Turno;
        group.CicloActivo = request.CicloActivo;

        await _repository.UpdateAsync(group);
        return NoContent();
    }
    
    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(string id)
    {
        var group = await _repository.GetByIdAsync(id);
        if (group == null)
        {
            return NotFound();
        }

        group.IsActive = false;
        await _repository.UpdateAsync(group);
        return NoContent();
    }
}

public record CreateGroupRequest(string Nombre, string? Carrera, string Turno, string CicloActivo);
public record UpdateGroupRequest(string Nombre, string? Carrera, string Turno, string CicloActivo);
