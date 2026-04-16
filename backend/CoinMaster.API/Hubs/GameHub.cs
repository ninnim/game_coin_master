using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;
using System.Security.Claims;

namespace CoinMaster.API.Hubs;

[Authorize]
public class GameHub : Hub
{
    private static readonly ConcurrentDictionary<string, string> _connections = new();

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId != null)
        {
            _connections[Context.ConnectionId] = userId;
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _connections.TryRemove(Context.ConnectionId, out _);
        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinClan(string clanId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"clan_{clanId}");
    }

    public static bool IsUserOnline(string userId) =>
        _connections.Values.Contains(userId);
}
