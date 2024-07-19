using Recipes.Api.User;

namespace Recipes.Api.Recipes
{
    public static class RecipeEndpoints
    {
        public static void MapRecipeEndpoints(this IEndpointRouteBuilder app)
        {
            app.MapGet("/recipes", GetRecipes).WithName("GetRecipes").WithOpenApi().RequireAuthorization();
        }

        private static async Task<IResult> GetRecipes(IUserService users, IRecipeService recipes)
        {
            var user = await users.GetAuthenticatedUser();

            if (user == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(await recipes.GetRecipes(user.Id));
        }
    }
}
