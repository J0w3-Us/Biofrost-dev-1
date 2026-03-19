using Microsoft.AspNetCore.Mvc;

namespace IntegradorHub.API.Features.Admin;

[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    // =====================
    // ADMIN SEED (TEMPORAL)
    // =====================
    
    /// <summary>
    /// Crea el usuario admin inicial en Firestore.
    /// SOLO usar una vez para setup inicial.
    /// </summary>
    [HttpPost("seed-admin")]
    public async Task<ActionResult> SeedAdmin([FromBody] SeedAdminRequest request)
    {
        try
        {
            var userRef = Shared.Infrastructure.FirestoreContext.Users.Document(request.Uid);
            await userRef.SetAsync(new Dictionary<string, object>
            {
                { "email", request.Email },
                { "nombre", "Admin" },
                { "rol", "admin" },
                { "is_first_login", false },
                { "created_at", DateTime.UtcNow.ToString("o") }
            }, Google.Cloud.Firestore.SetOptions.MergeAll);
            
            return Ok(new { message = "Admin creado exitosamente", uid = request.Uid });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }
}

// =====================
// REQUEST DTOs
// =====================

public record SeedAdminRequest(
    string Uid,
    string Email
);
