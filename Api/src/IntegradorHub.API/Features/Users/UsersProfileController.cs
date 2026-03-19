using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Features.Users.UpdateProfilePhoto;
using IntegradorHub.API.Features.Users.UpdateSocialLinks;
using IntegradorHub.API.Features.Users.GetPublicProfile;

namespace IntegradorHub.API.Features.Users;

[ApiController]
[Route("api/users")]
public class UsersProfileController : ControllerBase
{
    private readonly IMediator _mediator;

    public UsersProfileController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Gets a user's public profile data.
    /// </summary>
    [HttpGet("{userId}/profile")]
    public async Task<IActionResult> GetPublicProfile(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "User ID is required." });
        }

        try
        {
            var result = await _mediator.Send(new GetPublicProfileQuery(userId));
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting public profile: {ex.Message}");
            return StatusCode(500, new { error = "Error getting public profile." });
        }
    }

    /// <summary>
    /// Updates the user's profile photo URL.
    /// The image should already be uploaded to Supabase Storage via /api/storage/upload.
    /// </summary>
    [HttpPut("{userId}/photo")]
    public async Task<IActionResult> UpdateProfilePhoto(string userId, [FromBody] UpdatePhotoRequest request)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "User ID is required." });
        }

        if (string.IsNullOrWhiteSpace(request?.FotoUrl))
        {
            return BadRequest(new { error = "Photo URL is required." });
        }

        try
        {
            var result = await _mediator.Send(new UpdateProfilePhotoCommand(userId, request.FotoUrl));
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error updating profile photo: {ex.Message}");
            return StatusCode(500, new { error = "Error updating profile photo." });
        }
    }
    [HttpPut("{userId}/social")]
    public async Task<IActionResult> UpdateSocialLinks(string userId, [FromBody] UpdateSocialLinksRequest request)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "User ID is required." });
        }

        if (request?.RedesSociales == null)
        {
            Console.WriteLine("[DEBUG] UpdateSocialLinks: request.RedesSociales is NULL");
            return BadRequest(new { error = "RedesSociales dictionary is required." });
        }

        Console.WriteLine($"[DEBUG] UpdateSocialLinks: UserId={userId}, Links Count={request.RedesSociales.Count}");
        foreach(var kv in request.RedesSociales) {
            Console.WriteLine($"[DEBUG] Link: {kv.Key} -> {kv.Value}");
        }

        try
        {
            var result = await _mediator.Send(new UpdateSocialLinksCommand(userId, request.RedesSociales));
            return Ok(new { success = result, message = "Redes sociales actualizadas correctamente" });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error updating social links: {ex.Message}");
            return StatusCode(500, new { error = "Error updating social links." });
        }
    }
}

public record UpdatePhotoRequest(string FotoUrl);
public record UpdateSocialLinksRequest(Dictionary<string, string> RedesSociales);
