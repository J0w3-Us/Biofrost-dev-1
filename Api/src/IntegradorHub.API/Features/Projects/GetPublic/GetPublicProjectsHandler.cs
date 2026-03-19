using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.GetPublic;

// === QUERY ===
public record GetPublicProjectsQuery() : IRequest<IEnumerable<PublicProjectDto>>;



// === HANDLER ===
public class GetPublicProjectsHandler : IRequestHandler<GetPublicProjectsQuery, IEnumerable<PublicProjectDto>>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public GetPublicProjectsHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<IEnumerable<PublicProjectDto>> Handle(GetPublicProjectsQuery request, CancellationToken cancellationToken)
    {
        var projects = await _projectRepository.GetPublicProjectsAsync();

        // Extract unique user IDs for Leaders and Teachers to prevent N+1 queries
        var userIds = projects.Select(p => p.LiderId)
                              .Concat(projects.Where(p => !string.IsNullOrEmpty(p.DocenteId)).Select(p => p.DocenteId!))
                              .Distinct()
                              .ToList();

        // Fetch users in parallel
        var userTasks = userIds.Select(id => _userRepository.GetByIdAsync(id));
        var usersArr = await Task.WhenAll(userTasks);
        var usersDict = usersArr.Where(u => u != null).ToDictionary(u => u!.Id, u => u);

        var result = new List<PublicProjectDto>();
        foreach (var project in projects)
        {
            usersDict.TryGetValue(project.LiderId, out var leader);
            
            User? teacher = null;
            if (!string.IsNullOrEmpty(project.DocenteId))
            {
                usersDict.TryGetValue(project.DocenteId, out teacher);
            }

            // Extract description from first non-empty text block if available
            var description = "";
            var textBlock = project.CanvasBlocks?.FirstOrDefault(b => 
                b.Type == "text" && 
                !string.IsNullOrWhiteSpace(System.Text.RegularExpressions.Regex.Replace(b.Content ?? "", "<[^>]*>", "")));
            
            if (textBlock != null)
            {
                description = System.Text.RegularExpressions.Regex.Replace(textBlock.Content ?? "", "<[^>]*>", "").Trim();
            }

            result.Add(new PublicProjectDto(
                project.Id,
                project.Titulo,
                project.Materia,
                project.Ciclo,
                project.StackTecnologico,
                project.ThumbnailUrl,
                project.RepositorioUrl,
                project.DemoUrl,
                project.VideoUrl,
                leader?.Nombre ?? "Usuario",
                leader?.FotoUrl,
                project.MiembrosIds ?? new List<string>(),
                teacher?.Nombre,
                project.Estado,
                description,
                project.CanvasBlocks ?? new List<CanvasBlock>(),
                project.GetCreatedAtAsDateTime(),
                project.Calificacion,
                project.LiderId,
                project.PuntosTotales,
                project.PuntosUIUX,
                project.PuntosInovacion,
                project.PuntosPresentacion,
                project.PuntosImpacto,
                project.ConteoVotos,
                project.Votantes ?? new Dictionary<string, object>()
            ));
        }

        return result.OrderByDescending(p => p.CreatedAt);
    }
}

public record PublicProjectDto(
    string Id,
    string Titulo,
    string Materia,
    string Ciclo,
    List<string> StackTecnologico,
    string? ThumbnailUrl,
    string? RepositorioUrl,
    string? DemoUrl,
    string? VideoUrl,
    string LiderNombre,
    string? LiderFotoUrl,
    List<string> MiembrosIds,
    string? DocenteNombre,
    string Estado,
    string Descripcion,
    List<CanvasBlock> Canvas,
    DateTime CreatedAt,
    double? Calificacion,
    string LiderId,
    double PuntosTotales,
    double PuntosUIUX,
    double PuntosInovacion,
    double PuntosPresentacion,
    double PuntosImpacto,
    int ConteoVotos,
    Dictionary<string, object> Votantes
);
