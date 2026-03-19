using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.GetDetails;

// === QUERY ===
public record GetProjectDetailsQuery(string ProjectId) : IRequest<ProjectDetailsDto>;

// === HANDLER ===
public class GetProjectDetailsHandler : IRequestHandler<GetProjectDetailsQuery, ProjectDetailsDto>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public GetProjectDetailsHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<ProjectDetailsDto> Handle(GetProjectDetailsQuery request, CancellationToken cancellationToken)
    {
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null) throw new KeyNotFoundException("Proyecto no encontrado");

        var members = new List<MemberDto>();
        if (project.MiembrosIds != null)
        {
            foreach (var memberId in project.MiembrosIds)
            {
                var user = await _userRepository.GetByIdAsync(memberId);
                if (user != null)
                {
                    members.Add(new MemberDto(
                        user.Id,
                        user.Nombre,
                        user.Email,
                        user.FotoUrl,
                        memberId == project.LiderId ? "Líder" : "Miembro"
                    ));
                }
            }
        }

        return new ProjectDetailsDto(
            project.Id,
            project.Titulo,
            project.Materia,
            project.MateriaId,
            project.Ciclo,
            project.GrupoId,
            project.Estado,
            project.LiderId,
            project.DocenteId,
            project.MiembrosIds ?? new List<string>(),
            project.StackTecnologico,
            project.RepositorioUrl,
            project.VideoUrl,
            project.CanvasBlocks,
            members,
            project.GetCreatedAtAsDateTime(),
            project.EsPublico,
            project.PuntosTotales,
            project.PuntosUIUX,
            project.PuntosInovacion,
            project.PuntosPresentacion,
            project.PuntosImpacto,
            project.ConteoVotos,
            project.Votantes ?? new Dictionary<string, object>(),
            project.Calificacion
        );
    }
}

public record ProjectDetailsDto(
    string Id,
    string Titulo,
    string Materia,
    string MateriaId,
    string Ciclo,
    string GrupoId,
    string Estado,
    string LiderId,
    string? DocenteId,
    List<string> MiembrosIds,
    List<string> StackTecnologico,
    string? RepositorioUrl,
    string? VideoUrl,
    List<CanvasBlock> Canvas,
    List<MemberDto> Members,
    DateTime CreatedAt,
    bool EsPublico,
    double PuntosTotales,
    double PuntosUIUX,
    double PuntosInovacion,
    double PuntosPresentacion,
    double PuntosImpacto,
    int ConteoVotos,
    Dictionary<string, object> Votantes,
    double? Calificacion
);

public record MemberDto(string Id, string Nombre, string Email, string? FotoUrl, string Rol);
