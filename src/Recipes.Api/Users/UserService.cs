using Azure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Graph;
using Microsoft.Identity.Web.Resource;
using System.Security.Claims;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.Graph.Models;
using System.Text.Json;

namespace Recipes.Api.Users
{
    internal class UserService : IUserService
    {
        private readonly RecipesDbContext _db;
        private readonly ILogger<IUserService> _logger;
        private readonly IHttpContextAccessor _http;
        private readonly IConfiguration _configuration;

        public UserService(RecipesDbContext db, ILogger<IUserService> logger, IHttpContextAccessor http, IConfiguration configuration)
        {
            _db = db;
            _logger = logger;
            _http = http;
            _configuration = configuration;
        }

        public HttpContext? Http => _http.HttpContext;

        private string GetAuthenticatedUserId()
        {
            var objectIdClaim = Http?.User?.FindFirst("http://schemas.microsoft.com/identity/claims/objectidentifier");

            if (objectIdClaim == null)
            {
                return string.Empty;
            }

            return objectIdClaim.Value;
        }

        private GraphServiceClient GetGraphClient()
        {
            var scopes = new[] { "https://graph.microsoft.com/.default" };

            var clientId = _configuration["AzureAd:ClientId"];
            var tenantId = _configuration["AzureAd:TenantId"];
            var clientSecret = _configuration["Api:ClientSecret"];

            var options = new ClientSecretCredentialOptions
            {
                AuthorityHost = AzureAuthorityHosts.AzurePublicCloud,
            };

            var clientSecretCredential = new ClientSecretCredential(tenantId, clientId, clientSecret, options);

            return new GraphServiceClient(clientSecretCredential, scopes);
        }

        private async Task<User?> FindUserFromGraph(string userId)
        {
            try
            {
                return await GetGraphClient().Users[userId].GetAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user details from Microsoft Graph: {ErrorMessage}", ex.Message);
                return null;
            }
        }

        public async Task<UserResponse?> GetAuthenticatedUser()
        {
            Http?.VerifyUserHasAnyAcceptedScope("Recipes.User.Read");

            var userId = GetAuthenticatedUserId();

            if (string.IsNullOrEmpty(userId))
            {
                _logger.LogWarning("Could not resolve authenticated user object ID from the access token.");
                return null;
            }

            var user = await FindUserFromGraph(userId);

            if (user == null)
            {
                _logger.LogWarning("Could not find user with identifier {UserId} in Microsoft Graph.", userId);
                return null;
            }

            return new UserResponse(userId, user?.GivenName, user?.Surname, user?.UserPrincipalName);
        }

        public async Task<Stream?> GetUserPhoto()
        {
            Http?.VerifyUserHasAnyAcceptedScope("Recipes.User.Read");

            var userId = GetAuthenticatedUserId();

            if (string.IsNullOrEmpty(userId))
            {
                _logger.LogWarning("Could not resolve authenticated user object ID from the access token.");
            }

            return await GetGraphClient().Users[userId].Photo.Content.GetAsync();
        }
    }
}
