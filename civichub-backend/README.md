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

Configure the browser origins allowed to call the API:

```powershell
$env:CORS_ALLOWED_ORIGINS="http://localhost:3000,http://localhost:5173"
```

The default local value allows the Vite admin dev origins only. Bearer-token
authentication does not require CORS credentials. The backend exposes
`Content-Disposition` so the admin frontend can read CSV export filenames.

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

When enum values are added to columns backed by PostgreSQL check constraints,
the backend synchronizes the Sprint 3.5 audit action constraint on startup by
default. Set `AUTO_SYNC_AUDIT_LOG_ACTIONS=false` to disable this compatibility
sync.

If you need to apply the change manually, run:

```powershell
psql -h localhost -p 5432 -U $env:DB_USERNAME -d $env:DB_NAME -f src/main/resources/db/manual/20260722_sync_audit_log_action_check.sql
```

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

### Update Current User

`PATCH /api/auth/me`

Requires any authenticated user. Only safe profile fields are accepted:

```json
{
  "fullName": "Nguyen Van A",
  "phone": "0909000000",
  "avatar": "https://example.com/avatar.png"
}
```

The endpoint does not accept role, status, active flag, department, email, or
password updates.

### Change Password

`PATCH /api/auth/change-password`

Requires any authenticated user:

```json
{
  "currentPassword": "old-password",
  "newPassword": "new-password"
}
```

The backend verifies the current password, rejects blank/short/too-long new
passwords, rejects reusing the current password, and never logs password
values. The current MVP does not revoke already-issued JWTs; clients should
logout after a successful password change and sign in again.

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

### User Management

Requires an `ADMIN` JWT:

- `GET /api/admin/users?page=0&size=10&search=staff&role=STAFF&status=ACTIVE&isActive=true&departmentId=1`
- `GET /api/admin/users/export`
- `GET /api/admin/users/{id}`
- `PATCH /api/admin/users/{id}/status`
- `PATCH /api/admin/users/{id}/department`

Change status sample:

```json
{
  "isActive": false
}
```

Rules:

- Responses never include password hashes, refresh tokens, or secrets.
- Deactivating a user sets `isActive=false` and `status=INACTIVE`.
- Activating a user sets `isActive=true` and `status=ACTIVE`.
- Admin cannot deactivate their own admin account.
- Admin cannot deactivate the last active administrator.
- Department assignment is available only for `STAFF` users and only to active departments.
- Role update is intentionally not exposed in Sprint 3.5.

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
- `GET /api/admin/reports/export`
- `GET /api/admin/reports/{id}`
- `PATCH /api/admin/reports/{id}/department`
- `PATCH /api/admin/reports/{id}/status`

Assign department sample:

```json
{
  "departmentId": 1
}
```

Admin can view all reports and assign or reassign an active department. Assignment does not automatically change the report status.

Admin status update uses the same validated workflow as staff status handling:

- `PENDING` -> `RECEIVED` or `REJECTED`
- `RECEIVED` -> `IN_PROGRESS` or `REJECTED`
- `IN_PROGRESS` -> `RESOLVED` or `REJECTED`
- `RESOLVED`, `REJECTED`, and `CANCELLED` are terminal

Successful admin status changes create a citizen notification and write an
audit log. Admin UI must use `/api/admin/reports/{id}/status`, not the staff
endpoint.

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

`summary`, `category`, `department`, and `monthly` accept optional `from` and
`to` query parameters as ISO local date-time strings, for example
`2026-07-01T00:00:00` and `2026-07-31T23:59:59`. If both are provided and
`from` is after `to`, the API returns `400 Bad Request`.

`/recent` returns the latest reports sorted by `createdAt DESC`. The default size is 10.
The React Admin uses `/api/admin/reports` with `createdFrom` and `createdTo`
when it needs date-filtered recent reports, because that endpoint already
supports the same report filters and avoids a duplicate dashboard-specific
query path.

### Staff Dashboard

Requires a `STAFF` JWT and the staff user must belong to an active department:

- `GET /api/staff/dashboard/summary`
- `GET /api/staff/dashboard/recent`
- `GET /api/staff/dashboard/recent?size=10`

Staff dashboard statistics and recent reports are scoped to the staff user's current department. A citizen receives `403 Forbidden`; an anonymous request receives `401 Unauthorized`.

