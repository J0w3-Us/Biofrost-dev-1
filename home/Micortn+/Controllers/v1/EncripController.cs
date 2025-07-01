using Micort.service.feactures;
using Micort.Domain;
using Micort.Infrest.Context;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Micort.Domain.Dtos;

namespace Micort.Controllers.V1
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class EncripController : ControllerBase
    {
        private readonly MicortDbContext _context;
        private readonly EncryptionService _encripService;

        public EncripController(MicortDbContext context, EncryptionService encripService)
        {
            _context = context;
            _encripService = encripService;
        }


        // GET: api/v1/Encrip/5
        [HttpGet("{id}")]
        public ActionResult GetById(int id)
        {
            var encrip = _context.Encrip.Find(id);
            if (encrip == null) return NotFound();
            var textFinal = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(encrip.TextOrigin ?? string.Empty));
            var result = $"Id = {encrip.Id}, TextOrigin = {encrip.TextOrigin}, TextFinal = {textFinal}";
            return Ok(result);
        }

        // POST: api/v1/Encrip/Encrypt
        [HttpPost("Encrypt")]
        [ProducesResponseType(typeof(EncripResponseDto), 200)]
        public ActionResult<EncripResponseDto> Encrip([FromBody] string textOrigin)
        {
            if (string.IsNullOrWhiteSpace(textOrigin))
            {
                return BadRequest("El texto no puede ser nulo o vacío");
            }
            // Guarda solo el texto original
            var entity = new Encrip
            {
                TextOrigin = textOrigin
            };
            _context.Encrip.Add(entity);
            _context.SaveChanges();

            // Calcula el texto final (encriptado)
            var textFinal = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(textOrigin));

            // Devuelve solo el id y el texto final
            return Ok(new EncripResponseDto
            {
                Id = entity.Id,
                TextFinal = textFinal
            });
        }
        // DELETE: api/v1/Encrip/5
        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var entity = _context.Encrip.Find(id);
            if (entity == null) return NotFound();

            _context.Encrip.Remove(entity);
            _context.SaveChanges();
            return NoContent();
        }
        
        // POST: api/v1/Encrip/Decrypt
        [HttpPost("Decrypt")]
        [ProducesResponseType(typeof(string), 200)]
        public ActionResult<string> Decrypt([FromBody] string textFinal)
        {
            if (string.IsNullOrWhiteSpace(textFinal))
            {
                return BadRequest("El texto no puede ser nulo o vacío");
            }
        
            try
            {
                var bytes = Convert.FromBase64String(textFinal);
                var textOrigin = System.Text.Encoding.UTF8.GetString(bytes);
                return Ok(textOrigin);
            }
            catch
            {
                return BadRequest("El texto proporcionado no es un Base64 válido.");
            }
        }
    }
}