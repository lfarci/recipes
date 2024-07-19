namespace Recipes.Api.User
{
    internal interface IUserService
    {
        Task<UserEntity?> GetAuthenticatedUser();
    }
}
