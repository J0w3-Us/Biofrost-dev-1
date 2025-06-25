using Micort.Domain;
using Micort.Infrest.Context;
using Microsoft.AspNetCore.Mvc;
using System.Security.Cryptography;
using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Micort.Domain.Dtos;
using Micort.Infrest;

namespace Micort.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly MicortDbContext _context;
        public UsersController(MicortDbContext context)
        {
            _context = context;
        }

        // Todos los endpoints de Users eliminados
    }
}
