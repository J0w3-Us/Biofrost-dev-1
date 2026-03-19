using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.GetByTeacher;

// === QUERY ===
public record GetProjectsByTeacherQuery(string TeacherId) : IRequest<List<ProjectDto>>;

public record ProjectDto(
    string Id,
    string Titulo,
    string? Materia,
    string Estado,
    string LiderId,
    string? LiderNombre,
    string? LiderFotoUrl,
    int MembersCount,
    string? ThumbnailUrl,
    string? VideoUrl,
    string? DocenteId,
    bool EsPublico,
    DateTime CreatedAt,
    double? Calificacion,
    double? PuntosTotales,
    double? PuntosUIUX,
    double? PuntosInovacion,
    double? PuntosPresentacion,
    double? PuntosImpacto,
    List<string> StackTecnologico,
    string? Descripcion,
    Dictionary<string, object>? Votantes
);

// === HANDLER ===
public class GetProjectsByTeacherHandler : IRequestHandler<GetProjectsByTeacherQuery, List<ProjectDto>>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public GetProjectsByTeacherHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<List<ProjectDto>> Handle(GetProjectsByTeacherQuery request, CancellationToken cancellationToken)
    {
        var projects = await _projectRepository.GetByTeacherIdAsync(request.TeacherId);

        var result = new List<ProjectDto>();

        foreach (var p in projects)
        {
            string? liderNombre = null;
            string? liderFotoUrl = null;

            try
            {
                var lider = await _userRepository.GetByIdAsync(p.LiderId);
                liderNombre = lider?.Nombre;
                liderFotoUrl = lider?.FotoUrl;
            }
            catch { /* ignore missing leaders */ }

            // Extract description from first non-empty text canvas block
            string? descripcion = null;
            if (p.CanvasBlocks != null)
            {
                var textTypes = new[] { "text", "h1", "h2", "h3", "quote", "bullet", "todo" };
                var textBlock = p.CanvasBlocks.FirstOrDefault(b =>
                    textTypes.Contains(b.Type?.ToLower()) &&
                    !string.IsNullOrWhiteSpace(b.Content));

                if (textBlock?.Content != null)
                {
                    descripcion = System.Text.RegularExpressions.Regex.Replace(textBlock.Content, "<[^>]+>", "")
                        .Replace("&nbsp;", " ").Trim();
                }
            }

            result.Add(new ProjectDto(
                p.Id,
                p.Titulo,
                p.Materia,
                p.Estado,
                p.LiderId,
                liderNombre,
                liderFotoUrl,
                p.MiembrosIds?.Count ?? 0,
                p.ThumbnailUrl,
                p.VideoUrl,
                p.DocenteId,
                p.EsPublico,
                p.GetCreatedAtAsDateTime(),
                p.Calificacion,
                p.PuntosTotales,
                p.PuntosUIUX,
                p.PuntosInovacion,
                p.PuntosPresentacion,
                p.PuntosImpacto,
                p.StackTecnologico ?? new List<string>(),
                descripcion,
                p.Votantes
            ));
        }

        return result;
    }
}
