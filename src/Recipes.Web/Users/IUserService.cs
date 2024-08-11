namespace Recipes.Web.Users
{
    public interface IUserService
    {
        public UserResponse? Current { get; }
        public event Action? OnChange;

        Task<UserResponse?> GetUser();
    }
}
