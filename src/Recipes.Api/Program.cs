using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web;
using Recipes.Api;
using Recipes.Api.Recipes;
using Recipes.Api.Users;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

// When running the application locally use dotnet user-secrets instead of Key Vault
if (!builder.Environment.IsDevelopment())
{
    builder.Configuration.AddAzureKeyVault(
        new Uri($"https://{builder.Configuration["KeyVaultName"]}.vault.azure.net/"),
        new DefaultAzureCredential());
}

builder.Services.AddAuthorization();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors();

builder.Services.AddLogging(loggingBuilder =>
{
    loggingBuilder.AddConsole();
    loggingBuilder.AddAzureWebAppDiagnostics();
});

var cosmosDbConnectionStringName = "RecipesDocumentDatabase";
var cosmosDbConnectionString = builder.Configuration.GetConnectionString(cosmosDbConnectionStringName) ??
                       Environment.GetEnvironmentVariable($"DOCDBCONNSTR_{cosmosDbConnectionStringName}");
builder.Services
    .AddDbContext<RecipesDbContext>(options => options.UseCosmos(cosmosDbConnectionString!, "Recipes"));

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IRecipeService, RecipeService>();
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

//app.UseAuthentication();
app.UseAuthorization();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors(builder => builder.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()); // Configure CORS to accept all clients

app.MapUserEndpoints();
app.MapRecipeEndpoints();

app.Run();