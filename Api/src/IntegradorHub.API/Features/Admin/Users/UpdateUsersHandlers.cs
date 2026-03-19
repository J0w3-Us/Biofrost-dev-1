using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Features.Admin.Users;

// ============= UPDATE STUDENT GROUP =============
public record UpdateStudentGroupCommand(string UserId, string NewGrupoId) 
    : IRequest<UpdateStudentGroupResponse>;

public record UpdateStudentGroupResponse(
    bool Success,
    string Message,
    StudentDto? Student = null
);

public class UpdateStudentGroupHandler 
    : IRequestHandler<UpdateStudentGroupCommand, UpdateStudentGroupResponse>
{
    private readonly IUserRepository _userRepository;

    public UpdateStudentGroupHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UpdateStudentGroupResponse> Handle(
        UpdateStudentGroupCommand request, 
        CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(request.UserId);

        if (user == null)
        {
            return new UpdateStudentGroupResponse(false, "Usuario no encontrado");
        }

        if (user.Rol != "Alumno")
        {
            return new UpdateStudentGroupResponse(false, "El usuario no es un alumno");
        }

        var oldGrupoId = user.GrupoId;
        user.GrupoId = request.NewGrupoId;

        await _userRepository.UpdateAsync(user);

        // Log de auditoría
        Console.WriteLine($"[AUDIT] Admin cambió grupo de alumno {user.Matricula}: {oldGrupoId} → {request.NewGrupoId}");

        return new UpdateStudentGroupResponse(
            true, 
            "Grupo actualizado correctamente",
            StudentDto.FromUser(user)
        );
    }
}

// ============= UPDATE TEACHER ASSIGNMENTS =============
public record UpdateTeacherAssignmentsCommand(
    string UserId, 
    List<AsignacionDocente> Asignaciones
) : IRequest<UpdateTeacherAssignmentsResponse>;

public record UpdateTeacherAssignmentsResponse(
    bool Success,
    string Message,
    TeacherDto? Teacher = null
);

public class UpdateTeacherAssignmentsHandler 
    : IRequestHandler<UpdateTeacherAssignmentsCommand, UpdateTeacherAssignmentsResponse>
{
    private readonly IUserRepository _userRepository;

    public UpdateTeacherAssignmentsHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UpdateTeacherAssignmentsResponse> Handle(
        UpdateTeacherAssignmentsCommand request, 
        CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(request.UserId);

        if (user == null)
        {
            return new UpdateTeacherAssignmentsResponse(false, "Usuario no encontrado");
        }

        if (user.Rol != "Docente")
        {
            return new UpdateTeacherAssignmentsResponse(false, "El usuario no es un docente");
        }

        user.Asignaciones = request.Asignaciones;

        await _userRepository.UpdateAsync(user);

        // Log de auditoría
        Console.WriteLine($"[AUDIT] Admin actualizó asignaciones de docente {user.Nombre} ({user.Email})");
        Console.WriteLine($"[AUDIT] Nuevas asignaciones: {request.Asignaciones.Count} asignaciones");

        return new UpdateTeacherAssignmentsResponse(
            true, 
            "Asignaciones actualizadas correctamente",
            TeacherDto.FromUser(user)
        );
    }
}
