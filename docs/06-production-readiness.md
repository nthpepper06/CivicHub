# CivicHub Production Readiness

This checklist records production-readiness gates for the backend, Flutter
Citizen/Staff mobile app, and React Admin.

## Runtime Contract

- Backend API base: configure per environment.
- Flutter mobile/web: pass `--dart-define=APP_ENV=<development|staging|production>` and `--dart-define=API_BASE_URL=<https backend origin>` for staging and production release builds.
- React Admin: set `VITE_API_URL=<https backend origin>` for every non-development build.
- Local development defaults remain:
  - Flutter Web: `http://localhost:8080`
  - Android emulator: `http://10.0.2.2:8080`
  - React Admin dev: relative API URL unless `VITE_API_URL` is supplied
- Flutter product builds fail safely at runtime if `API_BASE_URL` is omitted, preventing accidental localhost/emulator release configuration.
- React Admin production builds fail when `VITE_API_URL` is omitted or points to localhost, unless `CIVICHUB_ALLOW_LOCAL_API_FOR_BUILD=true` is set for a local smoke test.

## Release Identity

- Android namespace: `com.civichub.mobile`
- Android application id: `com.civichub.mobile`
- Android app label: `CivicHub`
- iOS bundle identifier: `com.civichub.mobile`
- iOS display name: `CivicHub`
- Flutter web title and manifest name: `CivicHub`

## End-To-End Workflow Gate

1. Citizen signs in and creates a report.
2. Admin signs in and assigns an active department.
3. Staff signs in with a user assigned to that department.
4. Staff moves the report through `RECEIVED -> IN_PROGRESS -> RESOLVED`.
5. Citizen notification list shows the status-change notification.
6. Citizen report detail and list show the updated status after refresh.

## Shared Status Contract

Report statuses must remain synchronized across backend, Flutter, and React Admin:

- `PENDING`
- `RECEIVED`
- `IN_PROGRESS`
- `RESOLVED`
- `REJECTED`
- `CANCELLED`

Notification types currently supported:

- `REPORT_ASSIGNED`
- `REPORT_STATUS_CHANGED`

## GIS And Location

- Report create/update/detail contracts support `address`, `latitude`, and
  `longitude`.
- Report list responses include nullable coordinates for Citizen, Staff, and
  Admin map views.
- Maps must label their scope as loaded/current results unless a future backend
  endpoint returns a complete GIS dataset.
- Invalid or missing coordinates are excluded; reports must never be placed at
  `0,0` as a fallback.
- Configure `CIVICHUB_MAP_TILE_URL` for Flutter or `VITE_MAP_TILE_URL` for React
  Admin when using an approved production tile provider.
- Public OpenStreetMap tiles are not intended for heavy production traffic.

## Release Gates

- Backend `mvn test` passes.
- Flutter `flutter analyze`, `flutter test`, `flutter build apk --release`, and `flutter build web` pass.
- React Admin `npm run build` passes with `VITE_API_URL` configured for production.
- `git diff --check` passes in each repository.
- Database compatibility synchronization has run successfully on the target database.
- CORS allowed origins are environment-appropriate.
- JWT secret, database credentials, and frontend API URLs are not committed to source control.

## Build Commands

Development Flutter:

```powershell
flutter run --dart-define=APP_ENV=development
```

Production Flutter Android:

```powershell
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com
```

Production Flutter Web:

```powershell
flutter build web --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com
```

React Admin production build:

```powershell
$env:VITE_API_URL='https://api.example.com'
npm run build
Remove-Item Env:\VITE_API_URL
```

Backend production profile:

```powershell
$env:SPRING_PROFILES_ACTIVE='prod'
$env:JWT_SECRET='<minimum-32-character-secret>'
$env:DB_HOST='<postgres-host>'
$env:DB_PORT='5432'
$env:DB_NAME='civichub'
$env:DB_USERNAME='<database-user>'
$env:DB_PASSWORD='<database-password>'
$env:CORS_ALLOWED_ORIGIN_PATTERNS='https://admin.example.com,https://app.example.com'
mvn spring-boot:run
```

## Signing And Deployment Notes

- Android release signing still needs a production keystore and `signingConfig` wiring before Play Store release.
- iOS release signing, team id, provisioning profile, and App Store bundle registration must be completed on macOS.
- Production backend must run with `SPRING_PROFILES_ACTIVE=prod`.
- Production CORS origin patterns must be explicit deployed origins, not localhost.
- Production JWT secret must be supplied through the deployment environment.

## Known Release Risks

- Launcher icons and splash artwork still use generated Flutter assets; replace with approved CivicHub brand assets before store submission.
- React Admin intentionally fails production builds if `VITE_API_URL` is omitted or points to localhost.
- Flutter Web build emits wasm dry-run warnings from `flutter_secure_storage_web`; JavaScript web builds still pass.
- Admin status transitions are duplicated in React presentation code and backend service rules.
- No automated browser-driven full E2E test currently validates the complete Citizen -> Admin -> Staff -> Citizen loop against a live database.
- Public OpenStreetMap tile usage must be replaced or approved before high-traffic production deployment.
