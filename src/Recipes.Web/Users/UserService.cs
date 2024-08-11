using Microsoft.AspNetCore.Components.WebAssembly.Authentication;

namespace Recipes.Web.Users
{

    internal class UserService : WebApiService, IUserService
    {
        private UserResponse? _user = default;

        public UserResponse? Current => _user;

        public event Action? OnChange;

        public UserService(IAccessTokenProvider authorizationService, IConfiguration config, HttpClient http)
            : base(authorizationService, config, http)
        {
        }

        public async Task<UserResponse?> GetUser()
        {
            var response = await Get<UserResponse>("user");
            UserResponse? user = default;

            if (response.Success)
            {
                user = response.Value;
            }

            _user = user;
            NotifyStateChanged();

            return user;
        }

        public void NotifyStateChanged() => OnChange?.Invoke();
    }
}
