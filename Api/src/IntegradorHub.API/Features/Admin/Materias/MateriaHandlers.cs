using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using Google.Cloud.Firestore;
using IntegradorHub.API.Features.Admin.Groups; // Added to resolve GroupDto reference

namespace IntegradorHub.API.Features.Admin.Materias;

// === COMMAND: Create Materia ===
public record CreateMateriaCommand(
    string Nombre,
    string Clave,
    int Cuatrimestre
) : IRequest<CreateMateriaResponse>;

public record CreateMateriaResponse(bool Success, string Message, string? MateriaId);

public class CreateMateriaHandler : IRequestHandler<CreateMateriaCommand, CreateMateriaResponse>
{
    private readonly IMateriaRepository _materiaRepository;

    public CreateMateriaHandler(IMateriaRepository materiaRepository)
    {
        _materiaRepository = materiaRepository;
    }

    public async Task<CreateMateriaResponse> Handle(CreateMateriaCommand request, CancellationToken cancellationToken)
    {
        var materia = new Materia
        {
            Nombre = request.Nombre,
            Clave = request.Clave,
            Cuatrimestre = request.Cuatrimestre,
            IsActive = true,
            CreatedAt = Timestamp.GetCurrentTimestamp()
        };

        await _materiaRepository.CreateAsync(materia);

        return new CreateMateriaResponse(true, "Materia creada correctamente", materia.Id);
    }
}

// === QUERY: Get All Materias ===
public record GetAllMateriasQuery() : IRequest<IEnumerable<MateriaDto>>;

public record MateriaDto(
    string Id,
    string Nombre,
    string Clave,
    int Cuatrimestre,
    bool IsActive
);

public class GetAllMateriasHandler : IRequestHandler<GetAllMateriasQuery, IEnumerable<MateriaDto>>
{
    private readonly IMateriaRepository _materiaRepository;

    public GetAllMateriasHandler(IMateriaRepository materiaRepository)
    {
        _materiaRepository = materiaRepository;
    }

    public async Task<IEnumerable<MateriaDto>> Handle(GetAllMateriasQuery request, CancellationToken cancellationToken)
    {
        var materias = await _materiaRepository.GetAllActiveAsync();
        return materias.Select(m => new MateriaDto(
            m.Id,
            m.Nombre,
            m.Clave,
            m.Cuatrimestre,
            m.IsActive
        ));
    }
}

// === COMMAND: Update Materia ===
public record UpdateMateriaCommand(
    string Id,
    string? Nombre,
    string? Clave,
    int? Cuatrimestre,
    bool? IsActive
) : IRequest<UpdateMateriaResponse>;

public record UpdateMateriaResponse(bool Success, string Message);

public class UpdateMateriaHandler : IRequestHandler<UpdateMateriaCommand, UpdateMateriaResponse>
{
    private readonly IMateriaRepository _materiaRepository;

    public UpdateMateriaHandler(IMateriaRepository materiaRepository)
    {
        _materiaRepository = materiaRepository;
    }

    public async Task<UpdateMateriaResponse> Handle(UpdateMateriaCommand request, CancellationToken cancellationToken)
    {
        var materia = await _materiaRepository.GetByIdAsync(request.Id);
        if (materia == null)
            return new UpdateMateriaResponse(false, "Materia no encontrada");

        materia.Nombre = request.Nombre ?? materia.Nombre;
        materia.Clave = request.Clave ?? materia.Clave;
        materia.Cuatrimestre = request.Cuatrimestre ?? materia.Cuatrimestre;
        materia.IsActive = request.IsActive ?? materia.IsActive;

        await _materiaRepository.UpdateAsync(materia);

        return new UpdateMateriaResponse(true, "Materia actualizada");
    }
}

// === COMMAND: Delete (deactivate) Materia ===
public record DeleteMateriaCommand(string Id) : IRequest<DeleteMateriaResponse>;

public record DeleteMateriaResponse(bool Success, string Message);

public class DeleteMateriaHandler : IRequestHandler<DeleteMateriaCommand, DeleteMateriaResponse>
{
    private readonly IMateriaRepository _materiaRepository;

    public DeleteMateriaHandler(IMateriaRepository materiaRepository)
    {
        _materiaRepository = materiaRepository;
    }

