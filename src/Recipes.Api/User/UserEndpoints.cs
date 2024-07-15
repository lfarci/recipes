using Microsoft.Identity.Web.Resource;
using System.Security.Claims;

namespace Recipes.Api.User
{
    public static class UserEndpoints
    {
        public static void MapUserEndpoints(this IEndpointRouteBuilder app)
        {
            app.MapGet("/users/{userId}", GetUser).WithName("GetUser").WithOpenApi().RequireAuthorization();
            app.MapPost("/users", CreateUser).WithName("CreateUser").WithOpenApi().RequireAuthorization();
        }

        private static async Task<IResult> GetUser(HttpContext httpContext, long userId, RecipesDbContext dbContext)
        {
            httpContext.VerifyUserHasAnyAcceptedScope("Recipes.User.Read");

            var entity = await dbContext.Users.FindAsync(userId);

            if (entity == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(new { entity.FirstName, entity.LastName, entity.Email });
        }

        private static async Task<IResult> CreateUser(HttpContext httpContext, UserRequest user, RecipesDbContext dbContext)
        {
            httpContext.VerifyUserHasAnyAcceptedScope("Recipes.User.Write");

            var emailClaim = httpContext?.User?.FindFirst(ClaimTypes.Email);
            if (emailClaim == null)
            {
                return Results.BadRequest("Email not found.");
            }

            var email = emailClaim.Value;

            var createdUser = dbContext.Users.Add(new UserEntity()
            {
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = email
            });

            await dbContext.SaveChangesAsync();

            return Results.Created("GetUser", new { createdUser.Entity.Id });
        }
    }
}
