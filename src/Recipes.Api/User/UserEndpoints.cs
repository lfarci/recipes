using Microsoft.Identity.Web.Resource;
using System.Security.Claims;

namespace Recipes.Api.User
{
    public static class UserEndpoints
    {
        public static void MapUserEndpoints(this IEndpointRouteBuilder app)
        {
            app.MapPost("/users", CreateUser).WithName("CreateUser").WithOpenApi().RequireAuthorization();
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
                LastName = user.LastName
            });

            await dbContext.SaveChangesAsync();

            return Results.Created("GetUser", new { createdUser.Entity.Id });
        }
    }
}
