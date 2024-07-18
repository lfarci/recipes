using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web.Resource;
using System.Security.Claims;

namespace Recipes.Api.Recipes
{
    public static class RecipeEndpoints
    {
        public static void MapRecipeEndpoints(this IEndpointRouteBuilder app)
        {
            app.MapGet("/recipes", GetRecipes).WithName("GetRecipes").WithOpenApi().RequireAuthorization();
        }

        private static async Task<IResult> GetRecipes(HttpContext http, RecipesDbContext db, ILogger<Program> logger)
        {
            http.VerifyUserHasAnyAcceptedScope("Recipes.User.Read");

            logger.LogInformation("Accepted scope has been validated.");

            var nameIdentifierClaim = http?.User?.FindFirst(ClaimTypes.NameIdentifier);

            if (nameIdentifierClaim == null)
            {
                logger.LogError("Could not resolve name identifier claim from the access token.");
                return Results.BadRequest("Name identifier not found.");
            }

            var nameIdentifier = nameIdentifierClaim.Value;

            var user = await db.Users.FirstOrDefaultAsync(u => u.Id == nameIdentifier);

            if (user == null)
            {
                logger.LogError("Could not resolve user with {Id}.", nameIdentifier);
                return Results.NotFound();
            }

            logger.LogInformation("User with id {Id} is requesting all recipes.", user.Id);

            var recipes = db.Recipes
                .Where(r => r.OwnerId == user.Id)
                .Select(r => new
                {
                    r.Id,
                    r.Name,
                    r.Description
                })
                .ToList();

            logger.LogInformation("{Amount} recipes found for user with {Id}.", recipes.Count, user.Id);


            return Results.Ok(recipes);
        }
    }
}
