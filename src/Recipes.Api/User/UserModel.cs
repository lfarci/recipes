using System.ComponentModel.DataAnnotations.Schema;

namespace Recipes.Api.User
{
    [Table("User")]
    public class UserModel
    {
        public long Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
    }
}
