﻿namespace Recipes.Web;

public interface IRecipesService
{
    Task CreateRecipe(RecipeResponse recipe);
    Task<IEnumerable<RecipeResponse>> GetRecipes();
}