    public async Task<DeleteMateriaResponse> Handle(DeleteMateriaCommand request, CancellationToken cancellationToken)
    {
        var materia = await _materiaRepository.GetByIdAsync(request.Id);
        if (materia == null)
            return new DeleteMateriaResponse(false, "Materia no encontrada");

        materia.IsActive = false;
        await _materiaRepository.UpdateAsync(materia);

        return new DeleteMateriaResponse(true, "Materia desactivada");
    }
}

// === QUERY: Get Available Materias (Inteligente) ===
public record GetAvailableMateriasQuery(string CarreraId) : IRequest<IEnumerable<AvailableMateriaDto>>;

public record AvailableMateriaDto(
    MateriaDto Materia,
    IEnumerable<GroupDto> GruposDisponibles
);

public class GetAvailableMateriasHandler : IRequestHandler<GetAvailableMateriasQuery, IEnumerable<AvailableMateriaDto>>
{
    private readonly IMateriaRepository _materiaRepository;
    private readonly IGroupRepository _groupRepository;
    private readonly IUserRepository _userRepository;

    public GetAvailableMateriasHandler(
        IMateriaRepository materiaRepository, 
        IGroupRepository groupRepository, 
        IUserRepository userRepository)
    {
        _materiaRepository = materiaRepository;
        _groupRepository = groupRepository;
        _userRepository = userRepository;
    }

    public async Task<IEnumerable<AvailableMateriaDto>> Handle(GetAvailableMateriasQuery request, CancellationToken cancellationToken)
    {
        // 1. Obtener todas las materias de esta carrera
        var allMaterias = await _materiaRepository.GetAllActiveAsync();
        var materiasDeCarrera = allMaterias.Where(m => m.CarreraId == request.CarreraId).ToList();

        if (!materiasDeCarrera.Any()) return Enumerable.Empty<AvailableMateriaDto>();

        // 2. Obtener los grupos que pertenecen a la carrera (o todos si la carrera está mal llenada)
        var allGroups = await _groupRepository.GetAllActiveAsync();
        // Intentamos filtrar por carrera, pero permitiendo grupos donde la carrera venga vacía o diga "DSM" genérico (legacy)
        var gruposDeCarrera = allGroups
            .Where(g => g.Carrera == request.CarreraId || string.IsNullOrEmpty(g.Carrera) || g.Carrera == "DSM" || g.Carrera == "EVN" || g.Carrera == "RIC")
            .ToList();

        // 3. Obtener todos los docentes
        var docentes = await _userRepository.GetByRoleAsync("Docente");

        var results = new List<AvailableMateriaDto>();

        // 4. Calcular grupos ocupados por materia
        foreach (var materia in materiasDeCarrera)
        {
            // Encontrar todos los grupos que YA están asignados a esta materia por CUALQUIER docente
            var gruposOcupados = new HashSet<string>();

            foreach (var docente in docentes)
            {
                if (docente.Asignaciones != null)
                {
                    var asignacion = docente.Asignaciones.FirstOrDefault(a => a.MateriaId == materia.Id && a.CarreraId == request.CarreraId);
                    if (asignacion != null && asignacion.GruposIds != null)
                    {
                        foreach (var gId in asignacion.GruposIds)
                        {
                            gruposOcupados.Add(gId);
                        }
                    }
                }
            }

            // Filtrar los grupos disponibles (los que existen en la carrera menos los ocupados)
            var gruposLibres = gruposDeCarrera.Where(g => !gruposOcupados.Contains(g.Id)).ToList();

            // Solo enviar la materia si TODAVÍA tiene grupos libres.
            // Si gruposLibres.Count == 0, significa que la materia ya está totalmente ocupada.
            if (gruposLibres.Any())
            {
                var materiaDto = new MateriaDto(
                    materia.Id,
                    materia.Nombre,
                    materia.Clave,
                    materia.Cuatrimestre,
                    materia.IsActive
                );

                var gruposDtos = gruposLibres.Select(g => new GroupDto(
                    g.Id,
                    g.Nombre,
                    g.Carrera,
                    g.Turno,
                    g.CicloActivo,
                    g.DocentesIds,
                    g.IsActive
                ));

                results.Add(new AvailableMateriaDto(materiaDto, gruposDtos));
            }
        }

        return results;
    }
}

