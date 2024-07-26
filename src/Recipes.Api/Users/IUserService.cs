namespace Recipes.Api.Users
{
    internal interface IUserService
    {
        Task<UserResponse?> GetAuthenticatedUser();
        Task<Stream?> GetUserPhoto();
    }
}
