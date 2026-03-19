using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
namespace IntegradorHub.API.Features.Teams.GetAvailableStudents;

public record GetAvailableStudentsQuery(string GroupId) : IRequest<List<StudentDto>>;

public record StudentDto(string Id, string NombreCompleto, string Matricula, string FotoUrl);

public class GetAvailableStudentsHandler : IRequestHandler<GetAvailableStudentsQuery, List<StudentDto>>
{
    private readonly IUserRepository _userRepository;

    public GetAvailableStudentsHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<List<StudentDto>> Handle(GetAvailableStudentsQuery request, CancellationToken cancellationToken)
    {
        // Usamos el método optimizado del repositorio
        var studentsInGroup = await _userRepository.GetStudentsByGroupAsync(request.GroupId);
        
        Console.WriteLine($"[DEBUG] GetAvailableStudents: Encontrados {studentsInGroup.Count()} estudiantes en grupo {request.GroupId}.");
        foreach(var s in studentsInGroup) {
            Console.WriteLine($"[DEBUG] Estudiante: {s.Nombre} {s.Matricula}, ProjectId: '{s.ProjectId}'");
        }

        var availableStudents = studentsInGroup
            // Regla de Exclusividad: Solo aquellos que NO tienen ProjectId asignado
            .Where(u => string.IsNullOrEmpty(u.ProjectId)) 
            .Select(u => new StudentDto(
                u.Id,
                $"{u.Nombre} {u.ApellidoPaterno} {u.ApellidoMaterno}".Trim(),
                u.Matricula ?? "S/M",
                u.FotoUrl ?? ""
            ))
            .ToList();

        return availableStudents;
    }
}
