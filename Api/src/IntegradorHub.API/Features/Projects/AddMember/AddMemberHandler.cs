using FluentValidation;
using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Shared.Domain.ValueObjects;

namespace IntegradorHub.API.Features.Projects.AddMember;

// === COMMAND ===
public record AddMemberCommand(
    string ProjectId,
    string MemberEmailOrMatricula,
    string LeaderId // ID del usuario que ejecuta la acción (para validar permisos)
) : IRequest<AddMemberResponse>;

public record AddMemberResponse(bool Success, string Message, string? NewMemberId = null, string? NewMemberName = null);

// === VALIDATOR ===
public class AddMemberValidator : AbstractValidator<AddMemberCommand>
{
    public AddMemberValidator()
    {
        RuleFor(x => x.ProjectId).NotEmpty();
        RuleFor(x => x.MemberEmailOrMatricula).NotEmpty();
        RuleFor(x => x.LeaderId).NotEmpty();
    }
}

// === HANDLER ===
public class AddMemberHandler : IRequestHandler<AddMemberCommand, AddMemberResponse>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public AddMemberHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<AddMemberResponse> Handle(AddMemberCommand request, CancellationToken cancellationToken)
    {
        // 1. Obtener Proyecto
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null) 
            throw new KeyNotFoundException("Proyecto no encontrado");

        // 2. Validar permisos (Solo el líder puede agregar)
        if (project.LiderId != request.LeaderId)
            throw new UnauthorizedAccessException("Solo el líder del proyecto puede agregar miembros");

        // 3. Validar límite de miembros (ej: Máximo 5)
        if (project.MiembrosIds.Count >= 5)
            return new AddMemberResponse(false, "El equipo ya ha alcanzado el límite de 5 integrantes");

        // 4. Buscar usuario a agregar (Por Email o Matrícula)
        User? memberToAdd = null;
        
        // Intentar por Email primero
        if (request.MemberEmailOrMatricula.Contains("@"))
        {
            memberToAdd = await _userRepository.GetByEmailAsync(request.MemberEmailOrMatricula);
        }
        else 
        {
            // Intentar buscar por matrícula (asumiendo que implementamos búsqueda por matrícula o usamos Search)
            // Por simplicidad en este paso, iteramos o buscamos directo si el repo lo soporta.
            // Para MVP, vamos a asumir que el input es Email exacto o Matrícula exacta.
            // Necesitamos un método GetByMatricula en el repo o usar Search.
            // Usaremos Search del repositorio existente que busca por nombre o matrícula dentro del grupo.
            
            var usersInGroup = await _userRepository.GetByGroupIdAsync(project.GrupoId);
            memberToAdd = usersInGroup.FirstOrDefault(u => 
                u.Matricula?.Equals(request.MemberEmailOrMatricula, StringComparison.OrdinalIgnoreCase) == true);
        }

        if (memberToAdd == null)
            return new AddMemberResponse(false, "Usuario no encontrado. Asegúrate que ya se haya registrado en la plataforma.");

        // 5. Validar que sea del mismo grupo (Regla de negocio estricta para IntegradorHub)
        if (memberToAdd.GrupoId != project.GrupoId)
            return new AddMemberResponse(false, $"El usuario pertenece a otro grupo ({memberToAdd.GrupoId})");

        // 6. Validar Exclusividad (Un alumno = Un equipo)
        if (!string.IsNullOrEmpty(memberToAdd.ProjectId))
             return new AddMemberResponse(false, $"El alumno {memberToAdd.Nombre} ya tiene un proyecto asignado.");

        // 7. Validar que no esté ya en el proyecto (Redundante pero seguro)
        if (project.MiembrosIds.Contains(memberToAdd.Id))
            return new AddMemberResponse(false, "El usuario ya es miembro del equipo");

        // 7. Validar que no esté en OTRO proyecto de la misma materia/ciclo (TODO: Requiere query compleja, pendiente para v2)
        // Por ahora confiamos en la buena fe o validación visual.

        // 8. Agregar miembro y guardar cambios en el proyecto
        project.MiembrosIds.Add(memberToAdd.Id);
        await _projectRepository.UpdateAsync(project);
        
        // 9. Actualizar el perfil del usuario para asociarle este proyecto
        memberToAdd.ProjectId = project.Id;
        await _userRepository.UpdateAsync(memberToAdd);

        return new AddMemberResponse(true, "Miembro agregado exitosamente", memberToAdd.Id, memberToAdd.Nombre);
    }
}
