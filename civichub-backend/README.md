# CivicHub Backend

Spring Boot backend for the CivicHub MVP.

## Local PostgreSQL Configuration

The main application uses PostgreSQL. Configure these environment variables before starting the backend:

- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USERNAME`
- `DB_PASSWORD`

Do not commit real database passwords.

Start the backend:

```powershell
.\mvnw.cmd spring-boot:run
```

For a newly created local PostgreSQL database, run the backend with the `local` profile so Hibernate can create/update tables during development:

```powershell
$env:SPRING_PROFILES_ACTIVE="local"
.\mvnw.cmd spring-boot:run
```

The `local` profile uses `spring.jpa.hibernate.ddl-auto=update` for local development only. The default application configuration keeps `ddl-auto=none` and should remain the safer baseline for shared or production environments.

Swagger UI:

```text
http://localhost:8080/swagger-ui.html
```

## Authentication API

### Register

`POST /api/auth/register`

Sample request:

```json
{
  "fullName": "Nguyen Van A",
  "email": "citizen@example.com",
  "password": "strongPassword",
  "phone": "0909000000"
}
```

Successful response uses HTTP `201 Created` and returns an access token.

### Login

`POST /api/auth/login`

Sample request:

```json
{
  "email": "citizen@example.com",
  "password": "strongPassword"
}
```

Successful response uses HTTP `200 OK` and returns an access token.

### Current User

`GET /api/auth/me`

Requires an access token:

```http
Authorization: Bearer <accessToken>
```

The endpoint returns safe profile fields only. It does not return password hashes or internal security details.

## Category API

### Public Active Categories

`GET /api/categories`

This endpoint is public and returns only active categories, sorted by name ascending.

## Admin APIs

Admin endpoints require:

```http
Authorization: Bearer <accessToken>
```

In Swagger UI, use the `Authorize` button and paste:

```text
Bearer <accessToken>
```

### Category Management

- `GET /api/admin/categories?page=0&size=10&search=traffic&isActive=true`
- `GET /api/admin/categories/{id}`
- `POST /api/admin/categories`
- `PUT /api/admin/categories/{id}`
- `PATCH /api/admin/categories/{id}/status`

Create category sample:

```json
{
  "name": "Traffic",
  "description": "Traffic and road issues",
  "icon": "traffic"
}
```

Change status sample:

```json
{
  "isActive": false
}
```

### Department Management

- `GET /api/admin/departments?page=0&size=10&search=urban&isActive=true`
- `GET /api/admin/departments/{id}`
- `POST /api/admin/departments`
- `PUT /api/admin/departments/{id}`
- `PATCH /api/admin/departments/{id}/status`

Create department sample:

```json
{
  "name": "Urban Services",
  "description": "Handles local civic service issues"
}
```

## Local Development Admin Setup

A newly registered user is always `CITIZEN`. CivicHub does not provide an insecure API to promote users to `ADMIN`.

For local development only, after registering a known fake test account, you may update its role manually in PostgreSQL:

```sql
UPDATE users
SET role = 'ADMIN'
WHERE email = 'admin.dev@example.com';
```

Use fake local accounts only. Do not run this against production data.

## Production Hardening Notes

Before production, add database-level case-insensitive unique indexes for category and department names through the project's migration mechanism:

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uk_categories_name_lower
ON categories (LOWER(name));

CREATE UNIQUE INDEX IF NOT EXISTS uk_departments_name_lower
ON departments (LOWER(name));
```

The current MVP service layer already performs case-insensitive duplicate checks. Database indexes are still recommended before production to protect against concurrent inserts.

## JWT

- Token type: `Bearer`
- Expiration unit in API responses: seconds
- Expiration source: `app.jwt.expiration-ms` / `JWT_EXPIRATION_MS`
- JWT subject: user email
- JWT claims: `userId`, `role`
- Production secrets must be supplied through environment variables. Do not commit real secrets.
