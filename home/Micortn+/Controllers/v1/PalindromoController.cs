using Microsoft.AspNetCore.Mvc;
using MiWebApi.Models;

namespace MiWebApi.Controllers
{
    [ApiController]
    [Route("[Controller]")]
    public class PalindromoController : ControllerBase
    {
        [HttpPost]
        public IActionResult Verificar([FromBody] PalindromoRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Texto))
            {
                return BadRequest(new { mensaje = "El texto es requerido." });
            }

            bool esPalindromo = EsPalindromo(request.Texto);

            return Ok(new PalindromoResponse
            {
                EsPalindromo = esPalindromo
            });
        }

        private bool EsPalindromo(string texto)
        {
            // Limpiar el texto
            string limpio = "";
            foreach (char c in texto.ToLower())
            {
                if (char.IsLetterOrDigit(c))
                {
                    limpio += c;
                }
            }

            // Comparar desde ambos extremos
            int izquierda = 0;
            int derecha = limpio.Length - 1;

            while (izquierda < derecha)
            {
                if (limpio[izquierda] != limpio[derecha])
                {
                    return false;
                }
                izquierda++;
                derecha--;
            }

            return true;
        }
    }
}