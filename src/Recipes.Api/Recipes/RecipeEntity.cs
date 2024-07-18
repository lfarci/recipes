using Recipes.Api.User;
using System.ComponentModel.DataAnnotations.Schema;

namespace Recipes.Api.Recipes
{
    [Table("Recipe")]
    public class RecipeEntity
    {
        public long Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string OwnerId { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        public virtual UserEntity Owner { get; set; } = null!;
    }
}
