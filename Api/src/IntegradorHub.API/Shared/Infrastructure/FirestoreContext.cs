using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Infrastructure;

public class FirestoreContext
{
    private static FirestoreDb? _db;
    private static readonly object _lock = new();
    
    public static FirestoreDb GetDatabase()
    {
        if (_db is null)
        {
            lock (_lock)
            {
                if (_db is null)
                {
                    // 1. Intentar cargar desde archivo local (Desarrollo)
                    var localCredentialsPath = Path.Combine(
                        Directory.GetCurrentDirectory(), 
                        "..", "..", "..",
                        "integradorhub-dsm-firebase-adminsdk-fbsvc-d89dd8625c.json"
                    );
                    
                    if (File.Exists(localCredentialsPath))
                    {
                        Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", localCredentialsPath);
                    }
                    else 
                    {
                        // 2. Intentar cargar desde variable de entorno con el JSON directo (Producción - Render/Railway)
                        var jsonCredentials = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON");
                        if (!string.IsNullOrEmpty(jsonCredentials))
                        {
                            var tempFile = Path.GetTempFileName();
                            File.WriteAllText(tempFile, jsonCredentials);
                            Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", tempFile);
                        }
                    }
                    
                    var projectId = Environment.GetEnvironmentVariable("FIREBASE_PROJECT_ID") 
                                    ?? "integradorhub-dsm";
                    
                    _db = FirestoreDb.Create(projectId);
                }
            }
        }
        
        return _db;
    }
    
    // Colecciones
    public static CollectionReference Users => GetDatabase().Collection("users");
    public static CollectionReference Projects => GetDatabase().Collection("projects");
    public static CollectionReference Groups => GetDatabase().Collection("groups");
    public static CollectionReference Materias => GetDatabase().Collection("materias");
    public static CollectionReference Evaluations => GetDatabase().Collection("evaluations");
}
