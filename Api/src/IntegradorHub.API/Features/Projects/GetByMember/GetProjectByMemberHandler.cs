using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Features.Projects.GetDetails; // Resusing DTOs

namespace IntegradorHub.API.Features.Projects.GetByMember;

// === QUERY ===
public record GetProjectByMemberQuery(string UserId) : IRequest<ProjectDetailsDto?>;

// === HANDLER ===
public class GetProjectByMemberHandler : IRequestHandler<GetProjectByMemberQuery, ProjectDetailsDto?>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public GetProjectByMemberHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<ProjectDetailsDto?> Handle(GetProjectByMemberQuery request, CancellationToken cancellationToken)
    {
        var projects = await _projectRepository.GetByMemberIdAsync(request.UserId);
        var project = projects.FirstOrDefault();

        if (project == null) return null;

        // Populate members logic
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

        // Handle potentially null EsPublico in DB (though default is false in entity)
        // Project entity has it.

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
