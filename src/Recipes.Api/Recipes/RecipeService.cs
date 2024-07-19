
using Microsoft.EntityFrameworkCore;

namespace Recipes.Api.Recipes
{
    public class RecipeService : IRecipeService
    {
        private readonly RecipesDbContext _db;
        private readonly ILogger<IRecipeService> _logger;

        public RecipeService(RecipesDbContext db, ILogger<RecipeService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<IEnumerable<RecipeResponse>> GetRecipes(string userId)
        {
            var recipes = await _db.Recipes
                .Where(r => r.OwnerId == userId)
                .Select(r => new RecipeResponse(r.Id, r.Name, r.Description))
                .ToListAsync();

            _logger.LogInformation("{Amount} recipes found for user with {Id}.", recipes.Count, userId);

            return recipes;
        }
    }
}
