using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Shared.Domain.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(string userId);
    Task<User?> GetByEmailAsync(string email);
    Task<IEnumerable<User>> GetByGroupIdAsync(string groupId);
    Task<IEnumerable<User>> SearchByNameAsync(string searchTerm, string groupId);
    Task CreateAsync(User user);
    Task CreateIfNotExistsAsync(User user);
    Task UpdateAsync(User user);
    
    // User Management
    Task<IEnumerable<User>> GetByRoleAsync(string role);
    Task<IEnumerable<User>> GetStudentsByGroupAsync(string grupoId);
    Task<IEnumerable<User>> GetTeachersByGroupAsync(string grupoId, string? carreraId = null);
    Task UpdateSocialLinksAsync(string userId, Dictionary<string, string> redesSociales);
}
