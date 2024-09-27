namespace Recipes.Api.Recipes
{
    public class Recipe
    {
        public Guid? Id { get; set; } = null;
        public string Name { get; set; } = string.Empty;
        public string OwnerId { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }
}
