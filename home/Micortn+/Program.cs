using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models; // Para OpenApiInfo (información del documento Swagger)
using System; // Para Uri
using System.IO; // Para Path
using System.Reflection; // Para Assembly (si usas comentarios XML)

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Mi Web API de C#", // Título de la API que se mostrará en la interfaz de Swagger
        Version = "v1",          // Versión de la API
        Description = "Una API de ejemplo creada en ASP.NET Core con .NET 9 y Swagger.",
        TermsOfService = new Uri("https://example.com/terms"), // Enlace opcional a términos de servicio
        Contact = new OpenApiContact // Información de contacto opcional
        {
            Name = "Tu Nombre/Empresa",
            Email = "contacto@ejemplo.com",
            Url = new Uri("https://tupaginaweb.com"),
        },
        License = new OpenApiLicense // Información de licencia opcional
        {
            Name = "Licencia de Ejemplo",
            Url = new Uri("https://example.com/license"),
        }
    });

});


var app = builder.Build();


if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage(); // Proporciona información de depuración útil para errores.

    app.UseSwagger();

    // Habilita el middleware de Swagger UI, que sirve la interfaz web interactiva.
    app.UseSwaggerUI(c =>
    {
        // Swagger UI en la raíz para evitar problemas de rutas
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Mi Web API C# V1");
        
        c.RoutePrefix = string.Empty;
    });
}
else
{
    // En producción, usamos una página de errores más genérica.
    app.UseExceptionHandler("/Error");
    // HSTS (HTTP Strict Transport Security) agrega encabezados para forzar el uso de HTTPS.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllers();

app.Run();