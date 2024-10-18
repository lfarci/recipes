namespace Recipes.Api.Recipes
{
    public interface IRecipeService
    {
        Task<IEnumerable<RecipeResponse>> GetRecipes(string userId, int pageIndex, int pageSize);
        Task<RecipeResponse?> GetRecipe(string userId, string recipeId);
        Task EditRecipe(string userId, string recipeId, RecipeRequest newRecipe);
        Task<string> AddRecipe(string userId, RecipeRequest newRecipe);
        Task DeleteRecipe(string userId, string recipeId);
    }
}
