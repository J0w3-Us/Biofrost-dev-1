using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Features.Admin.Materias;

[ApiController]
[Route("api/admin/materias")]
public class MateriasController : ControllerBase
{
    private readonly IMateriaRepository _repository;

    public MateriasController(IMateriaRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<List<Materia>>> GetAll([FromQuery] string? carreraId = null)
    {
        var materias = await _repository.GetAllActiveAsync();
        
        if (!string.IsNullOrEmpty(carreraId))
        {
            materias = materias.Where(m => m.CarreraId == carreraId);
        }
        
        return Ok(materias.ToList());
    }

    [HttpGet("by-carrera/{carreraId}")]
    public async Task<ActionResult<List<Materia>>> GetByCarrera(string carreraId)
    {
        var materias = await _repository.GetByCuatrimestreAsync(0); // Get all
        var filtered = materias.Where(m => m.CarreraId == carreraId).ToList();
        return Ok(filtered);
    }

    [HttpGet("available")]
    public async Task<ActionResult<IEnumerable<AvailableMateriaDto>>> GetAvailable([FromQuery] string carreraId, [FromServices] MediatR.IMediator mediator)
    {
        if (string.IsNullOrEmpty(carreraId)) return BadRequest("El ID de la carrera es requerido.");
        
        var query = new GetAvailableMateriasQuery(carreraId);
        var result = await mediator.Send(query);
        
        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateMateriaRequest request)
    {
        var materia = new Materia
        {
            Nombre = request.Nombre,
            Clave = request.Clave ?? string.Empty,
            CarreraId = request.CarreraId,
            Cuatrimestre = request.Cuatrimestre,

            IsActive = true,
            EsAltaPrioridad = request.EsAltaPrioridad,
            CreatedAt = Timestamp.GetCurrentTimestamp()
        };
        
        await _repository.CreateAsync(materia);
        return Ok(materia);
    }
    
    [HttpPut("{id}")]
    public async Task<ActionResult> Update(string id, [FromBody] UpdateMateriaRequest request)
    {
        var materia = await _repository.GetByIdAsync(id);
        if (materia == null)
        {
            return NotFound();
        }

        materia.Nombre = request.Nombre;
        materia.Clave = request.Clave ?? string.Empty;
        materia.CarreraId = request.CarreraId;
        materia.CarreraId = request.CarreraId;
        materia.Cuatrimestre = request.Cuatrimestre;
        materia.EsAltaPrioridad = request.EsAltaPrioridad;

        await _repository.UpdateAsync(materia);
        return NoContent();
    }
    
    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(string id)
    {
        var materia = await _repository.GetByIdAsync(id);
        if (materia == null)
        {
            return NotFound();
        }

        materia.IsActive = false;
        await _repository.UpdateAsync(materia);
        return NoContent();
    }
}

public record CreateMateriaRequest(string Nombre, string? Clave, string CarreraId, int Cuatrimestre, bool EsAltaPrioridad = false);
public record UpdateMateriaRequest(string Nombre, string? Clave, string CarreraId, int Cuatrimestre, bool EsAltaPrioridad = false);
