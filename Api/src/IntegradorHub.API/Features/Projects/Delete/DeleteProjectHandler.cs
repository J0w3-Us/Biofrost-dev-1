using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.Delete;

// === COMMAND ===
public record DeleteProjectCommand(
    string ProjectId,
    string RequestingUserId // ID del usuario que solicita eliminar
) : IRequest<DeleteProjectResponse>;

public record DeleteProjectResponse(bool Success, string Message);

// === HANDLER ===
public class DeleteProjectHandler : IRequestHandler<DeleteProjectCommand, DeleteProjectResponse>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;
    private readonly IEvaluationRepository _evaluationRepository;

    public DeleteProjectHandler(
        IProjectRepository projectRepository, 
        IUserRepository userRepository,
        IEvaluationRepository evaluationRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
        _evaluationRepository = evaluationRepository;
    }

    public async Task<DeleteProjectResponse> Handle(DeleteProjectCommand request, CancellationToken cancellationToken)
    {
        Console.WriteLine($"[DELETE-DEBUG] Starting deletion for project: {request.ProjectId} (Requested by: {request.RequestingUserId})");
        
        try 
        {
            var project = await _projectRepository.GetByIdAsync(request.ProjectId);
            if (project == null) 
            {
                Console.WriteLine($"[DELETE-DEBUG] Project not found: {request.ProjectId}");
                return new DeleteProjectResponse(false, "Proyecto no encontrado");
            }

            // Validar que sea el líder, un docente asignado o un administrador
            var requestingUser = await _userRepository.GetByIdAsync(request.RequestingUserId);
            
            bool isLeader = project.LiderId == request.RequestingUserId;
            bool isAdmin = requestingUser?.Rol == "Admin" || requestingUser?.Rol == "SuperAdmin";
            bool isAssignedTeacher = (requestingUser?.Rol == "Docente" && project.DocenteId == request.RequestingUserId);

            Console.WriteLine($"[DELETE-DEBUG] Auth Check: isLeader={isLeader}, isAdmin={isAdmin}, isAssignedTeacher={isAssignedTeacher}");

            if (!isLeader && !isAdmin && !isAssignedTeacher)
            {
                Console.WriteLine($"[DELETE-DEBUG] Unauthorized attempt by: {request.RequestingUserId}");
                return new DeleteProjectResponse(false, "No tienes permisos suficientes para eliminar este proyecto.");
            }

            // 1. Eliminar evaluaciones (Cascade Delete)
            Console.WriteLine($"[DELETE-DEBUG] Step 1: Fetching evaluations for project: {request.ProjectId}");
            var evaluations = await _evaluationRepository.GetByProjectIdAsync(request.ProjectId);
            int evalCount = 0;
            foreach (var evaluation in evaluations)
            {
                Console.WriteLine($"[DELETE-DEBUG] Deleting evaluation: {evaluation.Id}");
                await _evaluationRepository.DeleteAsync(evaluation.Id);
                evalCount++;
            }
            Console.WriteLine($"[DELETE-DEBUG] Step 1 complete. Deleted {evalCount} evaluations.");

            // 2. Liberar a los miembros (User.ProjectId = null)
            // Usamos project.MiembrosIds y project.LiderId para asegurar limpieza
            Console.WriteLine("[DELETE-DEBUG] Step 2: Releasing members...");
            var usersToRelease = new List<string>(project.MiembrosIds);
            if (!usersToRelease.Contains(project.LiderId)) 
                usersToRelease.Add(project.LiderId);

            int releasedCount = 0;
            foreach (var userId in usersToRelease)
            {
                var member = await _userRepository.GetByIdAsync(userId);
                if (member != null && member.ProjectId == request.ProjectId)
                {
                    Console.WriteLine($"[DELETE-DEBUG] Releasing member: {member.Id}");
                    member.ProjectId = null;
                    await _userRepository.UpdateAsync(member);
                    releasedCount++;
                }
            }
            Console.WriteLine($"[DELETE-DEBUG] Step 2 complete. Released {releasedCount} members.");

            // 3. Eliminar el proyecto
            Console.WriteLine($"[DELETE-DEBUG] Step 3: Deleting project document: {request.ProjectId}");
            await _projectRepository.DeleteAsync(request.ProjectId);
            
            Console.WriteLine("[DELETE-DEBUG] All steps completed successfully.");
            return new DeleteProjectResponse(true, "Proyecto eliminado y equipo disuelto exitosamente.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[DELETE-DEBUG] CRITICAL ERROR during deletion: {ex.Message}");
            Console.WriteLine($"[DELETE-DEBUG] StackTrace: {ex.StackTrace}");
            return new DeleteProjectResponse(false, $"Error interno al eliminar el proyecto: {ex.Message}");
        }
    }
}
