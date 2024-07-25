using Recipes.Api.User;

namespace Recipes.Api.Recipes
{
    public static class RecipeEndpoints
    {
        public static void MapRecipeEndpoints(this IEndpointRouteBuilder app)
        {
            app.MapGet("/recipes", GetRecipes).WithName("GetRecipes").WithOpenApi().RequireAuthorization();
            app.MapGet("/recipes/{recipeId}", GetRecipe).WithName("GetRecipe").WithOpenApi().RequireAuthorization();
            app.MapPut("/recipes/{recipeId}", EditRecipe).WithName("EditRecipe").WithOpenApi().RequireAuthorization();
            app.MapPost("/recipes", AddRecipe).WithName("AddRecipe").WithOpenApi().RequireAuthorization();
            app.MapDelete("/recipes/{recipeId}", DeleteRecipe).WithName("DeleteRecipe").WithOpenApi().RequireAuthorization();
        }

        private static async Task<IResult> GetRecipes(IUserService users, IRecipeService recipes, int page, int size)
        {
            var user = await users.GetAuthenticatedUser();

            if (user == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(await recipes.GetRecipes(user.Id, page, size));
        }

        private static async Task<IResult> GetRecipe(IUserService users, IRecipeService recipes, long recipeId)
        {
            var user = await users.GetAuthenticatedUser();

            if (user == null)
            {
                return Results.NotFound();
            }

            var recipe = await recipes.GetRecipe(user.Id, recipeId);

            if (recipe == null)
            {
                return Results.NotFound();
            }
            else
            {
                return Results.Ok(recipe);
            }
        }

        private static async Task<IResult> EditRecipe(IUserService users, IRecipeService recipes, long recipeId, RecipeRequest recipe)
        {
            var user = await users.GetAuthenticatedUser();

            if (user == null)
            {
                return Results.NotFound();
            }

            await recipes.EditRecipe(user.Id, recipeId, recipe);

            return Results.Ok();
        }

        private static async Task<IResult> AddRecipe(IUserService users, IRecipeService recipes, RecipeRequest recipe)
        {
            var user = await users.GetAuthenticatedUser();

            if (user == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(await recipes.AddRecipe(user.Id, recipe));
        }

        private static async Task<IResult> DeleteRecipe(IUserService users, IRecipeService recipes, long recipeId)
        {
            var user = await users.GetAuthenticatedUser();

            if (user == null)
            {
                return Results.NotFound();
            }

            await recipes.DeleteRecipe(user.Id, recipeId);

            return Results.Ok();
        }
    }
}
