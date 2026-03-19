using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Shared.Domain.Interfaces;

public interface IProjectRepository
{
    Task<Project?> GetByIdAsync(string projectId);
    Task<IEnumerable<Project>> GetByGroupIdAsync(string groupId);
    Task<IEnumerable<Project>> GetPublicProjectsAsync(string? searchTerm = null, string? techStack = null);
    Task<IEnumerable<Project>> GetByLeaderIdAsync(string leaderId);
    Task<IEnumerable<Project>> GetByMemberIdAsync(string memberId);
    Task<IEnumerable<Project>> GetByTeacherIdAsync(string teacherId);
    Task CreateAsync(Project project);
    Task UpdateAsync(Project project);
    Task DeleteAsync(string projectId);
}
