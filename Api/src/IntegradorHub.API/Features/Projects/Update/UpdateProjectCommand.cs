using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Features.Projects.Update;

public record UpdateProjectCommand(
    string ProjectId,
    string Titulo,
    string? VideoUrl,
    List<CanvasBlock> CanvasBlocks,
    bool? EsPublico,
    string RequestingUserId
) : IRequest<UpdateProjectResponse>;

public record UpdateProjectResponse(bool Success, string Message);
