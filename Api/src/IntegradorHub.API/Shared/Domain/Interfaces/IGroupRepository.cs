using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Shared.Domain.Interfaces;

public interface IGroupRepository
{
    Task<Group?> GetByIdAsync(string groupId);
    Task<IEnumerable<Group>> GetAllActiveAsync();
    Task<IEnumerable<Group>> GetByDocenteIdAsync(string docenteId);
    Task CreateAsync(Group group);
    Task UpdateAsync(Group group);
}

public interface IMateriaRepository
{
    Task<Materia?> GetByIdAsync(string materiaId);
    Task<IEnumerable<Materia>> GetAllActiveAsync();
    Task<IEnumerable<Materia>> GetByCuatrimestreAsync(int cuatrimestre);
    Task CreateAsync(Materia materia);
    Task UpdateAsync(Materia materia);
}

public interface IEvaluationRepository
{
    Task<Evaluation?> GetByIdAsync(string evaluationId);
    Task<IEnumerable<Evaluation>> GetByProjectIdAsync(string projectId);
    Task<IEnumerable<Evaluation>> GetByDocenteIdAsync(string docenteId);
    Task CreateAsync(Evaluation evaluation);
    Task UpdateAsync(Evaluation evaluation);
    Task DeleteAsync(string evaluationId);
}
