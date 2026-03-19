using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Features.Admin.Users;

public record StudentDto
{
    public string Id { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Nombre { get; init; } = string.Empty;
    public string Matricula { get; init; } = string.Empty;
    public string GrupoId { get; init; } = string.Empty;
    public string CarreraId { get; init; } = string.Empty;
    public bool IsFirstLogin { get; init; }
    public string CreatedAt { get; init; } = string.Empty;

    public static StudentDto FromUser(User user)
    {
        return new StudentDto
        {
            Id = user.Id,
            Email = user.Email,
            Nombre = user.Nombre,
            Matricula = user.Matricula ?? string.Empty,
            GrupoId = user.GrupoId ?? string.Empty,
            CarreraId = user.CarreraId ?? string.Empty,
            IsFirstLogin = user.IsFirstLogin,
            CreatedAt = user.GetCreatedAtAsString() ?? DateTime.UtcNow.ToString("o")
        };
    }
}

public record TeacherDto
{
    public string Id { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Nombre { get; init; } = string.Empty;
    public string Profesion { get; init; } = string.Empty;
    public List<AsignacionDocente> Asignaciones { get; init; } = new();
    public string CreatedAt { get; init; } = string.Empty;

    public static TeacherDto FromUser(User user)
    {
        return new TeacherDto
        {
            Id = user.Id,
            Email = user.Email,
            Nombre = user.Nombre,
            Profesion = user.Profesion ?? string.Empty,
            Asignaciones = user.Asignaciones ?? new List<AsignacionDocente>(),
            CreatedAt = user.GetCreatedAtAsString() ?? DateTime.UtcNow.ToString("o")
        };
    }
}
