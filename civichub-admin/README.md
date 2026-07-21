# CivicHub Admin

CivicHub Admin is the React admin frontend for CivicHub. It is built on the existing CoreUI Free React Admin Template v5.6 with React 19, Vite, JavaScript, React Router, and the existing Redux UI state.

## Installation

```bash
npm install
```

## Environment

Copy `.env.example` to `.env` and set the backend URL:

```bash
VITE_API_URL=http://localhost:8080
```

The frontend reads API URLs from `VITE_API_URL`; backend URLs should not be hardcoded in feature code.

## Backend URL

Sprint 3.1 expects the Spring Boot backend to be running at:

```bash
http://localhost:8080
```

## How to Login

Start the frontend:

```bash
npm start
```

Open the app and sign in at `/login` with an existing CivicHub administrator account.

Authentication uses the backend endpoint:

```bash
POST /api/auth/login
```

Request body:

```json
{
  "email": "admin@example.com",
  "password": "password"
}
```

The response is the backend `ApiResponse<AuthResponse>` shape. The frontend uses `data.accessToken` and `data.user`.

## Admin Only

Only users whose role is `ADMIN` can access the admin application. Citizen and Staff accounts are rejected with:

```text
Admin access required.
```

## Current Sprint 3.1 Scope

- Axios API client with JWT request interceptor and 401 session cleanup.
- Auth storage with Remember Me support using localStorage or sessionStorage.
- Auth context and `useAuth` hook.
- CoreUI login page connected to the backend login endpoint.
- Protected admin routes.
- CivicHub Admin branding.
- Sidebar limited to Dashboard, Categories, Departments, Reports, Notifications, and Audit Logs.
- Header shows admin identity, role, theme switcher, and logout.
- Categories, Departments, Reports, Notifications, and Audit Logs currently render a reusable Coming Soon page.

## Verification

```bash
npm run lint
npm run build
```
