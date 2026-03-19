using Google.Cloud.Firestore;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Shared.Infrastructure.Repositories;

public class EvaluationRepository : IEvaluationRepository
{
    private readonly CollectionReference _collection;

    public EvaluationRepository()
    {
        _collection = FirestoreContext.Evaluations;
    }

    public async Task<Evaluation?> GetByIdAsync(string evaluationId)
    {
        var doc = await _collection.Document(evaluationId).GetSnapshotAsync();
        return doc.Exists ? doc.ConvertTo<Evaluation>() : null;
    }

    public async Task<IEnumerable<Evaluation>> GetByProjectIdAsync(string projectId)
    {
        var query = _collection
            .WhereEqualTo("project_id", projectId);
            //.OrderByDescending("created_at"); // Temporarily removed to bypass index requirement
        
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Evaluation>());
    }

    public async Task<IEnumerable<Evaluation>> GetByDocenteIdAsync(string docenteId)
    {
        var query = _collection
            .WhereEqualTo("docente_id", docenteId);
            //.OrderByDescending("created_at");
        
        var snapshot = await query.GetSnapshotAsync();
        return snapshot.Documents.Select(d => d.ConvertTo<Evaluation>());
    }

    public async Task CreateAsync(Evaluation evaluation)
    {
        evaluation.CreatedAt = Timestamp.GetCurrentTimestamp();
        evaluation.UpdatedAt = evaluation.CreatedAt;
        
        var docRef = _collection.Document();
        evaluation.Id = docRef.Id;
        await docRef.SetAsync(evaluation);
    }

    public async Task UpdateAsync(Evaluation evaluation)
    {
        evaluation.UpdatedAt = Timestamp.GetCurrentTimestamp();
        await _collection.Document(evaluation.Id).SetAsync(evaluation, SetOptions.MergeAll);
    }

    public async Task DeleteAsync(string evaluationId)
    {
        await _collection.Document(evaluationId).DeleteAsync();
    }
}
