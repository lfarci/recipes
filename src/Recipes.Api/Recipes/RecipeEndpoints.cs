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

            var emailClaim = http?.User?.FindFirst(ClaimTypes.Email);
            if (emailClaim == null)
            {
                logger.LogError("Could not resolve email claim from the access token.");
                return Results.BadRequest("Email not found.");
            }

            var email = emailClaim.Value;

            var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                return Results.NotFound();
            }

            logger.LogInformation("User {Email} (Id: {Id}) is requesting all recipes.", user.Email, user.Id);

            var recipes = db.Recipes
                .Where(r => r.OwnerId == user.Id)
                .Select(r => new
                {
                    r.Id,
                    r.Name,
                    r.Description
                })
                .ToList();

            logger.LogInformation("{Amount} recipes found for user {Email} (Id: {Id}).", recipes.Count, user.Email, user.Id);


            return Results.Ok(recipes);
        }
    }
}