## Notification Center

Sprint 2.7 adds in-app notifications for report workflow events. Notifications are stored in PostgreSQL and are available through authenticated API calls only. Email, SMS, Firebase, Apple Push Notification Service, browser push, WebSocket, Server-Sent Events, Redis, Kafka, scheduled delivery, notification preferences, deletion, and admin broadcast notifications are not included.

### Notification Events

| Event | Type | Citizen recipient | Staff recipient |
| --- | --- | --- | --- |
| Admin assigns or reassigns a report to an active department | `REPORT_ASSIGNED` | Report owner | Active `STAFF` users in the target department |
| Staff changes a report status successfully | `REPORT_STATUS_CHANGED` | Report owner | Not sent |

Assignment notifications are not created when the selected department is unchanged. If a department has no active staff, the assignment still succeeds and the citizen notification is still created.

Status-change notifications are created only after authorization and state-transition validation pass. Invalid transitions, unchanged status, unauthorized staff access, and rolled-back transactions do not leave notifications behind.

### Notification Endpoints

All notification endpoints require:

```http
Authorization: Bearer <accessToken>
```

In Swagger UI, use the `Authorize` button and paste only the raw JWT token.

- `GET /api/notifications?page=0&size=10&unread=true&type=REPORT_ASSIGNED&sortBy=createdAt&direction=DESC`
- `GET /api/notifications/{id}`
- `GET /api/notifications/unread-count`
- `PATCH /api/notifications/{id}/read`
- `PATCH /api/notifications/read`
- `PATCH /api/notifications/read-all`

Supported list filters:

- `unread`: optional boolean
- `type`: `REPORT_ASSIGNED` or `REPORT_STATUS_CHANGED`

Supported sort fields:

- `createdAt`
- `readAt`
- `read`

Default sort is `createdAt DESC`. Page indexes start at `0`, default size is `10`, and maximum size is capped at `100`.

### Ownership Rules

All authenticated roles can use their own notification center:

- `CITIZEN`
- `STAFF`
- `ADMIN`

Users can access only their own notifications. If a notification belongs to another user, the API returns `404 Not Found` to avoid revealing that it exists.

### Read Behavior

`PATCH /api/notifications/{id}/read` is idempotent:

- unread notification: sets `read=true` and writes `readAt`
- already-read notification: returns the current notification and keeps the original `readAt`

`PATCH /api/notifications/read-all` marks all unread notifications owned by the current user as read using a recipient-scoped bulk update and returns `updatedCount`.

`PATCH /api/notifications/read` marks selected unread notifications owned by
the current user as read:

```json
{
  "notificationIds": [1, 2, 3]
}
```

The list must be non-empty, has a maximum of 100 IDs, duplicate IDs are
deduplicated, and IDs belonging to other users are ignored by the
recipient-scoped update.

### Local PostgreSQL Notification Check

Use fake local users only. Do not add insecure APIs solely for changing roles or departments.

Suggested manual flow:

1. Start the backend with the `local` profile and PostgreSQL environment variables.
2. Register a fake ADMIN user, promote it through local-development SQL, then login again.
3. Create an active category and active department.
4. Register and login a fake CITIZEN user.
5. Register a fake STAFF user, assign role `STAFF` and the active department through local-development SQL, then login again.
6. Login as the CITIZEN and create a `PENDING` report.
7. Login as ADMIN and assign the report to the staff department.
8. Confirm the citizen receives `REPORT_ASSIGNED`.
9. Confirm the active staff user receives `REPORT_ASSIGNED`.
10. Login as STAFF and change the report status from `PENDING` to `RECEIVED`.
11. Confirm the citizen receives `REPORT_STATUS_CHANGED`.
12. As the citizen, call `GET /api/notifications`, `GET /api/notifications/unread-count`, `PATCH /api/notifications/{id}/read`, and `PATCH /api/notifications/read-all`.
13. Confirm another authenticated user receives `404 Not Found` when requesting the citizen's notification ID.
14. Confirm invalid status transitions do not create notifications.

## Audit Logging

Sprint 2.8 adds secure append-only audit logging for important business actions. Audit logs are created server-side inside the same transaction as the business operation. There are no public create, update, or delete audit APIs.

Audit logs store scalar snapshots:

