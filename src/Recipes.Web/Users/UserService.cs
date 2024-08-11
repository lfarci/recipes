using Microsoft.AspNetCore.Components.WebAssembly.Authentication;

namespace Recipes.Web.Users
{

    internal class UserService : WebApiService, IUserService
    {
        private UserState? _state = default;

        public UserState? Current => _state;

        public event Action OnStateChange = () => { };

        public UserService(IAccessTokenProvider authorizationService, IConfiguration config, HttpClient http)
            : base(authorizationService, config, http)
        {
        }

        public async Task LoadUserDetails()
        {
            var detailsResponse = await Get<UserResponse>("user");
            var photoResponse = await GetAsBase64("user/photo");

            UserResponse? user = default;
            string? photo = string.Empty;

            if (detailsResponse.Success)
            {
                user = detailsResponse.Value;
            }

            if (photoResponse.Success)
            {
                photo = photoResponse.Value;
            }

            _state = new UserState()
            {
                FirstName = user?.FirstName ?? string.Empty,
                LastName = user?.LastName ?? string.Empty,
                UserName = user?.UserName ?? string.Empty,
                Photo = photo
            };

            NotifyStateChanged();
        }

        private void NotifyStateChanged()
        {
            OnStateChange?.Invoke();
        }
    }
}
