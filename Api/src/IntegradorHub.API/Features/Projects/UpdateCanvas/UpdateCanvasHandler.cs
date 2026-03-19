using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.UpdateCanvas;

// === COMMAND ===
public record UpdateProjectCanvasCommand(
    string ProjectId,
    List<CanvasBlock> Blocks,
    string UserId
) : IRequest<UpdateCanvasResponse>;

public record UpdateCanvasResponse(bool Success, string Message);

// === HANDLER ===
public class UpdateCanvasHandler : IRequestHandler<UpdateProjectCanvasCommand, UpdateCanvasResponse>
{
    private readonly IProjectRepository _projectRepository;

    public UpdateCanvasHandler(IProjectRepository projectRepository)
    {
        _projectRepository = projectRepository;
    }

    public async Task<UpdateCanvasResponse> Handle(UpdateProjectCanvasCommand request, CancellationToken cancellationToken)
    {
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null) 
            throw new KeyNotFoundException("Proyecto no encontrado");

        // Validar permisos: Solo miembros o líder pueden editar el canvas
        if (project.LiderId != request.UserId && !project.MiembrosIds.Contains(request.UserId))
            throw new UnauthorizedAccessException("No tienes permiso para editar este proyecto");

        // Actualizar canvas
        project.CanvasBlocks = request.Blocks;
        
        // Actualizar fecha de modificación (si tuviéramos ese campo, por ahora lo omitimos o agregamos en futuro)
        // project.LastModified = DateTime.UtcNow;

        await _projectRepository.UpdateAsync(project);

        return new UpdateCanvasResponse(true, "Canvas actualizado correctamente");
    }
}
