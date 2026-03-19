using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Shared.Domain.Entities;
using Google.Cloud.Firestore;
using System.Text.Json;

namespace IntegradorHub.API.Features.Projects.Update;

public class UpdateProjectHandler : IRequestHandler<UpdateProjectCommand, UpdateProjectResponse>
{
    private readonly IProjectRepository _repository;

    public UpdateProjectHandler(IProjectRepository repository)
    {
        _repository = repository;
    }

    public async Task<UpdateProjectResponse> Handle(UpdateProjectCommand request, CancellationToken cancellationToken)
    {
        var project = await _repository.GetByIdAsync(request.ProjectId);
        if (project == null)
            throw new KeyNotFoundException("Proyecto no encontrado");

        project.Titulo = request.Titulo;
        project.VideoUrl = request.VideoUrl;
        project.CanvasBlocks = SanitizeBlocks(request.CanvasBlocks);

        if (request.EsPublico.HasValue)
            project.EsPublico = request.EsPublico.Value;

        project.UpdatedAt = Timestamp.FromDateTime(DateTime.UtcNow);
        await _repository.UpdateAsync(project);

        return new UpdateProjectResponse(true, "Proyecto actualizado correctamente");
    }

    private List<CanvasBlock> SanitizeBlocks(List<CanvasBlock> blocks)
    {
        if (blocks == null) return new List<CanvasBlock>();

        foreach (var block in blocks)
        {
            if (block.Metadata != null && block.Metadata.Count > 0)
            {
                block.Metadata = FlattenMetadata(block.Metadata);
            }
        }
        return blocks;
    }

    // Converts metadata so it can be saved to Firestore.
    // Firestore does NOT support arrays-of-arrays (e.g. table rows = string[][]).
    // Fix: serialize any nested objects/arrays that are themselves complex 
    // (like 'table') into a JSON string. Simple primitives are kept as-is.
    private Dictionary<string, object> FlattenMetadata(Dictionary<string, object> metadata)
    {
        var result = new Dictionary<string, object>();

        foreach (var kvp in metadata)
        {
            if (kvp.Value is JsonElement element)
            {
                switch (element.ValueKind)
                {
                    case JsonValueKind.String:
                        result[kvp.Key] = element.GetString() ?? string.Empty;
                        break;
                    case JsonValueKind.Number:
                        if (element.TryGetInt64(out long l)) result[kvp.Key] = l;
                        else if (element.TryGetDouble(out double d)) result[kvp.Key] = d;
                        else result[kvp.Key] = 0L;
                        break;
                    case JsonValueKind.True:
                        result[kvp.Key] = true;
                        break;
                    case JsonValueKind.False:
                        result[kvp.Key] = false;
                        break;
                    case JsonValueKind.Null:
                    case JsonValueKind.Undefined:
                        // skip nulls — Firestore fields must not be null in a map
                        break;
                    case JsonValueKind.Object:
                    case JsonValueKind.Array:
                        // Firestore does not support nested arrays (arrays of arrays).
                        // Serialize complex nested structures as a JSON string so they
                        // round-trip safely. The frontend already handles this via getTableData.
                        result[kvp.Key] = element.GetRawText();
                        break;
                }
            }
            else if (kvp.Value != null)
            {
                // Already a native type (bool, long, string) — pass through
                result[kvp.Key] = kvp.Value;
            }
        }

        return result;
    }
}
