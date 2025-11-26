# Inventario de Autos — README

## Introducción

Hola — este repositorio contiene una pequeña aplicación Angular que muestra un inventario de coches (autos). La idea es tener una página limpia y funcional donde puedas listar, buscar, crear, editar y eliminar coches usando una API REST simple (aquí usamos `json-server` para desarrollo). Este README explica cómo se hizo la aplicación, qué hace cada parte y los comandos útiles para crear el proyecto, servicios y componentes.

## Resumen de la app

- Qué muestra: una lista de autos en tarjetas (cards) con imagen, marca, modelo, año y precio.
- Qué puedes hacer: buscar autos (debounce + cancelación de peticiones), crear nuevos autos, editar existentes y eliminarlos. Las operaciones usan `http://localhost:3000/autos` y son CRUD completas (GET/POST/PUT/DELETE).
- Backend de desarrollo: `json-server` sirve `src/data/db.json` en `http://localhost:3000`.

## Arquitectura y archivos importantes

- `src/app/services/autos.service.ts` — Servicio Angular que encapsula las llamadas HTTP a la API (`list`, `get`, `create`, `update`, `delete`). Apunta a `http://localhost:3000/autos`.
- `src/app/components/auto-list/auto-list.ts` + `.html` + `.css` — Componente principal que muestra la grilla de autos, barra de búsqueda, filtros y botones de acción. Gestiona la recarga automática tras crear/editar/eliminar y usa guards SSR (`isPlatformBrowser`) para evitar llamadas desde el servidor.
- `src/app/components/auto-form/auto-form.ts` + `.html` + `.css` — Componente standalone que contiene el formulario de creación/edición. Es “tonto”: emite `save` y `cancel` y no accede al servicio HTTP directamente.
- `src/data/db.json` — Datos de muestra consumidos por `json-server`.
- `src/app/app.config.ts` — Configuración de bootstrap; incluye `provideHttpClient(withFetch())` para compatibilidad con fetch/SSR.

## Características implementadas

- CRUD completo contra `http://localhost:3000/autos` usando `HttpClient`.
- Búsqueda del lado del servidor con `?q=` (json-server) y debounce (300ms) + cancelación de solicitudes previas (`switchMap`).
- Auto-refresh: después de `create`, `update` o `delete` hacemos `loadAutos()` para mostrar el estado real del servidor.
- Formulario separado: `AutoForm` es un componente independiente usado por `AutoList` dentro de un modal centrado.
- Modal centrado con overlay; clic fuera o `Cancelar` cierra el modal.
- Iconos SVG inline para editar/eliminar en vez de emojis, y estilos modernos para tarjetas (hover, sombras, responsive).
- SSR-safety: evitamos llamadas HTTP en el servidor y errores por objetos solo disponibles en el navegador.

## Requisitos previos

- Node.js (recomendado 18+ para tener `fetch` nativo en SSR; si usas Node < 18, añade polyfill de `fetch`).
- npm (o pnpm/yarn según prefieras).

## Instalación y ejecución (desarrollo)

1. Instala dependencias:

```powershell
npm install
```

2. Instala `json-server` (si no lo tienes global):

```powershell
npx json-server --version  # prueba si está disponible
npm i -D json-server
```

3. Inicia el backend de desarrollo (`json-server`) que sirve `src/data/db.json`:

```powershell
npx json-server --watch src/data/db.json --port 3000
```

4. Inicia la app Angular (dev server):

```powershell
npm start
# o
# ng serve
```

5. Abre el navegador en la URL que muestra `ng serve` (p. ej. `http://localhost:4200` o la URL indicada en la salida).

## Comprobaciones rápidas de la API

GET listado de autos:

```powershell
curl http://localhost:3000/autos
# o en PowerShell
Invoke-RestMethod http://localhost:3000/autos
```

Crear (POST) ejemplo:

```powershell
curl -X POST http://localhost:3000/autos -H "Content-Type: application/json" -d '{"make":"Test","model":"X","year":2024, "price":10000}'
```

## Comandos útiles (crear proyecto, servicios y componentes)

Los siguientes comandos son ejemplos usando Angular CLI (`ng`). Si no usaste CLI originalmente, estos comandos muestran la forma estándar de generar archivos.

