using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace IntegradorHub.API.Shared.Infrastructure.Services;

public interface IStorageService
{
    Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, string folder = "projects");
    Task<bool> DeleteFileAsync(string filePath);
    string GetPublicUrl(string filePath);
}

public class SupabaseStorageService : IStorageService
{
    private readonly HttpClient _httpClient;
    private readonly string _supabaseUrl;
    private readonly string _bucketName;

    public SupabaseStorageService(IConfiguration configuration)
    {
        _supabaseUrl = configuration["Supabase:Url"] ?? throw new ArgumentNullException("Supabase:Url not configured");
        var serviceKey = configuration["Supabase:ServiceKey"] ?? throw new ArgumentNullException("Supabase:ServiceKey not configured");
        _bucketName = configuration["Supabase:BucketName"] ?? "project-files";

        _httpClient = new HttpClient();
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", serviceKey);
        _httpClient.DefaultRequestHeaders.Add("apikey", serviceKey);
    }

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, string folder = "projects")
    {
        // Generar nombre único para evitar colisiones.
        // Reemplazar espacios o caracteres especiales en el fileName principal
        var safeFileName = fileName.Replace(" ", "_");
        var uniqueFileName = $"{folder}/{Guid.NewGuid()}_{safeFileName}";
        
        // Supabase requiere que la ruta del objeto (que incluye carpetas) se pase
        // en la URL pero separada limpiamente (bucket/folder/file)
        var url = $"{_supabaseUrl}/storage/v1/object/{_bucketName}/{uniqueFileName}";

        using var content = new StreamContent(fileStream);
        content.Headers.ContentType = new MediaTypeHeaderValue(contentType);

        var response = await _httpClient.PostAsync(url, content);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            throw new Exception($"Error uploading file to Supabase: {error}");
        }

        return uniqueFileName;
    }

    public async Task<bool> DeleteFileAsync(string filePath)
    {
        var url = $"{_supabaseUrl}/storage/v1/object/{_bucketName}/{filePath}";
        
        var response = await _httpClient.DeleteAsync(url);
        return response.IsSuccessStatusCode;
    }

    public string GetPublicUrl(string filePath)
    {
        return $"{_supabaseUrl}/storage/v1/object/public/{_bucketName}/{filePath}";
    }
}
