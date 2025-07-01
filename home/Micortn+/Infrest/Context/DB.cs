using Microsoft.EntityFrameworkCore;
using Micort.Domain;
using Micort.Domain.Entities;

namespace Micort.Infrest.Context
{
    public class MicortDbContext : DbContext
    {
        public MicortDbContext(DbContextOptions<MicortDbContext> options) : base(options) { }
        public DbSet<Users> Users { get; set; }
        public DbSet<ParImpar> ParImpar { get; set; }

        public DbSet<Encrip> Encrip { get; set; }

        public DbSet<DesenCrip> DesenCrips { get; set; }

        public DbSet<Palindromo> Palindromo { get; set; }
    }
}