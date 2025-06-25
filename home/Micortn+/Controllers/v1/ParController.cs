using Micort.Domain.Entities;
using numberOperacion.Services.EvenOddApp.Services;
using Microsoft.AspNetCore.Mvc;
using Micort.Infrest.Context;

namespace Micort.Controllers.V1
{
    [ApiController]
    [Route("api/v1/[controller]")]

    public class NumberController : ControllerBase
    {
    private readonly NumberServices _numberServices;
    private readonly MicortDbContext _context;

    public NumberController(NumberServices numberServices, MicortDbContext context)
    {
        _numberServices = numberServices;
        _context = context;
    }

    [HttpGet("{number:int}/ispar")]
    public IActionResult EsPar([FromRoute] int number)
    {
        bool esPar = _numberServices.Isvalid(number);
        var registro = new ParImpar
        {
            Valor = number,
            Es_Par = esPar,
            Es_Impar = !esPar
        };
        _context.ParImpar.Add(registro);
        _context.SaveChanges();
        return Ok(new { number = number, esPar = esPar });
    }

    [HttpGet("{number:int}/isimpar")]
    public IActionResult EsImpar([FromRoute] int number)
    {
        bool esImpar = _numberServices.IsRech(number);
        var registro = new ParImpar
        {
            Valor = number,
            Es_Par = !esImpar,
            Es_Impar = esImpar
        };
        _context.ParImpar.Add(registro);
        _context.SaveChanges();
        return Ok(new { number = number, esImpar = esImpar });
    }
    }    
}