using Microsoft.Identity.Web.Resource;
using Recipes.Api.Users;
using System.Security.Claims;

namespace Recipes.Api.User
{
    public static class UserEndpoints
    {
        public static void MapUserEndpoints(this IEndpointRouteBuilder app)
        {
            app.MapGet("/profile", GetProfile).WithName("Profile").WithOpenApi().RequireAuthorization();
            app.MapPost("/users", CreateUser).WithName("CreateUser").WithOpenApi().RequireAuthorization();
        }

        private static IResult GetProfile(HttpContext httpContext)
        {
            httpContext.VerifyUserHasAnyAcceptedScope("Recipes.User.Read");

            return Results.Ok(new
            {
                Name = httpContext?.User?.Identity?.Name ?? "Unknown",
                Email = httpContext?.User?.FindFirst(ClaimTypes.Email)?.Value ?? "Unknown"
            });
        }

        private static async Task<IResult> CreateUser(HttpContext httpContext, UserModel user, UserDbContext dbContext)
        {
            httpContext.VerifyUserHasAnyAcceptedScope("Recipes.User.Write");

            dbContext.Users.Add(user);
            await dbContext.SaveChangesAsync();

            return Results.Created();
        }
    }
}
