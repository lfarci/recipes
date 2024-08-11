using System.Text;

namespace Recipes.Web.Users
{
    public class UserState
    {
        public static readonly UserState Default = new()
        {
            Id = string.Empty,
            FirstName = string.Empty,
            LastName = string.Empty,
            UserName = string.Empty
        };

        public string Id { get; init; } = string.Empty;

        public string? FirstName { get; init; }

        public string? LastName { get; init; }

        public string? UserName { get; init; }
        public string? Photo { get; init; }

        public UserState()
        {
        }

        public UserState(string id, string? firstName, string? lastName, string? userName)
        {
            Id = id;
            FirstName = firstName;
            LastName = lastName;
            UserName = userName;
        }

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

        public string PhotoSource => $"data:image/jpeg;base64,{Photo}";
    }
}
