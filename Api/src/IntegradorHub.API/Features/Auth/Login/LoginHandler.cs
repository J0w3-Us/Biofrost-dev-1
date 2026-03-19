using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Enums;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Shared.Domain.ValueObjects;

namespace IntegradorHub.API.Features.Auth.Login;

// === COMMAND ===
public record LoginCommand(
    string FirebaseUid,
    string Email,
    string DisplayName,
    string? PhotoUrl
) : IRequest<LoginResponse>;

public record LoginResponse(
    string UserId,
    string Email,
    string Nombre,
    string Rol,
    bool IsFirstLogin,
    string? GrupoId,
    string? GrupoNombre,
    string? Matricula,
    string? CarreraId,
    string? ApellidoPaterno,
    string? ApellidoMaterno,
    string? FotoUrl,
    string? Profesion,
    string? EspecialidadDocente,
    string? Organizacion,
    string? CreatedAt,
    Dictionary<string, string>? RedesSociales
);

// === HANDLER ===
public class LoginHandler : IRequestHandler<LoginCommand, LoginResponse>
{
    private readonly IUserRepository _userRepository;
    private readonly IGroupRepository _groupRepository;

    public LoginHandler(IUserRepository userRepository, IGroupRepository groupRepository)
    {
        _userRepository = userRepository;
        _groupRepository = groupRepository;
    }

    public async Task<LoginResponse> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // 1. Buscar usuario existente
            var existingUser = await _userRepository.GetByIdAsync(request.FirebaseUid);



            if (existingUser != null)
            {
                // --- ROLE CORRECTION LOGIC ---
                // 1. Force SuperAdmin for personal account (Specific Exception)
                if (existingUser.Email.Equals("uzielisaac28@gmail.com", StringComparison.OrdinalIgnoreCase))
                {
                    if (existingUser.Rol != "SuperAdmin")
                    {
                        existingUser.Rol = "SuperAdmin";
                        await _userRepository.UpdateAsync(existingUser);
                        Console.WriteLine($"[FIX] Set SuperAdmin role for {existingUser.Email}");
                    }
                }
                // 2. Specific Exception for YOUR Teacher Account
                else if (existingUser.Email.Equals("Uziel.Pech@utmetropolitana.edu.mx", StringComparison.OrdinalIgnoreCase))
                {
                    if (existingUser.Rol != "Docente")
                    {
                        existingUser.Rol = "Docente";
                        await _userRepository.UpdateAsync(existingUser);
                        Console.WriteLine($"[FIX-URGENT] Forced Docente role for {existingUser.Email}");
                    }
                }
                // 3. GENERAL FIX: Auto-correct any OTHER Docente
                else
                {
                    var reEvaluatedEmail = Email.From(existingUser.Email);
                    if (reEvaluatedEmail.DetectedRole == UserRole.Docente && existingUser.Rol != "Docente")
                    {
                        existingUser.Rol = "Docente";
                        await _userRepository.UpdateAsync(existingUser);
                        Console.WriteLine($"[AUTO-FIX] Corrected {existingUser.Email} to Docente role.");
                    }
                }
                // --- SYNC PROFILE DATA IMPROVED ---
                // Si el nombre en la DB es el genérico "Usuario" pero Firebase trae uno real, actualizar.
                bool needsUpdate = false;
                if ((existingUser.Nombre == "Usuario" || string.IsNullOrEmpty(existingUser.Nombre)) && 
                    !string.IsNullOrEmpty(request.DisplayName) && request.DisplayName != "Usuario")
                {
                    existingUser.Nombre = request.DisplayName;
                    needsUpdate = true;
                }

                // Sincronizar foto si no tiene una
                if (string.IsNullOrEmpty(existingUser.FotoUrl) && !string.IsNullOrEmpty(request.PhotoUrl))
                {
                    existingUser.FotoUrl = request.PhotoUrl;
                    needsUpdate = true;
                }

                if (needsUpdate)
                {
                    await _userRepository.UpdateAsync(existingUser);
                    Console.WriteLine($"[SYNC] Updated name/photo for {existingUser.Email}");
                }
                // -----------------------------

                // -----------------------------

                // Resolver nombre del grupo si existe
                string? grupoNombre = null;
                if (!string.IsNullOrEmpty(existingUser.GrupoId))
                {
                    var group = await _groupRepository.GetByIdAsync(existingUser.GrupoId);
                    grupoNombre = group?.Nombre;
                }

                // Usuario ya registrado, devolver datos
                return new LoginResponse(
                    existingUser.Id,
                    existingUser.Email,
                    existingUser.Nombre,
                    existingUser.Rol,
                    existingUser.IsFirstLogin,
                    existingUser.GrupoId,
                    grupoNombre,
                    existingUser.Matricula,
                    existingUser.CarreraId,
                    existingUser.ApellidoPaterno,
                    existingUser.ApellidoMaterno,
                    existingUser.FotoUrl,
                    existingUser.Profesion,
                    existingUser.EspecialidadDocente,
                    existingUser.Organizacion,
                    existingUser.GetCreatedAtAsString(),
                    existingUser.RedesSociales
                );
            }

            // 2. Usuario nuevo - detectar rol automáticamente
            Email email;
            try
            {
                email = Email.From(request.Email);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error parsing email {request.Email}: {ex.Message}");
                // Fallback: crear email como Invitado si falla la detección
                email = Email.From("guest@external.com"); // Esto siempre retorna Invitado
            }
            
            var newUser = new User
            {
                Id = request.FirebaseUid,
                Email = request.Email, // Usar el email original, no el parseado
                Nombre = request.DisplayName ?? "Usuario",
                FotoUrl = request.PhotoUrl,
                Rol = email.DetectedRole.ToString(),
                Matricula = email.ExtractedMatricula,
                IsFirstLogin = true // Necesita seleccionar grupo
            };

            await _userRepository.CreateIfNotExistsAsync(newUser);
            Console.WriteLine($"[DEBUG] LoginHandler: Attempting to create new user {newUser.Email} with Role {newUser.Rol} (Safe from race conditions)");

            return new LoginResponse(
                newUser.Id,
                newUser.Email,
                newUser.Nombre,
                newUser.Rol,
                newUser.IsFirstLogin,
                newUser.GrupoId,
                null, // Nuevo usuario no tiene grupo aún
                newUser.Matricula,
                newUser.CarreraId,
                newUser.ApellidoPaterno,
                newUser.ApellidoMaterno,
                newUser.FotoUrl,
                newUser.Profesion,
                newUser.EspecialidadDocente,
                newUser.Organizacion,
                newUser.GetCreatedAtAsString(),
                newUser.RedesSociales
            );
        }
        catch (Exception ex)
        {
            Console.WriteLine($"FATAL ERROR in LoginHandler: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            throw; // Re-throw para que el controller lo maneje
        }
    }
}
