using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Features.Auth.Register;

// === COMMAND ===
public record RegisterCommand(
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
    List<AsignacionDocente>? Asignaciones
) : IRequest<RegisterResponse>;

public record RegisterResponse(
    bool Success,
    string Message,
    string? UserId
);

// === HANDLER ===
public class RegisterHandler : IRequestHandler<RegisterCommand, RegisterResponse>
{
    private readonly IUserRepository _userRepository;

    public RegisterHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<RegisterResponse> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        // 1. Verificar si el usuario ya existe
        Console.WriteLine($"[DEBUG] RegisterHandler: Verificando existencia de {request.Email} (UID: {request.FirebaseUid})");
        var existingUser = await _userRepository.GetByIdAsync(request.FirebaseUid);

        if (existingUser != null)
        {
            // RACE CONDITION FIX:
            // Si el usuario ya existe, asumimos que fue creado parcialmente por el frontend (useAuth)
            // o es una corrección de datos. Actualizamos la información en lugar de rechazar.
            Console.WriteLine($"[DEBUG] RegisterHandler: Usuario ya existe (posible race condition). Actualizando datos...");

            existingUser.Nombre = request.Nombre;
            existingUser.ApellidoPaterno = request.ApellidoPaterno ?? string.Empty;
            existingUser.ApellidoMaterno = request.ApellidoMaterno ?? string.Empty;
            existingUser.Rol = request.Rol;

            // Actualizar campos específicos
            existingUser.GrupoId = request.GrupoId;
            existingUser.Matricula = request.Matricula;
            existingUser.CarreraId = request.CarreraId;
            existingUser.Profesion = request.Profesion;
            existingUser.Organizacion = request.Organizacion;
            existingUser.Asignaciones = request.Asignaciones;
            
            existingUser.UpdatedAt = DateTime.UtcNow.ToString("o");
            existingUser.IsFirstLogin = false; // Completó el registro

            await _userRepository.UpdateAsync(existingUser);
            Console.WriteLine($"[DEBUG] RegisterHandler: Usuario {existingUser.Email} actualizado correctamente.");

            return new RegisterResponse(true, "Usuario actualizado correctamente", existingUser.Id);
        }

        // 2. Crear nuevo usuario (si no existía)
        var user = new User
        {
            Id = request.FirebaseUid,
            Email = request.Email,
            Nombre = request.Nombre,
            ApellidoPaterno = request.ApellidoPaterno ?? string.Empty,
            ApellidoMaterno = request.ApellidoMaterno ?? string.Empty,
            Rol = request.Rol,
            
            // Campos comunes y específicos
            GrupoId = request.GrupoId,
            Matricula = request.Matricula,
            CarreraId = request.CarreraId,
            Profesion = request.Profesion,
            Organizacion = request.Organizacion,
            
            // Asignaciones de docente
            Asignaciones = request.Asignaciones,
            
            CreatedAt = DateTime.UtcNow.ToString("o"),
            UpdatedAt = DateTime.UtcNow.ToString("o"),
            IsFirstLogin = false // Ya completó el registro
        };

        await _userRepository.CreateAsync(user);
        Console.WriteLine($"[DEBUG] RegisterHandler: Usuario {user.Email} creado exitosamente con rol {user.Rol}");

        return new RegisterResponse(true, "Usuario registrado correctamente", user.Id);
    }
}
