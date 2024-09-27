using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ValueGeneration;
using Recipes.Api.Recipes;
using Recipes.Api.Users;

namespace Recipes.Api
{
    public class RecipesDbContext : DbContext
    {
        public RecipesDbContext(DbContextOptions<RecipesDbContext> options)
            : base(options) { }

        public DbSet<UserEntity> Users { get; set; }
        public DbSet<Recipe> Recipes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Recipe>().ToContainer("Recipes");
            modelBuilder.Entity<Recipe>().Property(b => b.Id).HasValueGenerator<GuidValueGenerator>();
        }
    }
}