using javeragesLibrery.Domian.Entities;
using numberOperacion.Services.EvenOddApp.Services;
using Microsoft.AspNetCore.Mvc;

namespace numberOperacion.Controllers.V1
{
    [ApiController]
    [Route("api/v1/[controller]")]

    public class NumberController : ControllerBase
    {
    private readonly NumberServices _numberServices;

    public NumberController(NumberServices numberServices)
    {
        _numberServices = numberServices;
    }

    [HttpGet("{number:int}/Isvalid")]
    public IActionResult CheckIfValid([FromRoute] int number)
    {
        bool Isvalid = _numberServices.Isvalid(number);

        return Ok(new { number = number, Isvalid = Isvalid });
    }

    [HttpGet("{number:int}/IsReach")]
    public IActionResult CheckedIfReach([FromRoute] int number)
    {
        bool isReach = _numberServices.IsRech(number);

        return Ok(new { number = number, isReach = isReach });
    }
    }    
}