- action
- entity type and entity id
- actor id, actor name, and actor role at the time of the action
- safe description
- whitelisted old/new values as JSON text
- created timestamp

Audit logs do not store passwords, password hashes, JWT values, authorization headers, request headers, database credentials, secret keys, full request bodies, stack traces, SQL errors, or private internal exception messages.

### Audited Actions

| Area | Business event | Audit action |
| --- | --- | --- |
| Category | Created | `CATEGORY_CREATED` |
| Category | Updated | `CATEGORY_UPDATED` |
| Category | Activated | `CATEGORY_ACTIVATED` |
| Category | Deactivated | `CATEGORY_DEACTIVATED` |
| Department | Created | `DEPARTMENT_CREATED` |
| Department | Updated | `DEPARTMENT_UPDATED` |
| Department | Activated | `DEPARTMENT_ACTIVATED` |
| Department | Deactivated | `DEPARTMENT_DEACTIVATED` |
| Report | Assigned to a department for the first time | `REPORT_ASSIGNED` |
| Report | Reassigned to another department | `REPORT_REASSIGNED` |
| Report | Status changed by staff or admin | `REPORT_STATUS_CHANGED` |
| Report | Cancelled by citizen | `REPORT_CANCELLED` |
| User | Profile updated by current user | `PROFILE_UPDATED` |
| User | Password changed by current user | `PASSWORD_CHANGED` |
| User | Activated or deactivated by admin | `USER_STATUS_CHANGED` |
| User | Staff department assigned by admin | `USER_DEPARTMENT_CHANGED` |

No audit log is created for invalid report transitions, failed assignments, failed cancellations, unauthorized attempts, or unchanged department assignments.

### Admin Audit Endpoints

Requires an `ADMIN` JWT:

- `GET /api/admin/audit-logs`
- `GET /api/admin/audit-logs/export`
- `GET /api/admin/audit-logs/{id}`

In Swagger UI, use the `Authorize` button and paste only the raw JWT token. For manual clients, use:

```http
Authorization: Bearer <accessToken>
```

List filters:

- `action`: `AuditAction`
- `entityType`: `CATEGORY`, `DEPARTMENT`, `REPORT`, or `USER`
- `entityId`: target entity id
- `actorId`: actor user id snapshot
- `actorRole`: existing `UserRole`
- `createdFrom`: ISO date/time
- `createdTo`: ISO date/time
- `search`: case-insensitive search over `actorName` and `description`

Pagination and sorting:

- `page`: zero-based, default `0`
- `size`: default `20`, capped at `100`
- `sortBy`: `createdAt`, `action`, `entityType`, or `actorName`
- `direction`: `ASC` or `DESC`
- default sort: `createdAt DESC`

If `createdFrom` is after `createdTo`, the API returns `400 Bad Request`. `STAFF` and `CITIZEN` receive `403 Forbidden`; unauthenticated requests receive `401 Unauthorized`.

### Transaction Consistency

Audit logs are saved in the same transaction as the business change:

- if category update fails, no audit log remains
- if department status change fails, no audit log remains
- if report assignment rolls back, no audit log remains
- if report status transition is invalid, no audit log is created

The implementation does not use async processing, a separate transaction, Redis, Kafka, or scheduled cleanup in this sprint.

### Local PostgreSQL Audit Check

Use fake local users only. Do not add insecure APIs solely for manual testing.

Suggested manual flow:

1. Start the backend with the `local` profile and PostgreSQL environment variables.
2. Register a fake ADMIN user, promote it through local-development SQL, then login again.
3. Login as ADMIN and create a category.
4. Update the category.
5. Deactivate and reactivate the category.
6. Create or update a department.
7. Login as a fake CITIZEN and create a report.
8. Login as ADMIN and assign the report to an active department.
9. Reassign the report if another active department exists.
10. Login as STAFF and change the report status through a valid transition.
11. Login as CITIZEN and cancel another eligible `PENDING` report.
12. Login as ADMIN and call `GET /api/admin/audit-logs`.
13. Call `GET /api/admin/audit-logs/{id}` for one record.
14. Verify actions, actor snapshots, entity ids, old/new values, and `createdAt DESC` ordering.
15. Verify STAFF and CITIZEN receive `403 Forbidden`.
16. Verify POST, PUT, and DELETE audit endpoints are not available.

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
