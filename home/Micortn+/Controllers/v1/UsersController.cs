using Micort.Domain;
using Micort.Infrest.Context;
using Microsoft.AspNetCore.Mvc;
using System.Security.Cryptography;
using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Micort.Domain.Dtos;

namespace Micort.Controllers.V1
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly MicortDbContext _context;
        public UsersController(MicortDbContext context)
        {
            _context = context;
        }

        [HttpPost("token")]
        public async Task<IActionResult> GenerarToken([FromBody] UsersLoginD users)
        {
            var token = GenerarTokenString();
            var newUser = new Users
            {
                Names = users.Names,
                Pasw = users.Pasw,
                Token = token
            };
            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();
            return Ok(new { token });
        }

        [HttpPost("nuevo-token")]
        public async Task<IActionResult> GenerarNuevoToken([FromBody] UsersLoginD users)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Names == users.Names && u.Pasw == users.Pasw);
            if (user == null)
                return Unauthorized("Users o Pasw incorrectos.");
            user.Token = GenerarTokenString();
            await _context.SaveChangesAsync();
            return Ok(new { token = user.Token });
        }

        private string GenerarTokenString()
        {
            var bytes = new byte[32];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(bytes);
            return Convert.ToBase64String(bytes);
        }
    }
}
// El controlador UsersController en v1 es redundante y debe eliminarse para evitar duplicados.