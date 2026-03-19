using IntegradorHub.API.Shared.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;

namespace IntegradorHub.API.Features.Storage;

[ApiController]
[Route("api/[controller]")]
public class StorageController : ControllerBase
{
    private readonly IStorageService _storageService;
    private readonly ILogger<StorageController> _logger;

    public StorageController(IStorageService storageService, ILogger<StorageController> logger)
    {
        _storageService = storageService;
        _logger = logger;
    }

    /// <summary>
    /// Sube un archivo al storage de Supabase
    /// </summary>
    [HttpPost("upload")]
    [RequestSizeLimit(524288000)] // 500 MB
    [RequestFormLimits(MultipartBodyLengthLimit = 524288000)] // 500 MB
    public async Task<IActionResult> UploadFile(IFormFile file, [FromQuery] string folder = "projects")
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { error = "No file provided" });
        }

        // Validar tamaño (máximo 500MB)
        if (file.Length > 500L * 1024 * 1024)
        {
            return BadRequest(new { error = "File size exceeds 500MB limit" });
        }

        // Validar tipo de archivo
        var allowedTypes = new[] { 
            "image/jpeg", "image/png", "image/gif", "image/webp", "application/pdf",
            "video/mp4", "video/webm", "video/quicktime"
        };
        if (!allowedTypes.Contains(file.ContentType))
        {
            return BadRequest(new { error = "Invalid file type. Allowed: JPEG, PNG, GIF, WebP, PDF, MP4, WebM, MOV" });
        }

        try
        {
            using var stream = file.OpenReadStream();
            var filePath = await _storageService.UploadFileAsync(stream, file.FileName, file.ContentType, folder);
            var publicUrl = _storageService.GetPublicUrl(filePath);

            _logger.LogInformation("File uploaded successfully: {FilePath}", filePath);

            return Ok(new
            {
                path = filePath,
                url = publicUrl,
                fileName = file.FileName,
                contentType = file.ContentType,
                size = file.Length
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading file");
            return StatusCode(500, new { error = "Error uploading file", details = ex.Message });
        }
    }

    /// <summary>
    /// Sube múltiples archivos
    /// </summary>
    [HttpPost("upload-multiple")]
    public async Task<IActionResult> UploadMultipleFiles(List<IFormFile> files, [FromQuery] string folder = "projects")
    {
        if (files == null || files.Count == 0)
        {
            return BadRequest(new { error = "No files provided" });
        }

        var results = new List<object>();
        var errors = new List<string>();

        foreach (var file in files)
        {
            try
            {
                if (file.Length > 10 * 1024 * 1024)
                {
                    errors.Add($"{file.FileName}: exceeds 10MB limit");
                    continue;
                }

                using var stream = file.OpenReadStream();
                var filePath = await _storageService.UploadFileAsync(stream, file.FileName, file.ContentType, folder);
                var publicUrl = _storageService.GetPublicUrl(filePath);

                results.Add(new
                {
                    path = filePath,
                    url = publicUrl,
                    fileName = file.FileName
                });
            }
            catch (Exception ex)
            {
                errors.Add($"{file.FileName}: {ex.Message}");
            }
        }

        return Ok(new
        {
            uploaded = results,
            errors = errors
        });
    }

    /// <summary>
    /// Elimina un archivo del storage
    /// </summary>
    [HttpDelete("{*filePath}")]
    public async Task<IActionResult> DeleteFile(string filePath)
    {
        try
        {
            var success = await _storageService.DeleteFileAsync(filePath);
            
            if (success)
            {
                return Ok(new { message = "File deleted successfully" });
            }

            return NotFound(new { error = "File not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting file: {FilePath}", filePath);
            return StatusCode(500, new { error = "Error deleting file" });
        }
    }
}
