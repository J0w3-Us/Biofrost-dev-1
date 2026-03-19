using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Users.UpdateSocialLinks;

// === COMMAND ===
public record UpdateSocialLinksCommand(string UserId, Dictionary<string, string> RedesSociales) : IRequest<bool>;

// === HANDLER ===
public class UpdateSocialLinksHandler : IRequestHandler<UpdateSocialLinksCommand, bool>
{
    private readonly IUserRepository _userRepository;

    public UpdateSocialLinksHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<bool> Handle(UpdateSocialLinksCommand request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(request.UserId);

        if (user == null)
        {
            throw new KeyNotFoundException($"Usuario con ID {request.UserId} no encontrado.");
        }

        await _userRepository.UpdateSocialLinksAsync(user.Id, request.RedesSociales);

        return true;
    }
}
