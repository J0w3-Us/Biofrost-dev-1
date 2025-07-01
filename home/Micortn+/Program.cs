using numberOperacion.Services.EvenOddApp.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models;
using System;
using Microsoft.EntityFrameworkCore;
using Micort.Infrest.Context;
using Micort.Domain;
using Micort.Domain.Entities;


var builder = WebApplication.CreateBuilder(args);

// Configuración de la cadena de conexión (ajusta el nombre y valores según tu entorno)
builder.Services.AddDbContext<MicortDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<NumberServices>();
builder.Services.AddScoped<Micort.service.feactures.EncryptionService>();
builder.Services.AddControllers();

// Quitar autenticación y autorización para pruebas locales
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = "https://localhost:5001";
        options.Audience = "api1";
        options.RequireHttpsMetadata = false;
    });

// builder.Services.AddAuthorization();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(opcion =>
{
    opcion.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Version = "v1",
        Title = "Number Parity API",
        Description = "Una api que verifica numeros pares"
    });
    // Configuración de seguridad para el botón Authorize y candados
    opcion.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Ingrese el token en el campo: Bearer {token}"
    });
    opcion.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

var app = builder.Build();

// Habilitar DeveloperExceptionPage y Swagger en todos los entornos (incluyendo producción)
app.UseDeveloperExceptionPage();
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "Number Parity API v1");
    options.RoutePrefix = string.Empty;
});

// Usar archivos de configuración según el entorno (asegura que los json se lean en producción)
// Esto ya lo maneja automáticamente WebApplication.CreateBuilder(args),
// pero si quieres asegurarte, puedes agregar:
// builder.Configuration.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
//                      .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true);

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();