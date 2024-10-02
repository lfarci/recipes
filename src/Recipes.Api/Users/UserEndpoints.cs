using Microsoft.Identity.Web.Resource;
using System.Security.Claims;

namespace Recipes.Api.Users
{
    public static class UserEndpoints
    {
        public static void MapUserEndpoints(this IEndpointRouteBuilder app)
        {
            app.MapGet("/user", GetUser).WithName("GetUser").WithOpenApi().RequireAuthorization();
            app.MapGet("/user/photo", GetUserPhoto).WithName("GetUserPhoto").WithOpenApi().RequireAuthorization();
            app.MapPost("/users", CreateUser).WithName("CreateUser").WithOpenApi().RequireAuthorization();
        }

        private static async Task<IResult> GetUserPhoto(HttpContext context, IUserService users)
        {
            var photo = await users.GetUserPhoto();

            if (photo == null)
            {
                return Results.NotFound();
            }

            return Results.File(photo, "image/png");
        }

        private static async Task<IResult> GetUser(IUserService users)
        {
            var user = await users.GetAuthenticatedUser();

            if (user == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(user);
        }

        private static async Task<IResult> CreateUser(HttpContext httpContext, UserRequest user, RecipesDbContext dbContext)
        {
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
