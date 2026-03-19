using System.Text.RegularExpressions;
using IntegradorHub.API.Shared.Domain.Enums;

namespace IntegradorHub.API.Shared.Domain.ValueObjects;

/// <summary>
/// Value Object que encapsula la lógica de validación de email
/// y detección automática de rol basado en el dominio.
/// </summary>
public partial class Email
{
    // Patrones de correo institucional UTM
    // Alumnos: 8 dígitos + @alumno.utmetropolitana.edu.mx
    // Docentes: @utmetropolitana.edu.mx
    // Admin: @utmetropolitana.edu.mx (pero no alumno)
    
    [GeneratedRegex(@"^\d{8}@alumno\.utmetropolitana\.edu\.mx$", RegexOptions.IgnoreCase)]
    private static partial Regex AlumnoPattern();
    
    [GeneratedRegex(@"^[a-zA-Z.]+@utmetropolitana\.edu\.mx$", RegexOptions.IgnoreCase)]
    private static partial Regex DocentePattern();
    
    // Legacy UTM patterns (opcional, o eliminar)
    [GeneratedRegex(@"^[\w\.-]+@utm\.mx$", RegexOptions.IgnoreCase)]
    private static partial Regex UtmGenericPattern();

    // Admin general (puede solaparse con docente, prioridad en lógica)
    [GeneratedRegex(@"^admin[\w\.-]*@utmetropolitana\.edu\.mx$", RegexOptions.IgnoreCase)]
    private static partial Regex AdminPattern();
    
    public string Value { get; }
    public UserRole DetectedRole { get; }
    public string? ExtractedMatricula { get; }
    
    private Email(string value, UserRole role, string? matricula = null)
    {
        Value = value;
        DetectedRole = role;
        ExtractedMatricula = matricula;
    }
    
    /// <summary>
    /// Crea un Email a partir de un string y detecta automáticamente el rol.
    /// </summary>
    public static Email From(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("El email no puede estar vacío", nameof(email));
        
        email = email.Trim().ToLowerInvariant();
        
        // Detectar si es admin (@utmetropolitana.edu.mx)
        if (AdminPattern().IsMatch(email))
        {
            return new Email(email, UserRole.SuperAdmin);
        }
        
        // Detectar si es alumno (8 dígitos)
        if (AlumnoPattern().IsMatch(email))
        {
            var matricula = email.Substring(0, 8); 
            return new Email(email, UserRole.Alumno, matricula);
        }
        
        // Detectar si es docente (nombre.apellido@utm.mx)
        if (DocentePattern().IsMatch(email))
        {
            return new Email(email, UserRole.Docente);
        }
        
        // Otros correos UTM (podrían ser docentes)
        if (UtmGenericPattern().IsMatch(email))
        {
            return new Email(email, UserRole.Docente);
        }
        
        // Correo externo = Invitado (no lanzar excepción, solo asignar rol)
        return new Email(email, UserRole.Invitado);
    }
    
    /// <summary>
    /// Valida si el email pertenece a la institución UTM.
    /// </summary>
    public bool IsInstitutional => Value.EndsWith("@utm.mx", StringComparison.OrdinalIgnoreCase);
    
    public override string ToString() => Value;
    
    public override bool Equals(object? obj) => 
        obj is Email other && Value.Equals(other.Value, StringComparison.OrdinalIgnoreCase);
    
    public override int GetHashCode() => Value.ToLowerInvariant().GetHashCode();
    
    public static implicit operator string(Email email) => email.Value;
}
