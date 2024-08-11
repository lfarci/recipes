namespace Recipes.Web;

public interface IRecipesService
{
    Task<IEnumerable<RecipeResponse>> GetRecipes();
}
