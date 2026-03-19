using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Users.GetPublicProfile;

public class GetPublicProfileHandler : IRequestHandler<GetPublicProfileQuery, PublicProfileDto>
{
    private readonly IUserRepository _userRepository;

    public GetPublicProfileHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<PublicProfileDto> Handle(GetPublicProfileQuery request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(request.UserId);

        if (user == null)
        {
            throw new KeyNotFoundException($"User with ID {request.UserId} not found.");
        }

        return new PublicProfileDto(
            Id: user.Id,
            Email: user.Email,
            Nombre: user.Nombre,
            ApellidoPaterno: user.ApellidoPaterno,
            ApellidoMaterno: user.ApellidoMaterno,
            FotoUrl: user.FotoUrl,
            Rol: user.Rol,
            Matricula: user.Matricula,
            GrupoId: user.GrupoId,
            CarreraId: user.CarreraId,
            Profesion: user.Profesion,
            EspecialidadDocente: user.EspecialidadDocente,
            Organizacion: user.Organizacion,
            CreatedAt: user.GetCreatedAtAsString(),
            RedesSociales: user.RedesSociales
        );
    }
}
