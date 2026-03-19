using FluentValidation;
using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Enums;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.Create;

// === COMMAND ===
public record CreateProjectCommand(
    string Titulo,
    string Materia,
    string MateriaId,
    string Ciclo,
    List<string> StackTecnologico,
    string? RepositorioUrl,
    string? VideoUrl,
    string UserId, // ID del usuario autenticado (Líder)
    string UserGroupId, // Grupo del usuario (para validación)
    string? DocenteId,
    List<string> MiembrosIds
) : IRequest<CreateProjectResponse>;

public record CreateProjectResponse(string ProjectId);

// === VALIDATOR ===
public class CreateProjectValidator : AbstractValidator<CreateProjectCommand>
{
    public CreateProjectValidator()
    {
        RuleFor(x => x.Titulo).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Materia).NotEmpty();
        RuleFor(x => x.MateriaId).NotEmpty();
        RuleFor(x => x.Ciclo).NotEmpty().Matches(@"^\d{4}-\d$"); // Ej: 2024-1
        RuleFor(x => x.StackTecnologico).Must(x => x.Count > 0).WithMessage("Debe incluir al menos una tecnología");
        RuleFor(x => x.RepositorioUrl).Must(uri => Uri.TryCreate(uri, UriKind.Absolute, out _))
            .When(x => !string.IsNullOrEmpty(x.RepositorioUrl))
            .WithMessage("URL de repositorio inválida");

        RuleFor(x => x.VideoUrl).Must(uri => Uri.TryCreate(uri, UriKind.Absolute, out _))
            .When(x => !string.IsNullOrEmpty(x.VideoUrl))
            .WithMessage("URL de video inválida");
        
        // REGLA DE NEGOCIO: Máximo 5 integrantes (Líder + 4 invitados)
        RuleFor(x => x.MiembrosIds).Must(x => x.Count <= 4)
            .WithMessage("El equipo no puede tener más de 5 integrantes (incluyendo al líder).");
    }
}

// === HANDLER ===
public class CreateProjectHandler : IRequestHandler<CreateProjectCommand, CreateProjectResponse>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public CreateProjectHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<CreateProjectResponse> Handle(CreateProjectCommand request, CancellationToken cancellationToken)
    {
        // 1. Validar al Líder (Usuario actual)
        var leader = await _userRepository.GetByIdAsync(request.UserId);
        if (leader == null) throw new UnauthorizedAccessException("Usuario no encontrado");
        
        if (leader.Rol != nameof(UserRole.Alumno))
            throw new UnauthorizedAccessException("Solo los alumnos pueden crear proyectos");

        // 3. Validar Docente (Si se seleccionó uno)
        if (!string.IsNullOrEmpty(request.DocenteId))
        {
            var teacher = await _userRepository.GetByIdAsync(request.DocenteId);
            if (teacher == null) 
                throw new KeyNotFoundException("El docente seleccionado no existe.");
            
            if (teacher.Rol != nameof(UserRole.Docente) && teacher.Rol != "Admin") 
                throw new InvalidOperationException("El usuario seleccionado no tiene rol de Docente.");

            // VALIDACIÓN ESTRICTA: El docente debe estar asignado al grupo del líder
            var isAssignedToGroup = teacher.Asignaciones?
                .Any(a => a.GruposIds.Contains(leader.GrupoId ?? string.Empty)) ?? false;

            if (!isAssignedToGroup && teacher.Rol != "Admin")
            {
                throw new InvalidOperationException($"El docente {teacher.Nombre} no imparte clases al grupo {leader.GrupoId}.");
            }
        }

        // REGLA DE NEGOCIO: Exclusividad (Líder no debe tener proyecto)
        if (!string.IsNullOrEmpty(leader.ProjectId))
            throw new InvalidOperationException("Ya perteneces a un equipo. Debes salirte antes de crear uno nuevo.");

        var finalMembers = new List<User> { leader };
        var finalMemberIds = new List<string> { leader.Id };

        // 2. Validar Miembros Invitados
        if (request.MiembrosIds != null && request.MiembrosIds.Any())
        {
            foreach (var memberId in request.MiembrosIds)
            {
                if (memberId == leader.Id) continue; // Ignorar si se auto-agregó

                var member = await _userRepository.GetByIdAsync(memberId);
                if (member == null) continue; // O lanzar error

                // REGLA: Mismo Grupo
                if (member.GrupoId != leader.GrupoId)
                    throw new InvalidOperationException($"El alumno {member.Nombre} no pertenece a tu grupo.");

                // REGLA: Exclusividad
                if (!string.IsNullOrEmpty(member.ProjectId))
                    throw new InvalidOperationException($"El alumno {member.Nombre} ya tiene un proyecto asignado.");

                finalMembers.Add(member);
                finalMemberIds.Add(member.Id);
            }
        }

        // 3. Crear entidad Proyecto
        var project = new Project
        {
            Id = Guid.NewGuid().ToString(),
            Titulo = request.Titulo,
            Materia = request.Materia,
            MateriaId = request.MateriaId,
            Ciclo = request.Ciclo,
            GrupoId = request.UserGroupId,
            LiderId = request.UserId,
            MiembrosIds = finalMemberIds, 
            DocenteId = request.DocenteId, // Asignar docente seleccionado
            Estado = nameof(ProjectState.Borrador),
            StackTecnologico = request.StackTecnologico,
            RepositorioUrl = request.RepositorioUrl,
            VideoUrl = request.VideoUrl,
            CreatedAt = Google.Cloud.Firestore.Timestamp.GetCurrentTimestamp(),
            UpdatedAt = Google.Cloud.Firestore.Timestamp.GetCurrentTimestamp()
        };

        // 4. Guardar Proyecto
        await _projectRepository.CreateAsync(project);

        // 5. Actualizar Usuarios (Asignar ProjectId) - "Batch" manual
        foreach (var user in finalMembers)
        {
            user.ProjectId = project.Id; // Vincular usuario al equipo
            await _userRepository.UpdateAsync(user);
        }

        return new CreateProjectResponse(project.Id);
    }
}
