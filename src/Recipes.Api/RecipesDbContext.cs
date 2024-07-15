using Microsoft.EntityFrameworkCore;
using Recipes.Api.Recipes;
using Recipes.Api.User;

namespace Recipes.Api
{
    public class RecipesDbContext : DbContext
    {
        public RecipesDbContext(DbContextOptions<RecipesDbContext> options)
            : base(options) { }

        public DbSet<UserEntity> Users { get; set; }
        public DbSet<RecipeEntity> Recipes { get; set; }
    }
}