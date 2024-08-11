﻿using Microsoft.AspNetCore.Components.WebAssembly.Authentication;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Net;

namespace Recipes.Web
{
    public class ApiResponse<T>
    {
        public bool Success { get; init; }
        public HttpStatusCode StatusCode { get; init; }
        public T? Value { get; init; }
    }

    public abstract class WebApiService
    {
        private static readonly string _apiAddressPropertyName = "RecipesApiAddress";

        protected readonly IAccessTokenProvider _authorization;
        protected readonly IConfiguration _configuration;
        protected readonly HttpClient _http;

        public WebApiService(IAccessTokenProvider authorizationService, IConfiguration config, HttpClient http)
        {
            _authorization = authorizationService;
            _configuration = config;
            _http = http;
        }

        public string ApiAddress => _configuration[_apiAddressPropertyName] ?? string.Empty;

        protected async Task<string?> RequestAccessToken()
        {
            var tokenResult = await _authorization.RequestAccessToken();
            string? value = null;

            if (tokenResult.TryGetToken(out var token))
            {
                value = token.Value;
            }

            return value;
        }

        public async Task<ApiResponse<T>> Get<T>(string path, Func<HttpContent, Task<T?>> read)
        {
            HttpResponseMessage response = await Get(path);
            T? result = default;

            if (response.IsSuccessStatusCode)
            {
                result = await read(response.Content);
            }

            return new ApiResponse<T>()
            {
                Success = response.IsSuccessStatusCode,
                StatusCode = response.StatusCode,
                Value = result
            };
        }

        public async Task<ApiResponse<T>> Get<T>(string path)
        {
            return await Get<T>(path, ReadJsonContent<T>);
        }

        public async Task<ApiResponse<string>> GetAsBase64(string path) => await Get(path, ReadBase64Content);

        private async Task<HttpResponseMessage> Get(string path) => await _http.SendAsync(await BuildHttpRequestMessage(HttpMethod.Get, path));

        private static async Task<T?> ReadJsonContent<T>(HttpContent content) => JsonSerializer.Deserialize<T>(await content.ReadAsStringAsync());

        private static async Task<string?> ReadBase64Content(HttpContent content)
        {
            using var stream = await content.ReadAsStreamAsync();
            using var memoryStream = new MemoryStream();
            await stream.CopyToAsync(memoryStream);
            return Convert.ToBase64String(memoryStream.ToArray());
        }

        private string BuildRequestUri(string path)
        {
            if (string.IsNullOrEmpty(ApiAddress))
            {
                throw new InvalidOperationException($"Could not find API address from configuration: \"{_apiAddressPropertyName}\".");
            }

            if (string.IsNullOrEmpty(path))
            {
                throw new ArgumentException(nameof(path));
            }

            return $"{ApiAddress}/{path}";
        }

        private async Task<HttpRequestMessage> BuildHttpRequestMessage(HttpMethod method, string path)
        {
            var accessToken = await RequestAccessToken();

            var request = new HttpRequestMessage(method, BuildRequestUri(path));
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            return request;
        }
    }
}