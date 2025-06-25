using Micort.Infrest.Context;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace Micort.Infrest
{
    public class TokenApiAttribute : TypeFilterAttribute
    {
        public TokenApiAttribute() : base(typeof(TokenApiFilters)) { }
    }

    public class TokenApiFilters : IAsyncActionFilter
    {
        private readonly MicortDbContext _context;

        public TokenApiFilters(MicortDbContext context)
        {
            _context = context;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var request = context.HttpContext.Request;
            var path = request.Path.Value?.ToLower();
            // Permitir acceso anónimo solo a los endpoints de generación de token y swagger
            if (path != null && (path.StartsWith("/swagger") || path.Contains("swagger") ||
                (request.Method == "POST" && (path.EndsWith("/users/token") || path.EndsWith("/users/nuevo-token")))))
            {
                await next();
                return;
            }
            if (!request.Headers.TryGetValue("Autorizacion", out var tokenHeader))
            {
                context.Result = new UnauthorizedObjectResult("Es necesario un token para tener acceso");
                return;
            }
            var token = tokenHeader.ToString().Replace("Bearer ", "").Trim();
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Token == token);
            if (user == null)
            {
                context.Result = new UnauthorizedObjectResult("Token incorrecto");
                return;
            }
            await next();
        }
    }
}