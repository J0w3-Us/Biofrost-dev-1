using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Shared.Infrastructure.Repositories;

public class CarreraRepository : ICarreraRepository
{
    private readonly CollectionReference _collection;

    public CarreraRepository()
    {
        _collection = FirestoreContext.GetDatabase().Collection("carreras");
    }

    public async Task<List<Carrera>> GetAllAsync()
    {
        var snapshot = await _collection.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Carrera>()).ToList();
    }

    public async Task<Carrera?> GetByIdAsync(string id)
    {
        var doc = await _collection.Document(id).GetSnapshotAsync();
        return doc.Exists ? doc.ConvertTo<Carrera>() : null;
    }

    public async Task<string> CreateAsync(Carrera carrera)
    {
        var docRef = _collection.Document(); 
        carrera.Id = docRef.Id;
        await docRef.SetAsync(carrera);
        return carrera.Id;
    }

    public async Task DeleteAsync(string id)
    {
        await _collection.Document(id).DeleteAsync();
    }
}
