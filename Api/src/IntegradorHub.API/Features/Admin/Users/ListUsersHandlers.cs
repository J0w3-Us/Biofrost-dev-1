using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Admin.Users;

// ============= LIST STUDENTS =============
public record ListStudentsQuery(string? GrupoId = null) : IRequest<List<StudentDto>>;

public class ListStudentsHandler : IRequestHandler<ListStudentsQuery, List<StudentDto>>
{
    private readonly IUserRepository _userRepository;

    public ListStudentsHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<List<StudentDto>> Handle(ListStudentsQuery request, CancellationToken cancellationToken)
    {
        IEnumerable<Shared.Domain.Entities.User> students;

        if (!string.IsNullOrEmpty(request.GrupoId))
        {
            Console.WriteLine($"[DEBUG] Buscando alumnos por grupo: '{request.GrupoId}'");
            students = await _userRepository.GetStudentsByGroupAsync(request.GrupoId);
            Console.WriteLine($"[DEBUG] Encontrados en grupo: {students.Count()}");
        }
        else
        {
            Console.WriteLine("[DEBUG] Buscando alumnos por rol 'Alumno' y 'alumno'");
            // Intentamos obtener con casing "Alumno" y "alumno" para robustez
            var studentsTitle = await _userRepository.GetByRoleAsync("Alumno");
            var studentsLower = await _userRepository.GetByRoleAsync("alumno");
            
            Console.WriteLine($"[DEBUG] Encontrados 'Alumno': {studentsTitle.Count()}");
            Console.WriteLine($"[DEBUG] Encontrados 'alumno': {studentsLower.Count()}");

            // Unimos y eliminamos duplicados por ID
            students = studentsTitle.Concat(studentsLower)
                .GroupBy(u => u.Id)
                .Select(g => g.First());
            
            Console.WriteLine($"[DEBUG] Total combinados: {students.Count()}");
        }

        return students
            .Select(StudentDto.FromUser)
            .OrderBy(s => s.Nombre)
            .ToList();
    }
}

// ============= LIST TEACHERS =============
public record ListTeachersQuery : IRequest<List<TeacherDto>>;

public class ListTeachersHandler : IRequestHandler<ListTeachersQuery, List<TeacherDto>>
{
    private readonly IUserRepository _userRepository;

    public ListTeachersHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<List<TeacherDto>> Handle(ListTeachersQuery request, CancellationToken cancellationToken)
    {
        // Intentamos obtener con casing "Docente" y "docente" para robustez
        var teachersTitle = await _userRepository.GetByRoleAsync("Docente");
        var teachersLower = await _userRepository.GetByRoleAsync("docente");

        var teachers = teachersTitle.Concat(teachersLower)
            .GroupBy(u => u.Id)
            .Select(g => g.First());

        return teachers
            .Select(TeacherDto.FromUser)
            .OrderBy(t => t.Nombre)
            .ToList();
    }
}
