using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Micort.Domain
{
    public class Users
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Names { get; set; } = string.Empty;
        [Required]
        [MaxLength(100)]
        public string Pasw { get; set; } = string.Empty;
        [MaxLength(100)]
        public string? Token { get; set; }
        [MaxLength(100)]
        public string? Email { get; set; }
        public DateTime? FechaRegistro { get; set; }
        [MaxLength(100)]
        public string? Inicio_de_secion { get; set; }
    }
}