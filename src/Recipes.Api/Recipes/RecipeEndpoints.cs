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

        private static async Task<IResult> GetRecipes(HttpContext http, RecipesDbContext db)
        {
            http.VerifyUserHasAnyAcceptedScope("Recipes.User.Read");

            var emailClaim = http?.User?.FindFirst(ClaimTypes.Email);
            if (emailClaim == null)
            {
                return Results.BadRequest("Email not found.");
            }

            var email = emailClaim.Value;

            var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                return Results.NotFound();
            }

            var recipes = db.Recipes
                .Where(r => r.OwnerId == user.Id)
                .Select(r => new
                {
                    r.Id,
                    r.Name,
                    r.Description
                })
                .ToList();

            return Results.Ok(recipes);
        }
    }
}
