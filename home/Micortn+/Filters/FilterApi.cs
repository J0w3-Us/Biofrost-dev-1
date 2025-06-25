using System;
using System.Linq.Expressions;
using LinqKit;
using Micort.Domain;

namespace Micort.Domain.Filter
{
    public class NumberFilter
    {
        public int? Value { get; set; }
        public bool? IsEven { get; set; }
        public DateTime? Fecha_Registro { get; set; }

        public Expression<Func<Users, bool>> BuildFilter()
        {
            var filter = PredicateBuilder.New<Users>(true);

            if (Value.HasValue)
            {
                filter = filter.And(u => u.Id == Value.Value);
            }
            if (IsEven.HasValue)
            {
                if (IsEven.Value)
                    filter = filter.And(u => u.Id % 2 == 0);
                else
                    filter = filter.And(u => u.Id % 2 != 0);
            }
            if (Fecha_Registro.HasValue)
            {
                filter = filter.And(u => u.FechaRegistro.HasValue && u.FechaRegistro.Value.Date == Fecha_Registro.Value.Date);
            }
            return filter;
        }
    }
}