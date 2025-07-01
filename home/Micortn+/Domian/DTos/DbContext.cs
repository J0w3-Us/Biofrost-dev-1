using System.ComponentModel.DataAnnotations;
using Microsoft.Identity.Client;

// guarda los datos de entrada y salida de los servicios

namespace Micort.Domain.Dtos
{

    // para 
    public class NumberBto
    {
        [Required]
        public int Value { get; set; }
    }

    public class EncripResponseDto
    {
        [Required]
        public int Id { get; set; }
        public string TextFinal { get; set; } = string.Empty;

    }

    public class RespuestaDesencrip
    {
        [Required]
        public int IdDesCrip { get; set; }
        public string DescFinal { get; set; } = string.Empty;

        public bool DescSuccess { get; set; }
    }

    public class Palindromo
    {
        [Required]
        public string Texto { get; set; } = string.Empty;
        public bool EsPalindromo { get; set; }
    }
    public class UsersLoginD
    {
        public string Names { get; set; } = string.Empty;
        public string Pasw { get; set; } = string.Empty;
    }
}
