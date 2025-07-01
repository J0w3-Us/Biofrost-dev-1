using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Micort.Domain.Entities
{
    public class NumberCheck
    {
        public int Number { get; set; }

        public NumberCheck()
        {
            Number = 0;
        }

        public bool Isvalid()
        {
            return Number % 2 == 0;
        }

        public bool IsRech()
        {
            return !Isvalid();
        }
    }

    [Table("Numeros")]
    public class ParImpar
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
        [Required]
        [RegularExpression("^[0-9]+$", ErrorMessage = "Solo se permiten números enteros positivos, sin letras, símbolos ni espacios.")]
        public int Valor { get; set; }
        public bool Es_Par { get; set; }
        public bool Es_Impar { get; set; }
    }
}