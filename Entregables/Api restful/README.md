# API financiera: tarjetas de credito

API REST con Node.js, TypeScript estricto y PostgreSQL. Incluye usuarios y tarjetas de ejemplo; las tarjetas se eliminan logicamente.

## Requisitos

- Node.js 20 o superior y npm.
- Docker Desktop con Docker Compose, o una instancia PostgreSQL 13 o superior.

## Inicio recomendado

Desde la carpeta del proyecto, ejecuta:

```powershell
docker compose up --build
```

Compose inicia PostgreSQL, crea el esquema, carga los datos de ejemplo e inicia la API. La primera compilacion puede tardar unos minutos. Al terminar, la API queda en `http://localhost:3000`. Para detenerla, usa `Ctrl+C`; los datos persisten en el volumen `postgres_data`.

Para detener y eliminar tambien los datos de ejemplo persistidos:

```powershell
docker compose down -v
```

## Inicio con PostgreSQL instalado localmente

1. Crea la base `credit_cards` y un usuario con acceso. Los valores predeterminados son `app` / `app`; puedes cambiarlos con `DATABASE_URL`.
2. Copia `.env.example` a `.env` y ajusta `DATABASE_URL` a tu instancia.
3. Ejecuta `npm install`, luego `npm run db:setup` para crear las tablas y cargar los datos iniciales.
4. Ejecuta `npm run dev` para iniciar la API con recarga automatica.

`npm run build` compila el proyecto y `npm run typecheck` verifica los tipos.

## Endpoints

Base URL: `http://localhost:3000/api/v1/credit-cards`

| Metodo | Ruta | Respuesta |
| --- | --- | --- |
| GET | `/` | `200` y array de tarjetas activas no eliminadas |
| POST | `/` | `201` y tarjeta creada; `400` si faltan datos o son invalidos; `404` si el usuario no existe |
| GET | `/:id` | `200` con la tarjeta o `404` si no existe |
| PATCH | `/:id` | `200` con la tarjeta actualizada; acepta `creditLimit`, `status` o ambos |
| DELETE | `/:id` | `204` sin contenido; registra `deleted_at`, no borra la fila |

Los errores tienen forma `{ "error": { "message": "..." } }`. Los montos deben ser positivos. `status` acepta `active` o `blocked`. El listado solo devuelve tarjetas activas.

### Datos de ejemplo

Usuarios disponibles:

| Nombre | userId |
| --- | --- |
| Ana Garcia | `11111111-1111-4111-8111-111111111111` |
| Luis Perez | `22222222-2222-4222-8222-222222222222` |
| Maria Lopez | `33333333-3333-4333-8333-333333333333` |

La tarjeta `aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa` pertenece a Ana y tiene limite `5000.00`; tambien hay una tarjeta activa de Luis y una bloqueada de Maria.

### Crear una tarjeta con cURL

```powershell
curl.exe -X POST http://localhost:3000/api/v1/credit-cards `
  -H "Content-Type: application/json" `
  -d '{"userId":"11111111-1111-4111-8111-111111111111","creditLimit":8500.75}'
```

## Postman

Importa `postman/credit-cards.postman_collection.json`. La coleccion trae las cinco operaciones y variables configuradas. Ejecuta POST para guardar el ID nuevo en `cardId`; luego prueba GET por ID, PATCH y DELETE. El DELETE responde `204` sin cuerpo; repetirlo da `404`.
