using Microsoft.AspNetCore.Components.WebAssembly.Authentication;

namespace Recipes.Web;

public class RecipeService : WebApiService, IRecipesService
{
    public RecipeService(IAccessTokenProvider authorizationService, IConfiguration config, HttpClient http)
        : base(authorizationService, config, http)
    {
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
}
