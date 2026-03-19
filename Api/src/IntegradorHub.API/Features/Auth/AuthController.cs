using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Features.Auth.Login;
using IntegradorHub.API.Features.Auth.Register;
using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Features.Auth;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;

    public AuthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Procesa el login de un usuario autenticado con Firebase.
    /// Detecta automáticamente el rol basado en el email.
    /// </summary>
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        var command = new LoginCommand(
            request.FirebaseUid,
            request.Email,
            request.DisplayName,
            request.PhotoUrl
        );

        var response = await _mediator.Send(command);
        return Ok(response);
    }

    /// <summary>
    /// Registra un usuario con información completa (grupo, matrícula, etc.)
    /// </summary>
    [HttpPost("register")]
    public async Task<ActionResult<RegisterResponse>> Register([FromBody] RegisterRequest request)
    {
        // Convertir formato del frontend a Asignaciones si es docente
        List<AsignacionDocente>? asignaciones = request.Asignaciones;
        
        if (request.Rol == "Docente" && request.CarrerasIds != null && request.GruposDocente != null)
        {
            asignaciones = request.CarrerasIds.Select(carreraId => new AsignacionDocente
            {
                CarreraId = carreraId,
                MateriaId = string.Empty, // Se asignará después por el admin
                GruposIds = request.GruposDocente.ToList()
            }).ToList();
        }
        
        var command = new RegisterCommand(
            request.FirebaseUid,
            request.Email,
            request.Nombre,
            request.ApellidoPaterno,
            request.ApellidoMaterno,
            request.Rol,
            request.GrupoId,
            request.Matricula,
            request.CarreraId,
            request.Profesion,
            request.Organizacion,
            asignaciones
        );

        var response = await _mediator.Send(command);
        
        if (!response.Success)
            return BadRequest(response);
            
        return Ok(response);
    }
}

public record LoginRequest(
    string FirebaseUid,
    string Email,
    string DisplayName,
    string? PhotoUrl
);

public record RegisterRequest(
    string FirebaseUid,
    string Email,
    string Nombre,
    string? ApellidoPaterno,
    string? ApellidoMaterno,
    string Rol,
    string? GrupoId,
    string? Matricula,
    string? CarreraId,
    string? Profesion,
    string? Organizacion,
    List<AsignacionDocente>? Asignaciones,
    // Formato del frontend para docentes
    List<string>? GruposDocente,
    List<string>? CarrerasIds
);
