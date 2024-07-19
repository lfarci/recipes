using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web;
using Recipes.Api;
using Recipes.Api.Recipes;
using Recipes.Api.User;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors();

builder.Services.AddLogging(loggingBuilder =>
{
    loggingBuilder.AddConsole();
    loggingBuilder.AddAzureWebAppDiagnostics();
});

var connectionStringName = "RecipesDatabase";
var connectionString = builder.Configuration.GetConnectionString(connectionStringName) ??
                       Environment.GetEnvironmentVariable($"SQLCONNSTR_{connectionStringName}");

builder.Services
    .AddDbContext<RecipesDbContext>(options => options.UseSqlServer(connectionString));

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IRecipeService, RecipeService>();
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

app.UseAuthentication();
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