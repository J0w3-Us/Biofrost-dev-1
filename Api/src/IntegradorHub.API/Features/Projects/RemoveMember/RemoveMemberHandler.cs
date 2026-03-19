using FluentValidation;
using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.RemoveMember;

// === COMMAND ===
public record RemoveMemberCommand(
    string ProjectId,
    string MemberIdToRemove,
    string RequestingUserId // ID del usuario que ejecuta la acción (Líder o el mismo usuario saliéndose)
) : IRequest<RemoveMemberResponse>;

public record RemoveMemberResponse(bool Success, string Message);

// === HANDLER ===
public class RemoveMemberHandler : IRequestHandler<RemoveMemberCommand, RemoveMemberResponse>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public RemoveMemberHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<RemoveMemberResponse> Handle(RemoveMemberCommand request, CancellationToken cancellationToken)
    {
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null) 
            throw new KeyNotFoundException("Proyecto no encontrado");

        // Validar permisos:
        // 1. Líder eliminando a alguien
        // 2. Miembro saliéndose voluntariamente
        bool isLeader = project.LiderId == request.RequestingUserId;
        bool isSelfRemoval = request.MemberIdToRemove == request.RequestingUserId;

        if (!isLeader && !isSelfRemoval)
            throw new UnauthorizedAccessException("No tienes permiso para eliminar a este miembro");

        // No puedes eliminar al líder (debe transferir liderazgo primero o borrar proyecto)
        if (request.MemberIdToRemove == project.LiderId)
             return new RemoveMemberResponse(false, "No se puede eliminar al líder del proyecto. Transfiere el liderazgo o elimina el proyecto.");

        if (!project.MiembrosIds.Contains(request.MemberIdToRemove))
            return new RemoveMemberResponse(false, "El usuario no es miembro del proyecto");

        // CORRECCIÓN: Actualizar proyecto Y usuario para evitar inconsistencia
        project.MiembrosIds.Remove(request.MemberIdToRemove);
        await _projectRepository.UpdateAsync(project);

        // Buscar al miembro y limpiar su ProjectId
        var member = await _userRepository.GetByIdAsync(request.MemberIdToRemove);
        if (member != null)
        {
            member.ProjectId = null;
            await _userRepository.UpdateAsync(member);
        }

        return new RemoveMemberResponse(true, "Miembro eliminado exitosamente"); 
    }
}