- Crear un nuevo proyecto Angular:

```powershell
ng new my-autos-app --standalone --routing=false --style=css
cd my-autos-app
```

- Generar un servicio (AutosService):

```powershell
ng generate service src/app/services/autos --skip-tests
```

Dentro de `autos.service.ts` implementa los métodos básicos usando `HttpClient`:

- Generar un componente standalone para la lista (AutoList):

```powershell
ng generate component src/app/components/auto-list --standalone --skip-tests
```

- Generar un componente standalone para el formulario (AutoForm):

```powershell
ng generate component src/app/components/auto-form --standalone --skip-tests
```

Notas sobre los comandos: los flags `--standalone` crean componentes que no necesitan NgModule; `--skip-tests` evita generar archivos de test si no los quieres.

## Implementación técnica (resumen)

- `AutosService` contiene métodos similares a:

```ts
list(params?: any): Observable<Auto[]> { return this.http.get<Auto[]>(this.baseUrl, { params }); }
get(id: string) { return this.http.get<Auto>(`${this.baseUrl}/${id}`); }
create(a: Auto) { return this.http.post<Auto>(this.baseUrl, a); }
update(id: string, a: Auto) { return this.http.put<Auto>(`${this.baseUrl}/${id}`, a); }
delete(id: string) { return this.http.delete(`${this.baseUrl}/${id}`); }
```

- `AutoList`:

  - Llama `loadAutos()` en `ngOnInit()` (pero sólo en el navegador usando `isPlatformBrowser`).
  - Maneja `searchControl` con `valueChanges.pipe(debounceTime(300), distinctUntilChanged(), switchMap(...))` para búsqueda eficiente.
  - Muestra modal con `<app-auto-form>` al crear/editar.
  - Tras `save` del formulario ejecuta `create` o `update` y luego `loadAutos()` para refrescar la vista.

- `AutoForm`:
  - Componente pequeño que gestiona la UI del formulario y emite `save` con los datos.
  - Validaciones simples (required, min year, min price).

## Decisiones y pequeñas notas

- Usamos `provideHttpClient(withFetch())` en bootstrap para aprovechar `fetch` en entornos modernos y mejorar compatibilidad con Angular SSR.
- Evitamos referencias a objetos sólo disponibles en el navegador durante SSR (por ejemplo `ErrorEvent`) para no romper el servidor.
- El front está pensado para desarrollo rápido con `json-server`. Para producción deberías reemplazarlo por una API real y añadir autenticación, control de errores mejorado y validaciones server-side.

## Mejoras posibles (siguientes pasos)

- Notificaciones (toasts) para éxito/fracaso de operaciones.
- Modal con focus-trap y cierre con `Escape` para accesibilidad.
- Paginación y filtros reales en servidor para escalabilidad.
- Subida de imágenes (file upload) y almacenamiento en CDN.

## Contacto y notas finales

Si quieres que convierta el formulario en modal con focus-trap y cierre por `Escape`, o que añada toasts para feedback de usuario, lo implemento enseguida.

Gracias — disfruta probando el inventario de autos.

# ApiAngular

This project was generated using [Angular CLI](https://github.com/angular/angular-cli) version 20.3.8.

## Development server

To start a local development server, run:

```bash
ng serve
```

Once the server is running, open your browser and navigate to `http://localhost:4200/`. The application will automatically reload whenever you modify any of the source files.

## Code scaffolding

Angular CLI includes powerful code scaffolding tools. To generate a new component, run:

```bash
ng generate component component-name
```

For a complete list of available schematics (such as `components`, `directives`, or `pipes`), run:

```bash
ng generate --help
```

## Building

To build the project run:

```bash
ng build
```

This will compile your project and store the build artifacts in the `dist/` directory. By default, the production build optimizes your application for performance and speed.

## Running unit tests

To execute unit tests with the [Karma](https://karma-runner.github.io) test runner, use the following command:

```bash
ng test
```

## Running end-to-end tests

For end-to-end (e2e) testing, run:

```bash
ng e2e
```

Angular CLI does not come with an end-to-end testing framework by default. You can choose one that suits your needs.

## Additional Resources

For more information on using the Angular CLI, including detailed command references, visit the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.
