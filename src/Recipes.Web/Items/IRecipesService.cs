namespace Recipes.Web;

public interface IRecipesService
{
    Task CreateRecipe(RecipeResponse recipe);
    Task<IEnumerable<RecipeResponse>> GetRecipes();
    Task<RecipeResponse?> GetRecipe(string recipeId);
    Task DeleteRecipe(string recipeId);
}
