<<<<<<< HEAD
using System.Reflection.Metadata.Ecma335;
using Micort.Domain;
using Micort.Infrest.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Micort.Controllers.V1
{
    [ApiController]
    [Route("api/v1/[controller]")]

    public class PalindromoController : ControllerBase
    {
        private readonly MicortDbContext _context;

        public PalindromoController(MicortDbContext context)
        {
            _context = context;
        }

        [HttpGet("{id}")]
        public ActionResult GetById(int id)
        {
            var palindromo = _context.Palindromo.Find(id);
            if (palindromo == null)
                return NotFound();
            var result = $"Id = {palindromo.Id}, Texto = {palindromo.Texto}";
            return Ok(result);
        }

        [HttpPost("Palindromo")]
        public ActionResult Create([FromBody] string texto)
        {
            if (string.IsNullOrWhiteSpace(texto))
            {
                return BadRequest("El texto no puede ser nulo o vacío");
            }
            // Solo guarda el texto
            var entity = new Palindromo
            {
                Texto = texto
            };
            _context.Palindromo.Add(entity);
            _context.SaveChanges();

            // Verifica si el texto es un palíndromo
            var textCheck = new TextCheck { Texto = entity.Texto };
            var esPalindromo = textCheck.EsPalindromo();
            // Devuelve solo el resultado de si es palíndromo
            return Ok(new { esPalindromo });
        }

        [HttpDelete("{id}")]
        public ActionResult Delete(int id)
        {
            var existingItem = _context.Palindromo.Find(id);
            if (existingItem == null)
                return NotFound();

            _context.Palindromo.Remove(existingItem);
            _context.SaveChanges();

            return NoContent();
=======
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
>>>>>>> 3cb7b333036580d6db77056e6ac5438232fa4438
        }
    }
}