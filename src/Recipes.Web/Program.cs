using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using Microsoft.FluentUI.AspNetCore.Components;
using Recipes.Web.Components;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
var baseAddress = builder.Configuration["BaseAddress"] ?? "https://localhost:3000";

builder.Services.AddFluentUIComponents();

builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

builder.Configuration.AddUserSecrets<Program>();

builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri(baseAddress) });

builder.Services.AddMsalAuthentication(options =>
{
    builder.Configuration.Bind("AzureAd", options.ProviderOptions.Authentication);
    options.ProviderOptions.LoginMode = "redirect";

    var scopesSection = builder.Configuration.GetSection("AzureAd:DefaultAccessTokenScopes");
    var scopes = scopesSection.Get<string[]>();

    if (scopesSection.Exists() && scopes != null)
    {
        options.ProviderOptions.DefaultAccessTokenScopes = scopes;
    }
});

await builder.Build().RunAsync();
