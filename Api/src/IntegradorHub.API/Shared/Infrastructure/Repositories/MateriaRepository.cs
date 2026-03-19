using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Shared.Infrastructure.Repositories;

public class MateriaRepository : IMateriaRepository
{
    private readonly CollectionReference _collection;

    public MateriaRepository()
    {
        _collection = FirestoreContext.Materias;
    }

    public async Task<Materia?> GetByIdAsync(string materiaId)
    {
        var doc = await _collection.Document(materiaId).GetSnapshotAsync();
        return doc.Exists ? doc.ConvertTo<Materia>() : null;
    }

    public async Task<IEnumerable<Materia>> GetAllActiveAsync()
    {
        var query = _collection.WhereEqualTo("is_active", true);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Materia>());
    }

    public async Task<IEnumerable<Materia>> GetByCuatrimestreAsync(int cuatrimestre)
    {
        var query = _collection
            .WhereEqualTo("cuatrimestre", cuatrimestre)
            .WhereEqualTo("is_active", true);
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Materia>());
    }

    public async Task CreateAsync(Materia materia)
    {
        materia.CreatedAt = Timestamp.GetCurrentTimestamp();
        
        var docRef = _collection.Document();
        materia.Id = docRef.Id;
        await docRef.SetAsync(materia);
    }

    public async Task UpdateAsync(Materia materia)
    {
        await _collection.Document(materia.Id).SetAsync(materia, SetOptions.MergeAll);
    }
}
