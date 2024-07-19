namespace Recipes.Api.Recipes
{
    public interface IRecipeService
    {
        Task<IEnumerable<RecipeResponse>> GetRecipes(string userId);
    }
}
