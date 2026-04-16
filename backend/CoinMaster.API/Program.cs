using System.Text;
using CoinMaster.API.Data;
using CoinMaster.API.Hubs;
using CoinMaster.API.Middleware;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Connection string: prefer DATABASE_URL env var (Railway)
var connectionString = Environment.GetEnvironmentVariable("DATABASE_URL")
    ?? builder.Configuration.GetConnectionString("DefaultConnection")!;

// If Railway format (postgres://), convert to Npgsql format
if (connectionString.StartsWith("postgres://") || connectionString.StartsWith("postgresql://"))
{
    var uri = new Uri(connectionString);
    var userInfo = uri.UserInfo.Split(':');
    connectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.TrimStart('/')};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true";
}

builder.Services.AddDbContext<AppDbContext>(opt => opt.UseNpgsql(connectionString));

// JWT
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"]!;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true, ValidateAudience = true,
            ValidateLifetime = true, ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
        };
        // Allow SignalR JWT from query string
        opt.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var token = ctx.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(token) && ctx.HttpContext.Request.Path.StartsWithSegments("/hubs"))
                    ctx.Token = token;
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddCors(opt => opt.AddPolicy("AllowAll", p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

// GameSettings
builder.Services.Configure<GameSettings>(builder.Configuration.GetSection("GameSettings"));
builder.Services.AddSingleton<GameSettings>(sp =>
{
    var gs = new GameSettings();
    builder.Configuration.GetSection("GameSettings").Bind(gs);
    return gs;
});

// Services — register NotificationService first since others depend on it
builder.Services.AddScoped<JwtService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddScoped<SpinService>();
builder.Services.AddScoped<AttackService>();
builder.Services.AddScoped<RaidService>();
builder.Services.AddScoped<BuildingService>();
builder.Services.AddScoped<CardService>();
builder.Services.AddScoped<PetService>();
builder.Services.AddScoped<EventService>();
builder.Services.AddScoped<AchievementService>();
builder.Services.AddScoped<SocialService>();
builder.Services.AddScoped<PlayerStateService>();

builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

// Serve uploaded files
var uploadsPath = Path.Combine(app.Environment.ContentRootPath, "uploads");
Directory.CreateDirectory(uploadsPath);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));
app.MapControllers();
app.MapHub<GameHub>("/hubs/game");

app.Run();
