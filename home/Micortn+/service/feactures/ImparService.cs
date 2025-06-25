using Micort.Domain.Entities;
using System.Collections.Generic;
using System.Linq;

namespace numberOperacion.Services.EvenOddApp.Services
{
    public class NumberServices
    {
        public NumberServices() {}

        public bool Isvalid(int number)
        {
            return number % 2 == 0;
        }

        public bool IsRech(int number)
        {
            return !Isvalid(number);
        }
    }
}