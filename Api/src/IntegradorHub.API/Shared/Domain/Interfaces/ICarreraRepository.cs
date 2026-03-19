using IntegradorHub.API.Shared.Domain.Entities;

namespace IntegradorHub.API.Shared.Domain.Interfaces;

public interface ICarreraRepository
{
    Task<List<Carrera>> GetAllAsync();
    Task<Carrera?> GetByIdAsync(string id);
    Task<string> CreateAsync(Carrera carrera);
    Task DeleteAsync(string id);
}
