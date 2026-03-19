using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Shared.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly CollectionReference _collection;

    public UserRepository()
    {
        _collection = FirestoreContext.Users;
    }

    public async Task<User?> GetByIdAsync(string userId)
    {
        var snapshot = await _collection.Document(userId).GetSnapshotAsync();
        return snapshot.Exists ? snapshot.ConvertTo<User>() : null;
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        var query = _collection.WhereEqualTo("email", email.ToLowerInvariant());
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.FirstOrDefault()?.ConvertTo<User>();
    }

    public async Task<IEnumerable<User>> GetByGroupIdAsync(string groupId)
    {
        var query = _collection.WhereEqualTo("grupo_id", groupId);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<User>());
    }

    public async Task<IEnumerable<User>> SearchByNameAsync(string searchTerm, string groupId)
    {
        // Firestore no soporta búsqueda de texto completo nativa
        // Obtenemos usuarios del grupo y filtramos en memoria
        var users = await GetByGroupIdAsync(groupId);
        var term = searchTerm.ToLowerInvariant();
        
        return users.Where(u => 
            u.Nombre.ToLowerInvariant().Contains(term) ||
            (u.Matricula?.ToLowerInvariant().Contains(term) ?? false));
    }

    public async Task CreateAsync(User user)
    {
        user.CreatedAt = DateTime.UtcNow.ToString("o");
        user.UpdatedAt = DateTime.UtcNow.ToString("o");
        await _collection.Document(user.Id).SetAsync(user);
    }

    public async Task CreateIfNotExistsAsync(User user)
    {
        user.CreatedAt = DateTime.UtcNow.ToString("o");
        user.UpdatedAt = DateTime.UtcNow.ToString("o");
        try 
        {
            await _collection.Document(user.Id).CreateAsync(user);
        }
        catch (Grpc.Core.RpcException ex) when (ex.StatusCode == Grpc.Core.StatusCode.AlreadyExists)
        {
            Console.WriteLine($"[DEBUG] UserRepository: User {user.Id} already exists, skipping creation to avoid race condition overwrite.");
        }
    }

    public async Task UpdateAsync(User user)
    {
        user.UpdatedAt = DateTime.UtcNow.ToString("o");
        await _collection.Document(user.Id).SetAsync(user, SetOptions.MergeAll);
    }

    // User Management Methods
    public async Task<IEnumerable<User>> GetByRoleAsync(string role)
    {
        var query = _collection.WhereEqualTo("rol", role);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<User>());
    }

    public async Task<IEnumerable<User>> GetStudentsByGroupAsync(string grupoId)
    {
        var query = _collection
            .WhereEqualTo("rol", "Alumno")
            .WhereEqualTo("grupo_id", grupoId);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<User>());
    }

    public async Task<IEnumerable<User>> GetTeachersByGroupAsync(string grupoId, string? carreraId = null)
    {
        // Obtener todos los docentes
        var teachers = await GetByRoleAsync("Docente");
        
        // Filtrar docentes que tienen asignaciones con ese grupoId
        return teachers.Where(t => 
            t.Asignaciones?.Any(a => 
                a.GruposIds.Contains(grupoId) && 
                (carreraId == null || a.CarreraId == carreraId)
            ) ?? false
        );
    }

    public async Task UpdateSocialLinksAsync(string userId, Dictionary<string, string> redesSociales)
    {
        var timestamp = DateTime.UtcNow.ToString("o");
        var updates = new Dictionary<string, object>
        {
            { "redes_sociales", redesSociales },
            { "updated_at", timestamp }
        };
        await _collection.Document(userId).UpdateAsync(updates);
    }
}
