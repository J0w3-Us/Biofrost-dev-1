using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Features.Evaluations.Create;

// === COMMAND ===
public record CreateEvaluationCommand(
    string ProjectId,
    string DocenteId,
    string DocenteNombre,
    string Tipo,          // "oficial" | "sugerencia"
    string Contenido,
    int? Calificacion     // Solo para tipo "oficial", 0-100
) : IRequest<CreateEvaluationResponse>;

public record CreateEvaluationResponse(bool Success, string Message, string? EvaluationId);

// === HANDLER ===
public class CreateEvaluationHandler : IRequestHandler<CreateEvaluationCommand, CreateEvaluationResponse>
{
    private readonly IEvaluationRepository _evaluationRepository;
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;
    private readonly IMateriaRepository _materiaRepository;

    public CreateEvaluationHandler(
        IEvaluationRepository evaluationRepository,
        IProjectRepository projectRepository,
        IUserRepository userRepository,
        IMateriaRepository materiaRepository)
    {
        _evaluationRepository = evaluationRepository;
        _projectRepository = projectRepository;
        _userRepository = userRepository;
        _materiaRepository = materiaRepository;
    }

    public async Task<CreateEvaluationResponse> Handle(CreateEvaluationCommand request, CancellationToken cancellationToken)
    {
        // Validar que el proyecto existe
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null)
            throw new KeyNotFoundException("Proyecto no encontrado");

        // Validar que el usuario existe
        var docente = await _userRepository.GetByIdAsync(request.DocenteId);
        if (docente == null)
            throw new UnauthorizedAccessException("Usuario no encontrado");

        bool isDocente = docente.Rol == "Docente";
        bool isInvitado = docente.Rol == "Invitado";

        // Solo Docentes e Invitados pueden evaluar; otros roles no tienen este flujo
        if (!isDocente && !isInvitado)
            throw new UnauthorizedAccessException("No tienes permiso para evaluar proyectos");

        // Los Invitados solo pueden dejar sugerencias, nunca calificaciones oficiales
        if (isInvitado && request.Tipo == "oficial")
            throw new UnauthorizedAccessException("Los invitados solo pueden dejar sugerencias. Las calificaciones oficiales son exclusivas de los docentes.");

        // Validar tipo
        if (request.Tipo != "oficial" && request.Tipo != "sugerencia")
            throw new ArgumentException("Tipo de evaluación inválido. Debe ser 'oficial' o 'sugerencia'");

        // Validar calificación si es oficial (solo aplica a Docentes)
        if (request.Tipo == "oficial")
        {
            bool isTitular = project.DocenteId == request.DocenteId;
            bool isAdmin = docente.Rol == "admin" || docente.Rol == "SuperAdmin";

            // STRICT CHECK: Only Titular Project Leader or Admin can give Official Grades (0-100).
            // Other teachers/advisors can only give "Sugerencia" (or use the Star Rating system).
            if (!isTitular && !isAdmin)
                throw new UnauthorizedAccessException("Solo el docente titular asignado al proyecto puede realizar evaluaciones oficiales (calificación 0-100). Otros docentes pueden dejar sugerencias.");

            if (!request.Calificacion.HasValue || request.Calificacion < 0 || request.Calificacion > 100)
                throw new ArgumentException("Las evaluaciones oficiales requieren una calificación entre 0 y 100");
        }

        // Crear evaluación
        var evaluation = new Evaluation
        {
            ProjectId = request.ProjectId,
            DocenteId = request.DocenteId,
            DocenteNombre = request.DocenteNombre,
            Tipo = request.Tipo,
            Contenido = request.Contenido,
            Calificacion = request.Tipo == "oficial" ? request.Calificacion : null
        };

        if (request.Tipo == "oficial" && request.Calificacion.HasValue)
        {
            // Actualizar la calificación oficial del proyecto
            project.Calificacion = request.Calificacion.Value;

            // Update Project in DB
            await _projectRepository.UpdateAsync(project);
        }

        await _evaluationRepository.CreateAsync(evaluation);

        return new CreateEvaluationResponse(true, "Evaluación creada correctamente", evaluation.Id);
    }
}
