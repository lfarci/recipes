namespace Recipes.Api.Recipes
{
    public interface IRecipeService
    {
        Task<IEnumerable<RecipeResponse>> GetRecipes(string userId, int pageIndex, int pageSize);
        Task<RecipeResponse?> GetRecipe(string userId, long recipeId);
        Task EditRecipe(string userId, long recipeId, RecipeRequest newRecipe);
        Task<long> AddRecipe(string userId, RecipeRequest newRecipe);
        Task DeleteRecipe(string userId, long recipeId);
    }
}
