using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Features.Users.GetPublicProfile;

public record PublicProfileDto(
    string Id,
    string? Email,
    string Nombre,
    string? ApellidoPaterno,
    string? ApellidoMaterno,
    string? FotoUrl,
    string Rol,
    string? Matricula,
    string? GrupoId,
    string? CarreraId,
    string? Profesion,
    string? EspecialidadDocente,
    string? Organizacion,
    string? CreatedAt,
    Dictionary<string, string>? RedesSociales
);
