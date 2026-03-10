🔐 Guía de Implementación — Sistema de Login IntegradorHub
Documento de referencia para replicar el sistema de autenticación exactamente como funciona en IntegradorHub, manteniendo congruencia entre proyectos.

Arquitectura General
El sistema usa dos capas:

Capa	Responsabilidad
Firebase Auth	Autenticación real (sesión, token, contraseña, Google OAuth)
Backend C# (.NET 8)	Roles, datos de perfil, lógica de negocio (Firestore como BD)
El frontend/móvil nunca escribe directamente en Firestore. El backend es la única fuente de verdad.

Flujo Completo
[App Móvil / Frontend]
        │
        ▼
1. Firebase.signIn(email, password)
   └── OR signInWithPopup(googleProvider)
        │
        ▼ onAuthStateChanged / resultado del login dispara:
2. POST /api/auth/login
        │
        ▼
   [Backend C#]
   ├── ¿Usuario existe en Firestore? 
   │     SÍ → Sincroniza nombre/foto si faltan, corrige rol si es necesario
   │     NO → Crea usuario nuevo con rol auto-detectado desde el email
        │
        ▼
3. Recibe LoginResponse → leer campo "rol"
        │
        ├── "Docente"    → Pantalla de Docente
        └── "Invitado"   → Pantalla de Invitado
Detección Automática de Rol
El rol se asigna 100% basado en el email. No hay campo de selección de rol.

Patrón de Email	Rol
Nombre.Apellido@utmetropolitana.edu.mx	
Docente
12345678@alumno.utmetropolitana.edu.mx	Alumno
admin*@utmetropolitana.edu.mx	SuperAdmin
Cualquier otro dominio válido	Invitado
Para el proyecto móvil, los dos roles relevantes son 
Docente
 e Invitado.

Endpoint: POST /api/auth/login
Request Body
json
{
  "firebaseUid": "abc123xyzUID",
  "email": "Juan.Perez@utmetropolitana.edu.mx",
  "displayName": "Juan Pérez",
  "photoUrl": "https://lh3.googleusercontent.com/..."
}
Campo	Tipo	Descripción
firebaseUid	string	Requerido. user.uid de Firebase
email	string	Requerido. Email del usuario
displayName	string	Nombre de Firebase ("Usuario" si no tiene)
photoUrl	string?	URL de foto de perfil, puede ser vacío
Response Body
json
{
  "userId": "abc123xyzUID",
  "email": "Juan.Perez@utmetropolitana.edu.mx",
  "nombre": "Juan",
  "rol": "Docente",
  "isFirstLogin": true,
  "grupoId": null,
  "grupoNombre": null,
  "matricula": null,
  "carreraId": null,
  "apellidoPaterno": "Pérez",
  "apellidoMaterno": "García",
  "fotoUrl": "https://...",
  "profesion": "Ing. en Sistemas",
  "especialidadDocente": null,
  "organizacion": null,
  "createdAt": "2026-01-01T00:00:00Z",
  "redesSociales": {}
}
Campos por Rol
Campo	Docente	Invitado
profesion	✅ Tiene valor	❌ null
especialidadDocente	✅ Puede tener	❌ null
organizacion	❌ null	✅ Tiene valor
matricula	❌ null	❌ null
grupoId	❌ null	❌ null
Flag isFirstLogin
Es el detonador para el flujo de onboarding:

isFirstLogin === true
       │
       ▼
Mostrar pantalla de "Completar Perfil"
       │
       ▼
POST /api/auth/register  (ver sección abajo)
       │
       ▼
isFirstLogin === false → App completa
Endpoint: POST /api/auth/register
Se llama solo cuando el usuario es nuevo y necesita completar su perfil.

Request Body — Docente
json
{
  "firebaseUid": "abc123xyzUID",
  "email": "Juan.Perez@utmetropolitana.edu.mx",
  "nombre": "Juan",
  "apellidoPaterno": "Pérez",
  "apellidoMaterno": "García",
  "rol": "Docente",
  "profesion": "Ing. en Sistemas Computacionales",
  "asignaciones": [
    {
      "carreraId": "dsm",
      "materiaId": "mat-prog-avanzada",
      "gruposIds": ["5A", "5B"]
    }
  ],
  "grupoId": null,
  "matricula": null,
  "carreraId": null,
  "organizacion": null
}
Request Body — Invitado
json
{
  "firebaseUid": "abc123xyzUID",
  "email": "visitante@gmail.com",
  "nombre": "Carlos",
  "apellidoPaterno": "López",
  "apellidoMaterno": "Ruiz",
  "rol": "Invitado",
  "organizacion": "Google",
  "asignaciones": null,
  "grupoId": null,
  "matricula": null,
  "carreraId": null,
  "profesion": null
}
Estructura en Firestore
Colección: users — El Document ID = firebaseUid

users/
  └── {firebaseUid}/
        ├── email             (string)
        ├── nombre            (string)
        ├── apellido_paterno  (string)
        ├── apellido_materno  (string)
        ├── rol               (string)   "Docente" | "Invitado" | "Alumno" | "SuperAdmin"
        ├── foto_url          (string?)
        ├── is_first_login    (bool)
        ├── created_at        (string)
        ├── updated_at        (string)
        ├── redes_sociales    (map)
        │
        │   ── Solo Docente ──
        ├── profesion         (string?)
        ├── especialidad_docente (string?)
        ├── asignaciones      (array?)   [{carreraId, materiaId, gruposIds[]}]
        │
        │   ── Solo Invitado ──
        └── organizacion      (string?)
Lógica de Corrección Automática de Rol
El backend corrige el rol en cada login si detecta inconsistencias:

csharp
// Si el email ES de docente pero el rol guardado NO lo es → corrige automáticamente
if (email.DetectedRole == UserRole.Docente && existingUser.Rol != "Docente")
{
    existingUser.Rol = "Docente";
    // Guarda en Firestore
}
Esto garantiza que aunque el dato esté mal en BD, en el siguiente login se corrige solo.

Implementación en Dart/Flutter (Referencia)
dart
// 1. Login con Firebase
final credential = await FirebaseAuth.instance
    .signInWithEmailAndPassword(email: email, password: password);
// 2. Llamar al backend
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'firebaseUid': credential.user!.uid,
    'email': credential.user!.email,
    'displayName': credential.user!.displayName ?? 'Usuario',
    'photoUrl': credential.user!.photoURL ?? '',
  }),
);
// 3. Parsear respuesta
final data = jsonDecode(response.body);
final String rol = data['rol'];           // "Docente" o "Invitado"
final bool isFirstLogin = data['isFirstLogin'];
// 4. Navegar según rol
if (isFirstLogin) {
  Navigator.pushNamed(context, '/complete-profile');
} else if (rol == 'Docente') {
  Navigator.pushNamed(context, '/teacher-dashboard');
} else {
  Navigator.pushNamed(context, '/guest-dashboard');
}
Resumen Ejecutivo para Implementación Móvil
Autentica con Firebase (email+pass o Google)
POST a /api/auth/login con { firebaseUid, email, displayName, photoUrl }
Lee 
rol
 en la respuesta → navega a la pantalla correcta
Si isFirstLogin === true → muestra formulario de perfil y llama a /api/auth/register
Nunca escribas directo a Firestore desde el app — todo pasa por el backend
Documento generado desde el análisis del proyecto IntegradorHub — Marzo 2026


Comment
⌥⌘M
