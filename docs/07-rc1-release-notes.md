# CivicHub RC1 Release Notes

RC1 freezes the CivicHub platform before AI-related work begins. This release
contains the production-ready baseline for the backend, Citizen/Staff Flutter
app, and React Admin portal.

## Scope

- Backend authentication, authorization, reports, categories, departments,
  notifications, audit logging, dashboard summaries, and database compatibility.
- Citizen app authentication, home, reports, profile, notifications, report
  create/edit/detail, location picker, and personal report map.
- Staff workspace dashboard, assigned work queue, report detail, status
  workflow, notifications, profile, and department-scoped report map.
- Admin portal dashboard, users, categories, departments, reports, notifications,
  audit logs, profile, and report map view.

## Production Workflow Gate

The RC1 acceptance workflow is:

1. Citizen signs in.
2. Citizen creates a report with address and optional map coordinates.
3. Admin assigns the report to an active department.
4. Staff in that department sees the report in the assigned queue.
5. Staff moves the report through the valid workflow.
6. Citizen receives notifications and sees updated report status.
7. Citizen and Staff detail screens show the same report location.

## Environment Variables

Backend production:

- `SPRING_PROFILES_ACTIVE=prod`
- `JWT_SECRET`
- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USERNAME`
- `DB_PASSWORD`
- `CORS_ALLOWED_ORIGIN_PATTERNS`

Flutter staging/production:

- `APP_ENV=staging|production`
- `API_BASE_URL=https://<backend-origin>`
- `CIVICHUB_MAP_TILE_URL=https://<approved-tile-template>` when not using the
  default OpenStreetMap tile URL.

React Admin production:

- `VITE_API_URL=https://<backend-origin>`
- `VITE_MAP_TILE_URL=https://<approved-tile-template>` when configured.

## Build Commands

Backend:

```powershell
mvn test
```

Flutter:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com
flutter build web --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com
```

React Admin:

```powershell
$env:VITE_API_URL='https://api.example.com'
npm run build
Remove-Item Env:\VITE_API_URL
```

## Known Issues

- Android release signing and store assets remain external release tasks.
- iOS signing/provisioning must be completed on macOS.
- Public OpenStreetMap tiles are acceptable for development and demos, but a
  production tile provider or cache should be configured before heavy traffic.
- Flutter Web emits wasm dry-run warnings from `flutter_secure_storage_web`;
  JavaScript web builds pass.
- No automated browser E2E suite currently validates the full
  Citizen-to-Admin-to-Staff-to-Citizen loop against a live database.
- Admin status transition options are duplicated in React presentation code and
  backend workflow rules.

## RC1 Checklist

- [x] Backend tests pass.
- [x] Flutter analyze passes.
- [x] Flutter tests pass.
- [x] Flutter Android release build passes.
- [x] Flutter Web build passes.
- [x] React Admin production build passes with `VITE_API_URL`.
- [x] Debug/demo report fixtures removed from production Flutter code.
- [x] Production-facing placeholder copy reviewed.
- [x] GIS maps are labeled as current loaded scope, not city-wide analytics.
- [x] No commit or push performed by Codex.
