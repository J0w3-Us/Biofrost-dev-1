namespace javeragesLibrery.Domian.Entities
{
    public class NumberCheck
    {
        public int Number { get; set; }

        public NumberCheck()
        {
            Number = 0;
        }

        public bool Isvalid()
        {
            return Number % 2 == 0;
        }

        public bool IsRech()
        {
            return !Isvalid();
        }
    }
}