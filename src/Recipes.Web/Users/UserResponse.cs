using System.Text;
using System.Text.Json.Serialization;

namespace Recipes.Web.Users
{
    public class UserResponse
    {
        public static readonly UserResponse Default = new()
        {
            Id = string.Empty,
            FirstName = string.Empty,
            LastName = string.Empty,
            UserName = string.Empty
        };

        [JsonPropertyName("id")]
        public string Id { get; init; } = string.Empty;

        [JsonPropertyName("firstName")]
        public string? FirstName { get; init; }

        [JsonPropertyName("lastName")]
        public string? LastName { get; init; }

        [JsonPropertyName("userName")]
        public string? UserName { get; init; }

        public UserResponse()
        {
        }

        public UserResponse(string id, string? firstName, string? lastName, string? userName)
        {
            Id = id;
            FirstName = firstName;
            LastName = lastName;
            UserName = userName;
        }

        [JsonIgnore]
        public string DisplayName
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(FirstName) && !string.IsNullOrWhiteSpace(LastName))
                {
                    return $"{FirstName} {LastName}";
                }

                return UserName ?? string.Empty;
            }
        }

        [JsonIgnore]
        public string Initials
        {
            get
            {
                var initials = new StringBuilder();

                if (!string.IsNullOrWhiteSpace(FirstName))
                {
                    initials.Append(FirstName[0]);
                }

                if (!string.IsNullOrWhiteSpace(LastName))
                {
                    initials.Append(LastName[0]);
                }

                if (initials.Length == 0)
                {
                    initials.Append("X");
                }

                return initials.ToString();
            }
        }
    }
}
