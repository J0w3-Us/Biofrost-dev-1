using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Teams.GetAvailableTeachers;

public record GetAvailableTeachersQuery(string GroupId, string? CarreraId = null) : IRequest<List<TeacherDto>>;

    public record TeacherDto(string Id, string NombreCompleto, string Profesion, string Carrera, string Asignatura, string? MateriaId, bool EsAltaPrioridad);
    
    public class GetAvailableTeachersHandler : IRequestHandler<GetAvailableTeachersQuery, List<TeacherDto>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IMateriaRepository _materiaRepository;
    
        public GetAvailableTeachersHandler(IUserRepository userRepository, IMateriaRepository materiaRepository)
        {
            _userRepository = userRepository;
            _materiaRepository = materiaRepository;
        }
    
        public async Task<List<TeacherDto>> Handle(GetAvailableTeachersQuery request, CancellationToken cancellationToken)
        {
            var teachersInGroup = await _userRepository.GetTeachersByGroupAsync(request.GroupId, request.CarreraId);
            var materias = await _materiaRepository.GetAllActiveAsync();
            var materiasMap = materias.ToDictionary(m => m.Id, m => m); // Store full Materia object
    
            var availableTeachers = teachersInGroup
                .Select(u => {
                    // Obtener TODAS las asignaciones para este grupo
                    var asignacionesDelGrupo = u.Asignaciones?
                        .Where(a => a.GruposIds.Contains(request.GroupId))
                        .ToList() ?? new List<AsignacionDocente>();
                    
                    if (!asignacionesDelGrupo.Any()) return null;

                    // PRIORIDAD: Buscar primero si tiene alguna materia de Alta Prioridad (Integradora)
                    var asignacionPrioritaria = asignacionesDelGrupo
                        .FirstOrDefault(a => materiasMap.TryGetValue(a.MateriaId, out var m) && m.EsAltaPrioridad);

                    // Si no tiene alta prioridad, tomar la primera disponible
                    var asignacionFinal = asignacionPrioritaria ?? asignacionesDelGrupo.First();
                    
                    var materiaNombre = "Docente";
                    var esAltaPrioridad = false;

                    if (asignacionFinal != null && materiasMap.TryGetValue(asignacionFinal.MateriaId, out var materia))
                    {
                        materiaNombre = materia.Nombre;
                        esAltaPrioridad = materia.EsAltaPrioridad;
                    }
                    
                    return new TeacherDto(
                        u.Id,
                        $"{u.Nombre} {u.ApellidoPaterno} {u.ApellidoMaterno}".Trim(),
                        u.Profesion ?? "Docente",
                        asignacionFinal?.CarreraId ?? "", 
                        materiaNombre,
                        asignacionFinal?.MateriaId,
                        esAltaPrioridad
                    );
                })
                .Where(t => t != null) // Filter out nulls
                .OrderByDescending(t => t!.EsAltaPrioridad) // High Priority first
                .ThenBy(t => t!.NombreCompleto)
                .ToList();
    
            return availableTeachers!;
    }
}
