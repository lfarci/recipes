using Microsoft.EntityFrameworkCore;
using Recipes.Api.User;

namespace Recipes.Api.Users
{
    public class UserDbContext : DbContext
    {
        public UserDbContext(DbContextOptions<UserDbContext> options)
            : base(options) { }

        public DbSet<UserEntity> Users { get; set; }
    }
}