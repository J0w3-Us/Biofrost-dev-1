using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;
using Google.Cloud.Firestore;

namespace IntegradorHub.API.Features.Admin.Groups;

// === COMMAND: Create Group ===
public record CreateGroupCommand(
    string Nombre,
    string Turno,
    string CicloActivo,
    string DocenteId
) : IRequest<CreateGroupResponse>;

public record CreateGroupResponse(bool Success, string Message, string? GroupId);

public class CreateGroupHandler : IRequestHandler<CreateGroupCommand, CreateGroupResponse>
{
    private readonly IGroupRepository _groupRepository;

    public CreateGroupHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task<CreateGroupResponse> Handle(CreateGroupCommand request, CancellationToken cancellationToken)
    {
        var group = new Group
        {
            Nombre = request.Nombre,
            Carrera = "DSM",
            Turno = request.Turno,
            CicloActivo = request.CicloActivo,
            DocentesIds = new List<string> { request.DocenteId },
            IsActive = true
        };

        await _groupRepository.CreateAsync(group);

        return new CreateGroupResponse(true, "Grupo creado correctamente", group.Id);
    }
}

// === QUERY: Get All Groups ===
public record GetAllGroupsQuery() : IRequest<IEnumerable<GroupDto>>;

public record GroupDto(
    string Id,
    string Nombre,
    string Carrera,
    string Turno,
    string CicloActivo,
    List<string> DocentesIds,
    bool IsActive
);

public class GetAllGroupsHandler : IRequestHandler<GetAllGroupsQuery, IEnumerable<GroupDto>>
{
    private readonly IGroupRepository _groupRepository;

    public GetAllGroupsHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task<IEnumerable<GroupDto>> Handle(GetAllGroupsQuery request, CancellationToken cancellationToken)
    {
        var groups = await _groupRepository.GetAllActiveAsync();
        return groups.Select(g => new GroupDto(
            g.Id,
            g.Nombre,
            g.Carrera,
            g.Turno,
            g.CicloActivo,
            g.DocentesIds,
            g.IsActive
        ));
    }
}
