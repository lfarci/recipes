using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web;
using Recipes.Api.User;
using Recipes.Api.Users;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var connectionStringName = "RecipesDatabase";
var connectionString = builder.Configuration.GetConnectionString(connectionStringName) ??
                       Environment.GetEnvironmentVariable($"SQLCONNSTR_{connectionStringName}");

builder.Services
    .AddDbContext<UserDbContext>(options => options.UseSqlServer(connectionString));

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
app.MapUserEndpoints();

app.Run();