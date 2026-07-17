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
<accessToken>
```

Because the OpenAPI scheme is HTTP Bearer, paste only the raw token in Swagger. For manual HTTP clients, use `Authorization: Bearer <accessToken>`.

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

## Report Workflow

Sprint 2.6 supports report workflow and dashboard statistics for the MVP. Binary file upload, multipart upload, cloud storage, notification delivery, map integration, and AI are not included.

### Citizen Report Endpoints

Requires a `CITIZEN` JWT:

- `POST /api/reports`
- `GET /api/reports/my?page=0&size=10&status=PENDING&categoryId=1&sortBy=createdAt&direction=DESC`
- `GET /api/reports/my/{id}`
- `PUT /api/reports/my/{id}`
- `PATCH /api/reports/my/{id}/cancel`

Create report sample:

```json
{
  "title": "Broken street light",
  "description": "The street light is not working at night.",
  "address": "123 Main Street",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "categoryId": 1,
  "imageUrls": [
    "https://example.com/report-image-1.jpg"
  ]
}
```

Rules:

- New reports start as `PENDING`.
- Citizens can update or cancel only their own `PENDING` reports.
- Citizens cannot assign departments or change processing status.
- Citizens cannot access another citizen's report.
- `imageUrls` accepts at most 5 URL strings. Each URL is trimmed, must be unique after trimming, and must not exceed 2000 characters.

### Staff Report Endpoints

Requires a `STAFF` JWT and the staff user must belong to a department:

- `GET /api/staff/reports?page=0&size=10&status=RECEIVED&categoryId=1`
- `GET /api/staff/reports/{id}`
- `PATCH /api/staff/reports/{id}/status`

Update status sample:

```json
{
  "status": "IN_PROGRESS"
}
```

Staff can view and update only reports assigned to their own department.

### Admin Report Endpoints

Requires an `ADMIN` JWT:

- `GET /api/admin/reports?page=0&size=10&status=PENDING&assigned=false`
- `GET /api/admin/reports/{id}`
- `PATCH /api/admin/reports/{id}/department`

Assign department sample:

```json
{
  "departmentId": 1
}
```

Admin can view all reports and assign or reassign an active department. Assignment does not automatically change the report status.

## Dashboard API

Dashboard endpoints require a JWT. Aggregations are performed by repository queries using database `COUNT`, `GROUP BY`, and status-based conditional counts. The backend does not load all reports into memory for dashboard statistics.

### Admin Dashboard

Requires an `ADMIN` JWT:

- `GET /api/admin/dashboard/summary`
- `GET /api/admin/dashboard/category`
- `GET /api/admin/dashboard/department`
- `GET /api/admin/dashboard/monthly?year=2026`
- `GET /api/admin/dashboard/recent`
- `GET /api/admin/dashboard/recent?size=10`

`/summary` returns:

- total reports by status: `PENDING`, `RECEIVED`, `IN_PROGRESS`, `RESOLVED`, `REJECTED`, `CANCELLED`
- total citizens
- total staff
- total departments
- total categories

`/monthly` always returns 12 records, one for each month. Months without reports return zero counts.

`/recent` returns the latest reports sorted by `createdAt DESC`. The default size is 10.

### Staff Dashboard

Requires a `STAFF` JWT and the staff user must belong to an active department:

- `GET /api/staff/dashboard/summary`
- `GET /api/staff/dashboard/recent`
- `GET /api/staff/dashboard/recent?size=10`

Staff dashboard statistics and recent reports are scoped to the staff user's current department. A citizen receives `403 Forbidden`; an anonymous request receives `401 Unauthorized`.

### Report Status Lifecycle

Supported statuses:

- `PENDING`
- `RECEIVED`
- `IN_PROGRESS`
- `RESOLVED`
- `REJECTED`
- `CANCELLED`

Staff status transitions:

- `PENDING` -> `RECEIVED`
- `PENDING` -> `REJECTED`
- `RECEIVED` -> `IN_PROGRESS`
- `RECEIVED` -> `REJECTED`
- `IN_PROGRESS` -> `RESOLVED`
- `IN_PROGRESS` -> `REJECTED`

Terminal statuses cannot transition:

- `RESOLVED`
- `REJECTED`
- `CANCELLED`

### Local PostgreSQL Report Workflow Check

Use fake local users only. After changing a user's role or department directly in the database, login again so JWT claims are refreshed.

Local-development-only SQL examples:

```sql
UPDATE users
SET role = 'ADMIN'
WHERE email = 'admin.dev@example.com';

UPDATE users
SET role = 'STAFF',
    department_id = 1
WHERE email = 'staff.dev@example.com';
```

Suggested manual flow:

1. Start with the `local` profile and PostgreSQL environment variables.
2. Register a fake ADMIN user, then promote it using local SQL and login again.
3. Create an active category.
4. Create an active department.
5. Register and login a fake CITIZEN user.
6. Create a report with a category and image URL.
7. List the citizen's reports.
8. Login as ADMIN and assign the report to a department.
9. Register a fake STAFF user, assign role and department using local SQL, then login again.
10. List staff department reports.
11. Move the report through valid statuses and verify invalid transitions return `409`.
12. Verify the citizen cannot edit after the report leaves `PENDING`.

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
