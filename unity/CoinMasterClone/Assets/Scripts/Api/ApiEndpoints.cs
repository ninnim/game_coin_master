namespace CoinMasterClone.Api
{
    /// <summary>
    /// Mirrors the Flutter api_endpoints.dart — same ASP.NET Core backend.
    /// </summary>
    public static class ApiEndpoints
    {
        // Config: swap between local dev and Railway production as needed.
        public const string BaseUrl = "https://your-railway-url.up.railway.app";
        // public const string BaseUrl = "http://localhost:5000"; // local dev

        public const string Register = "/api/auth/register";
        public const string Login = "/api/auth/login";
        public const string Me = "/api/auth/me";

        public const string Spin = "/api/spin";
        public const string SpinHistory = "/api/spin/history";
        public const string SpinBet = "/api/spin/bet";

        public const string Attack = "/api/attack";
        public const string Raid = "/api/raid";

        public const string PlayerState = "/api/player/state";
        public const string PlayerTargets = "/api/player/targets";

        public const string Villages = "/api/villages";
        public const string CurrentVillage = "/api/villages/current";
        public static string UpgradeBuilding(string id) => $"/api/buildings/{id}/upgrade";

        public const string Cards = "/api/cards";
        public const string Chests = "/api/chests";
        public const string OpenChest = "/api/chests/open";

        public const string Pets = "/api/pets";
        public static string ActivatePet(string id) => $"/api/pets/{id}/activate";
        public static string FeedPet(string id) => $"/api/pets/{id}/feed";

        public const string Friends = "/api/friends";
        public const string Leaderboard = "/api/leaderboard";
        public const string ActiveEvents = "/api/events/active";
        public const string Achievements = "/api/achievements";
        public const string Profile = "/api/profile";
    }
}
