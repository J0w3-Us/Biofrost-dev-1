using javeragesLibrery.Domian.Entities;
using System.Collections.Generic;
using System.Linq;

namespace numberOperacion.Services.EvenOddApp.Services
{
    public class NumberServices
    {
        private int _number;

        public NumberServices()
        {
            _number = 0;
        }

        public bool Isvalid(int _number)
        {
            return _number % 2 == 0;
        }

        public bool IsRech(int _number)
        {
            return !Isvalid( _number);
        }
    }
}