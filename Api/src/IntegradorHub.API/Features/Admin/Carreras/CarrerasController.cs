using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Admin.Carreras;

[ApiController]
[Route("api/admin/carreras")]
public class CarrerasController : ControllerBase
{
    private readonly ICarreraRepository _repository;

    public CarrerasController(ICarreraRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<List<Carrera>>> GetAll()
    {
        var carreras = await _repository.GetAllAsync();
        return Ok(carreras);
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateCarreraRequest request)
    {
        var carrera = new Carrera
        {
            Nombre = request.Nombre,
            Nivel = request.Nivel,
            Activo = true
        };
        
        var id = await _repository.CreateAsync(carrera);
        return CreatedAtAction(nameof(GetAll), new { id }, carrera);
    }
    
    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(string id)
    {
        await _repository.DeleteAsync(id);
        return NoContent();
    }
}

public record CreateCarreraRequest(string Nombre, string Nivel);
