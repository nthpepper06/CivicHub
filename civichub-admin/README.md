# CivicHub Admin

CivicHub Admin is the React admin console for CivicHub. It uses React, Vite,
React Router, Axios, and CoreUI components, but the reachable routes and sidebar
are limited to CivicHub modules.

## Requirements

- Node.js 18 or newer
- npm
- CivicHub backend running separately

## Environment

Create a local `.env` from `.env.example`:

```bash
VITE_API_URL=http://localhost:8080
```

`.env` is ignored by Git. Do not place JWTs, passwords, or backend secrets in
frontend env files. Production builds must provide `VITE_API_URL` for the real
API origin.

## Run

```bash
npm install
npm start
```

The dev server runs on `http://localhost:3000`. API requests use
`VITE_API_URL`; the Vite proxy also points `/api` at the same backend URL.

## Build

```bash
npm run lint
npm run build
```

Preview a production build:

```bash
npm run serve
```

## Backend

Start the Spring Boot backend from `../civichub-backend`:

```bash
.\mvnw.cmd spring-boot:run
```

Backend tests:

```bash
.\mvnw.cmd test
```

Use local fake test accounts only. Do not document or commit real passwords.

## Admin Modules

- Dashboard
- Users
- Categories
- Departments
- Reports
- Notifications
- Audit Logs
- Admin Profile

Sprint 3.5 connects the admin UI to backend APIs for user management, profile
update, change password, admin report status workflow, dashboard date-range
analytics, backend CSV export, and selected notification mark-read.

Backend CSV export is used for Reports, Users, and Audit Logs and keeps the
current filters. Categories, Departments, and Notifications still use
current-page CSV export because backend export endpoints are not defined for
those modules.

Changing password logs out the frontend and asks the user to sign in again.
The backend does not yet implement JWT revocation, so previously issued JWTs
may remain technically valid until their normal expiry.
