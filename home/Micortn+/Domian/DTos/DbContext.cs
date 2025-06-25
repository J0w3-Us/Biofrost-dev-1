using System.ComponentModel.DataAnnotations;
using Microsoft.Identity.Client;

namespace Micort.Domain.Dtos
{ 

    // para 
    public class NumberBto
    {
        [Required]
        public int Value { get; set; }
    }


    public class UsersLoginD
    {
        public string Names { get; set; } = string.Empty;
        public string Pasw { get; set; } = string.Empty;
    }
}
