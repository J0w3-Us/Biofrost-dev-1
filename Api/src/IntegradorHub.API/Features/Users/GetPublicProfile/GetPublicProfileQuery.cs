using MediatR;

namespace IntegradorHub.API.Features.Users.GetPublicProfile;

public record GetPublicProfileQuery(string UserId) : IRequest<PublicProfileDto>;
