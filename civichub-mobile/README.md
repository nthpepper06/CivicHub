# CivicHub Mobile

Flutter Citizen App for CivicHub.

## Requirements

- Flutter SDK installed
- Android emulator or physical device
- CivicHub backend running locally

## Setup

```bash
flutter pub get
```

## Run on Android Emulator

Use `10.0.2.2` for the backend host when running on the Android emulator.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

If your backend runs on a different port, change the URL accordingly.

## Backend

- Default backend port: `8080`
- Auth login endpoint: `POST /api/auth/login`
- Current user endpoint: `GET /api/auth/me`
- Citizen App only accepts users with role `CITIZEN`.
- There is no backend logout endpoint; logout clears the local access token.
- There is no refresh-token flow in the current backend contract.

## Notes

- `API_BASE_URL` is read from `--dart-define`.
- Debug builds allow cleartext HTTP only for development.
- Token storage uses `flutter_secure_storage`.
- No API secrets or passwords are stored in this repository.
- The login endpoint is public and does not attach an existing JWT.
- Protected API requests attach `Authorization: Bearer <token>` when a token is available.
- A `401` from protected API requests clears the token and returns the app to Login.
- If session bootstrap fails because of network, timeout, or temporary server failure, the app stays on Splash with Retry and keeps the stored token.

## Validation

```bash
dart format .
flutter analyze
flutter test
flutter build apk --debug
```
