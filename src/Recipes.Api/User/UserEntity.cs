using Recipes.Api.Recipes;
using System.ComponentModel.DataAnnotations.Schema;

namespace Recipes.Api.User
{
    [Table("User")]
    public class UserEntity
    {
        public long Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;

        public virtual ICollection<RecipeEntity> Recipes { get; set; } = [];
    }
}
