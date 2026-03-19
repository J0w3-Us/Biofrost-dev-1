using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Users.UpdateProfilePhoto;

// === COMMAND ===
public record UpdateProfilePhotoCommand(
    string UserId,
    string FotoUrl
) : IRequest<UpdateProfilePhotoResponse>;

public record UpdateProfilePhotoResponse(
    string UserId,
    string FotoUrl
);

// === HANDLER ===
public class UpdateProfilePhotoHandler : IRequestHandler<UpdateProfilePhotoCommand, UpdateProfilePhotoResponse>
{
    private readonly IUserRepository _userRepository;

    public UpdateProfilePhotoHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UpdateProfilePhotoResponse> Handle(UpdateProfilePhotoCommand request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(request.UserId);
        
        if (user == null)
        {
            throw new KeyNotFoundException($"User with ID '{request.UserId}' not found.");
        }

        user.FotoUrl = request.FotoUrl;
        user.UpdatedAt = DateTime.UtcNow.ToString("o");

        await _userRepository.UpdateAsync(user);
        
        Console.WriteLine($"[PROFILE] Updated photo for user {user.Email}: {request.FotoUrl}");

        return new UpdateProfilePhotoResponse(user.Id, user.FotoUrl);
    }
}
