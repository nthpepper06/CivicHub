# CivicHub Admin Development

## Local Setup

1. Start the backend from `../civichub-backend`.
2. Copy `.env.example` to `.env`.
3. Set `VITE_API_URL=http://localhost:8080`.
4. Run `npm install`.
5. Run `npm start`.

## Scripts

```bash
npm start
npm run lint
npm run build
npm run serve
```

There is no frontend test script configured in `package.json` at this time.

## Architecture

- API wrappers live in `src/api`.
- Auth state lives in `src/auth/AuthContext.jsx`.
- Auth storage helpers live in `src/utils/authStorage.js`.
- Shared admin states and dialogs live in `src/components/admin`.
- Protected route components are registered in `src/routes.js`.
- Sidebar items are registered in `src/_nav.jsx`.

Keep feature code using service wrappers instead of hardcoding backend URLs or
duplicating Axios calls in views.

## Backend Contracts

Use only endpoints that exist in the backend source. Current admin frontend
features use:

- `POST /api/auth/login`
- `GET /api/auth/me`
- `PATCH /api/auth/me`
- `PATCH /api/auth/change-password`
- `GET /api/admin/dashboard/*`
- `GET /api/admin/users`
- `GET /api/admin/users/export`
- `GET /api/admin/users/{id}`
- `PATCH /api/admin/users/{id}/status`
- `PATCH /api/admin/users/{id}/department`
- `GET /api/admin/categories`
- `POST /api/admin/categories`
- `PUT /api/admin/categories/{id}`
- `PATCH /api/admin/categories/{id}/status`
- `GET /api/admin/departments`
- `POST /api/admin/departments`
- `PUT /api/admin/departments/{id}`
- `PATCH /api/admin/departments/{id}/status`
- `GET /api/admin/reports`
- `GET /api/admin/reports/export`
- `GET /api/admin/reports/{id}`
- `PATCH /api/admin/reports/{id}/department`
- `PATCH /api/admin/reports/{id}/status`
- `GET /api/notifications`
- `GET /api/notifications/unread-count`
- `PATCH /api/notifications/{id}/read`
- `PATCH /api/notifications/read`
- `PATCH /api/notifications/read-all`
- `GET /api/admin/audit-logs`
- `GET /api/admin/audit-logs/export`
- `GET /api/admin/audit-logs/{id}`

Remaining unsupported backend features:

- Report priority update endpoint
- Dedicated report history endpoint; the admin UI reuses Audit Logs for report timeline
- Backend CSV export for Categories, Departments, and Notifications

Dashboard date filters use local date-time strings such as
`YYYY-MM-DDT00:00:00` and `YYYY-MM-DDT23:59:59`; do not construct them with
`new Date(dateInput).toISOString()` because that can shift dates by timezone.
The Dashboard recent list intentionally uses `GET /api/admin/reports` with
`createdFrom` and `createdTo` so date-range filtering is applied by the existing
reports API; `/api/admin/dashboard/recent` remains the simple unfiltered recent
endpoint.

## Production Notes

- `.env` must not be committed.
- `VITE_API_URL` must be set for production.
- Do not put JWT secrets or database credentials in the frontend.
- Unknown routes render the admin 404 page.
- The backend remains responsible for role enforcement; UI checks are only a
  convenience layer.
