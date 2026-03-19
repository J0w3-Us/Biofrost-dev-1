using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Evaluations.Visibility;

public record UpdateEvaluationVisibilityCommand(string EvaluationId, string UserId, bool EsPublico) : IRequest<UpdateEvaluationVisibilityResponse>;

public record UpdateEvaluationVisibilityResponse(bool Success, string Message);

public class UpdateEvaluationVisibilityHandler : IRequestHandler<UpdateEvaluationVisibilityCommand, UpdateEvaluationVisibilityResponse>
{
    private readonly IEvaluationRepository _evaluationRepository;
    private readonly IUserRepository _userRepository;

    public UpdateEvaluationVisibilityHandler(IEvaluationRepository evaluationRepository, IUserRepository userRepository)
    {
        _evaluationRepository = evaluationRepository;
        _userRepository = userRepository;
    }

    public async Task<UpdateEvaluationVisibilityResponse> Handle(UpdateEvaluationVisibilityCommand request, CancellationToken cancellationToken)
    {
        var evaluation = await _evaluationRepository.GetByIdAsync(request.EvaluationId);
        if (evaluation == null)
            throw new KeyNotFoundException("Evaluación no encontrada");

        // Validate permissions: Only the creator (docente) or Admin can change visibility
        var user = await _userRepository.GetByIdAsync(request.UserId);
        if (user == null) 
            throw new UnauthorizedAccessException("Usuario no encontrado");

        bool isAdmin = user.Rol == "admin" || user.Rol == "SuperAdmin";
        bool isCreator = evaluation.DocenteId == request.UserId;

        if (!isAdmin && !isCreator)
            throw new UnauthorizedAccessException("No tienes permiso para modificar esta evaluación");

        // Update visibility
        evaluation.EsPublico = request.EsPublico;
        
        await _evaluationRepository.UpdateAsync(evaluation);

        return new UpdateEvaluationVisibilityResponse(true, "Visibilidad actualizada correctamente");
    }
}
