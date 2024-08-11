namespace Recipes.Web.Users
{
    public interface IUserService
    {
        public UserState? Current { get; }
        public event Action OnStateChange;

        Task LoadUserDetails();
    }
}
