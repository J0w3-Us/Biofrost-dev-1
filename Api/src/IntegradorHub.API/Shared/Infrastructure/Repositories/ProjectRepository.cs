using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Enums;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Shared.Infrastructure.Repositories;

public class ProjectRepository : IProjectRepository
{
    private readonly CollectionReference _collection;

    public ProjectRepository()
    {
        _collection = FirestoreContext.Projects;
    }

    public async Task<Project?> GetByIdAsync(string projectId)
    {
        var snapshot = await _collection.Document(projectId).GetSnapshotAsync();
        return snapshot.Exists ? snapshot.ConvertTo<Project>() : null;
    }

    public async Task<IEnumerable<Project>> GetByGroupIdAsync(string groupId)
    {
        var query = _collection.WhereEqualTo("grupo_id", groupId);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Project>());
    }

    public async Task<IEnumerable<Project>> GetPublicProjectsAsync(string? searchTerm = null, string? techStack = null)
    {
        var query = _collection.WhereEqualTo("es_publico", true);
        var snapshot = await query.GetSnapshotAsync();
        var projects = snapshot.Documents.Select(d => d.ConvertTo<Project>());

        // Filtrar en memoria (Firestore no soporta búsqueda de texto completo)
        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.ToLowerInvariant();
            projects = projects.Where(p => 
                p.Titulo.ToLowerInvariant().Contains(term) ||
                p.Materia.ToLowerInvariant().Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(techStack))
        {
            projects = projects.Where(p => 
                p.StackTecnologico.Any(s => 
                    s.Equals(techStack, StringComparison.OrdinalIgnoreCase)));
        }

        return projects;
    }

    public async Task<IEnumerable<Project>> GetByLeaderIdAsync(string leaderId)
    {
        var query = _collection.WhereEqualTo("lider_id", leaderId);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Project>());
    }

    public async Task<IEnumerable<Project>> GetByMemberIdAsync(string memberId)
    {
        var query = _collection.WhereArrayContains("miembros_ids", memberId);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Project>());
    }

    public async Task<IEnumerable<Project>> GetByTeacherIdAsync(string teacherId)
    {
        var query = _collection.WhereEqualTo("docente_id", teacherId);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => {
            var p = d.ConvertTo<Project>();
            p.Id = d.Id;
            return p;
        });
    }

    public async Task CreateAsync(Project project)
    {
        project.Id = string.IsNullOrEmpty(project.Id) 
            ? _collection.Document().Id 
            : project.Id;
        project.CreatedAt = Timestamp.GetCurrentTimestamp();
        project.UpdatedAt = Timestamp.GetCurrentTimestamp();
        await _collection.Document(project.Id).SetAsync(project);
    }

    public async Task UpdateAsync(Project project)
    {
        project.UpdatedAt = Timestamp.GetCurrentTimestamp();
        await _collection.Document(project.Id).SetAsync(project, SetOptions.MergeAll);
    }

    public async Task DeleteAsync(string projectId)
    {
        await _collection.Document(projectId).DeleteAsync();
    }
}
