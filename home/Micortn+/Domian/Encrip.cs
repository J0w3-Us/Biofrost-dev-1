using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Micort.Domain;

public class Encrip
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [MaxLength(250)]
    [RegularExpression("^[a-zA-Z]+$", ErrorMessage = "Solo se permiten letras (sin números ni símbolos) al ingresar.")]
    public string TextOrigin { get; set; } = string.Empty;

}
[Table("Encrip")]
public class Respuesta
{
    [Key]
    public int Id { get; set; }
    [MaxLength(250)]
    public string TextOrigin { get; set; } = string.Empty;
    [MaxLength(300)]
    public string textFinal { get; set; } = string.Empty;

    public bool succes { get; set; }
}

public class DesenCrip
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    [MaxLength(250)]
    public string DescOrigin { get; set; } = string.Empty;
    [MaxLength(300)]
    public string DescFinal { get; set; } = string.Empty;

    public bool DescSuccess { get; set; }
}

[Table("DesenCrip")]
public class RespuestaDesencrip
{
    [Key]
    public int IdDesCrip { get; set; }
    [MaxLength(250)]
    public string DescOrigin { get; set; } = string.Empty;
    [MaxLength(300)]
    public string DescFinal { get; set; } = string.Empty;

    public bool DescSuccess { get; set; }
}