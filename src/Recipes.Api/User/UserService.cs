using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web.Resource;
using System.Security.Claims;

namespace Recipes.Api.User
{
    internal class UserService : IUserService
    {
        private readonly RecipesDbContext _db;
        private readonly ILogger<IUserService> _logger;
        private readonly IHttpContextAccessor _http;

        public UserService(RecipesDbContext db, ILogger<IUserService> logger, IHttpContextAccessor http)
        {
            _db = db;
            _logger = logger;
            _http = http;
        }

        public HttpContext? Http => _http.HttpContext;

        private string GetAuthenticatedUserId()
        {
            var nameIdentifierClaim = Http?.User?.FindFirst(ClaimTypes.NameIdentifier);

            if (nameIdentifierClaim == null)
            {
                return string.Empty;
            }

            return nameIdentifierClaim.Value;
        }

        public async Task<UserEntity?> GetAuthenticatedUser()
        {
            Http?.VerifyUserHasAnyAcceptedScope("Recipes.User.Read");

            var userId = GetAuthenticatedUserId();

            if (string.IsNullOrEmpty(userId))
            {
                _logger.LogWarning("Could not resolve authenticated user name identifier from the access token.");
                return null;
            }

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                _logger.LogError("Could not resolve user with ID {Id} from the database.", userId);
            }
            else
            {
                _logger.LogInformation("Resolved user with ID {Id} from the database.", userId);
            }

            return user;
        }
    }
}
