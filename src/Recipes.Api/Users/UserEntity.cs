using Recipes.Api.Recipes;
using System.ComponentModel.DataAnnotations.Schema;

namespace Recipes.Api.Users
{
    [Table("User")]
    public class UserEntity
    {
        public string Id { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;

        public virtual ICollection<RecipeEntity> Recipes { get; set; } = [];
    }
}
