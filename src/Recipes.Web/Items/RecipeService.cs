using Microsoft.AspNetCore.Components.WebAssembly.Authentication;
using Recipes.Web.Common;

namespace Recipes.Web;

public class RecipeService : WebApiService, IRecipesService
{
    public RecipeService(IAccessTokenProvider authorizationService, IConfiguration config, HttpClient http)
        : base(authorizationService, config, http)
    {
    }

    public async Task<RecipeResponse?> GetRecipe(long recipeId)
    {
        var response = await Get<RecipeResponse>($"recipes/{recipeId}");
        RecipeResponse? recipe = null;

        if (response.Success)
        {
            recipe = response.Value ?? new RecipeResponse();
        }

        return recipe;
    }

    public async Task<IEnumerable<RecipeResponse>> GetRecipes()
    {
        var response = await Get<IEnumerable<RecipeResponse>>("recipes?page=1&size=1000");
        IEnumerable<RecipeResponse> recipes = [];

        if (response.Success)
        {
            recipes = response.Value ?? [];
        }

        return recipes;
    }

    public async Task CreateRecipe(RecipeResponse recipe)
    {
        await Post("recipes", recipe);
    }

    public async Task DeleteRecipe(long recipeId)
    {
        await Delete($"recipes/{recipeId}");
    }
}
