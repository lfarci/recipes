
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

        public async Task<IEnumerable<RecipeResponse>> GetRecipes(string userId, int pageIndex = 1, int pageSize = 10)
        {
            int skip = (pageIndex - 1) * pageSize;

            _logger.LogInformation("Fetching recipes page {PageIndex} (Size of {PageSize}) for user with ID of {UserId}.", pageIndex, pageSize, userId);

            var recipes = await _db.Recipes
                .Where(r => r.OwnerId == userId)
                .Select(r => new RecipeResponse(r.Id.ToString() ?? string.Empty, r.Name, r.Description))
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();

            _logger.LogInformation("Fetched {Count} recipes for page {PageIndex} (Size of {PageSize}) for user with ID of {UserId}.", recipes.Count, pageIndex, pageSize, userId);

            return recipes;
        }

        public async Task<RecipeResponse?> GetRecipe(string userId, string recipeId)
        {
            var entity = await GetRecipeEntity(userId, recipeId);
            RecipeResponse? recipe = null;

            if (entity == null)
            {
                _logger.LogWarning("Recipe with ID of {RecipeId} not found for user with ID of {UserId}.", recipeId, userId);
            }
            else
            {
                _logger.LogInformation("Recipe with ID of {RecipeId} found for user with ID of {UserId}.", recipeId, userId);
                recipe = new RecipeResponse(entity.Id.ToString() ?? string.Empty, entity.Name, entity.Description);
            }

            return recipe;
        }

        public async Task EditRecipe(string userId, string recipeId, RecipeRequest newRecipe)
        {
            var recipe = await GetRecipeEntity(userId, recipeId);

            if (recipe == null)
            {
                NotFound(userId, recipeId);
            }
            else
            {
                recipe.Name = newRecipe.Name;
                recipe.Description = newRecipe.Description;

                await _db.SaveChangesAsync();

                _logger.LogInformation("Recipe with ID of {RecipeId} updated for user with ID of {UserId}.", recipeId, userId);
            }
        }

        public async Task<string> AddRecipe(string userId, RecipeRequest newRecipe)
        {
            var addedRecipe = await _db.Recipes.AddAsync(new Recipe
            {
                Name = newRecipe.Name,
                Description = newRecipe.Description,
                OwnerId = userId
            });

            await _db.SaveChangesAsync();

            return addedRecipe.Entity.Id.ToString() ?? string.Empty;
        }

        public async Task DeleteRecipe(string userId, string recipeId)
        {
            var recipe = await GetRecipeEntity(userId, recipeId);

            if (recipe == null)
            {
                NotFound(userId, recipeId);
            }
            else
            {
                _db.Recipes.Remove(recipe);
                await _db.SaveChangesAsync();
                _logger.LogInformation("Recipe with ID of {RecipeId} deleted for user with ID of {UserId}.", recipeId, userId);
            }
        }

        private void NotFound(string userId, string recipeId)
        {
            _logger.LogWarning("Recipe with ID of {RecipeId} not found for user with ID of {UserId}.", recipeId, userId);
            throw new InvalidOperationException($"User with ID of {userId} or recipe with ID of {recipeId} not found.");
        }

        private async Task<Recipe?> GetRecipeEntity(string userId, string recipeId)
        {
            return await _db.Recipes
                .Where(r => r.Id == Guid.Parse(recipeId) && r.OwnerId == userId)
                .FirstOrDefaultAsync();
        }
    }
}
