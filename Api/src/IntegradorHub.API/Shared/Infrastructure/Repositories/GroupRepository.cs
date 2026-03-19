using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Shared.Infrastructure.Repositories;

public class GroupRepository : IGroupRepository
{
    private readonly CollectionReference _collection;

    public GroupRepository()
    {
        _collection = FirestoreContext.Groups;
    }

    public async Task<Group?> GetByIdAsync(string groupId)
    {
        var doc = await _collection.Document(groupId).GetSnapshotAsync();
        return doc.Exists ? doc.ConvertTo<Group>() : null;
    }

    public async Task<IEnumerable<Group>> GetAllActiveAsync()
    {
        var query = _collection.WhereEqualTo("is_active", true);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Group>());
    }

    public async Task<IEnumerable<Group>> GetByDocenteIdAsync(string docenteId)
    {
        var query = _collection
            .WhereArrayContains("docentes_ids", docenteId)
            .WhereEqualTo("is_active", true);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Group>());
    }

    public async Task CreateAsync(Group group)
    {
        group.CreatedAt = Timestamp.GetCurrentTimestamp();
        
        var docRef = _collection.Document();
        group.Id = docRef.Id;
        await docRef.SetAsync(group);
    }

    public async Task UpdateAsync(Group group)
    {
        await _collection.Document(group.Id).SetAsync(group, SetOptions.MergeAll);
    }
}
