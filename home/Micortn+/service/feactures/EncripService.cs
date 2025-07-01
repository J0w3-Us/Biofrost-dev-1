using Azure.Core;
using Micort.Domain;
using System.Text;
namespace Micort.service.feactures;

public class EncryptionService
{
    public Respuesta Encrip(Encrip request)
    {
        var textFinal = Convert.ToBase64String(Encoding.UTF8.GetBytes(request.TextOrigin ?? string.Empty));
        var encrip = new Respuesta
        {
            TextOrigin = request.TextOrigin ?? string.Empty,
            textFinal = textFinal,
            succes = true
        };
        return encrip;
    }

    public RespuestaDesencrip DesenCrip(DesenCrip request)
    {
        var DescOrigin = Convert.ToBase64String(Encoding.UTF8.GetBytes(request.DescOrigin ?? string.Empty));
        var desencrip = new RespuestaDesencrip
        {
            DescOrigin = request.DescOrigin ?? string.Empty,
            DescFinal = DescOrigin,
            DescSuccess = true
        };
        return desencrip;
    }
}
