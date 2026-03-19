using MediatR;
using FluentValidation;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Shared.Infrastructure.Repositories;
using IntegradorHub.API.Shared.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

// === KESTREL: Aumentar límite global a 500MB para subida de videos ===
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 524288000; // 500 MB
});

// === SERVICES ===

// Controllers
builder.Services.AddControllers();

// Form options globales para multipart (500MB)
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 524288000; // 500 MB
    options.ValueLengthLimit = int.MaxValue;
    options.MultipartHeadersLengthLimit = int.MaxValue;
});

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// MediatR (CQRS)
builder.Services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly));

// FluentValidation
builder.Services.AddValidatorsFromAssembly(typeof(Program).Assembly);

// Repositories (Firestore)
builder.Services.AddSingleton<IUserRepository, UserRepository>();
builder.Services.AddScoped<IProjectRepository, ProjectRepository>();
builder.Services.AddScoped<IEvaluationRepository, EvaluationRepository>();
builder.Services.AddScoped<IGroupRepository, GroupRepository>();
builder.Services.AddScoped<IMateriaRepository, MateriaRepository>();
builder.Services.AddScoped<ICarreraRepository, CarreraRepository>();

// Storage Service (Supabase)
builder.Services.AddSingleton<IStorageService, SupabaseStorageService>();

// CORS (Dinámico para Producción y Desarrollo)
var allowedOrigins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
var fixedOrigins = new[]
{
    "http://localhost:5173",
    "http://localhost:5174",
    "http://localhost:3000",
    "https://integradorhub-frontend.vercel.app",
    "https://integradorhub.onrender.com"
};
var allOrigins = allowedOrigins.Concat(fixedOrigins).Distinct().ToArray();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.SetIsOriginAllowed(origin =>
            {
                if (string.IsNullOrEmpty(origin)) return false;
                var uri = new Uri(origin);
                // Permitir todos los subdominios de vercel.app (preview + producción)
                if (uri.Host.EndsWith(".vercel.app", StringComparison.OrdinalIgnoreCase)) return true;
                // Permitir orígenes locales y fijos
                return allOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase);
            })
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

var app = builder.Build();

// === MIDDLEWARE ===

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");
app.UseAuthorization();
app.MapControllers();

// Endpoint de prueba
app.MapGet("/api/health", () => new { status = "ok", timestamp = DateTime.UtcNow })
   .WithName("HealthCheck")
   .WithOpenApi();

app.Run();
