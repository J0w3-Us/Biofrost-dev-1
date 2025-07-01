using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Azure.Core;

namespace Micort.Domain
{

    public class TextCheck
    {
        public string Texto { get; set; } = string.Empty;

        public TextCheck()
        {
            Texto = string.Empty;
        }

        public bool EsPalindromo()
        {
            if (string.IsNullOrWhiteSpace(Texto))
                return false;
            if (!Texto.All(char.IsLetter))
                return false;

            var textoLimpio = new string(Texto
            .Where(char.IsLetterOrDigit)
            .Select(char.ToLower)
            .ToArray());

            return textoLimpio.SequenceEqual(textoLimpio.Reverse());
        }
    }

    [Table("Palindromo")]
    public class Palindromo
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        [RegularExpression("^[a-zA-Z]+$", ErrorMessage = "Solo se permiten letras sin espacios, números ni símbolos.")]
        public string Texto { get; set; } = string.Empty;
    }
}