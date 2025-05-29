using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;


var builder = WebApplication.CreateBuilder(args);

// 🔧 Agrega servicios necesarios
builder.Services.AddControllers(); // ← ¡Esta línea es crucial!
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Mi API", Version = "v1" });
});
// Si tienes controladores, asegúrate de que estén en el espacio de nombres correcto

var app = builder.Build();

// 🚀 Habilita Swagger
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/openapi/v1.json", "Mi API V1");
    options.RoutePrefix = "swagger"; // Swagger UI en /swagger
});

app.UseHttpsRedirection();

app.MapControllers(); // ← Ahora sí tiene controladores que mapear

app.Run();