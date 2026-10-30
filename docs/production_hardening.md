# MedCare Production Hardening

## Realtime queue

Backend exposes `GET /queue/events` as Server-Sent Events. Flutter opens this stream after backend login and updates `LiveQueueInfo` whenever the doctor or admin calls `POST /queue/call-next`.

## HTTPS deployment

Run the backend behind Caddy:

```powershell
$env:MEDCARE_DOMAIN="your-domain.example.com"
$env:MEDCARE_JWT_SECRET="replace-with-a-long-random-secret"
docker compose up -d --build
```

Caddy terminates HTTPS and proxies API requests to `medcare-api:8080`.

## SQLite at-rest encryption

For a production mobile build, replace the local sqflite database factory with SQLCipher:

1. Add mobile dependencies:

```yaml
dependencies:
  sqflite_sqlcipher: ^3.4.1
  flutter_secure_storage: ^11.2.0
```

2. Generate a random database passphrase on first launch and store it in platform secure storage.
3. Open the mobile database with SQLCipher password.
4. Keep desktop/test fallback on `sqflite_common_ffi`.

This machine currently has Windows Developer Mode disabled, so Flutter cannot create plugin symlinks for validating those packages locally. Enable Developer Mode with `start ms-settings:developers`, run `flutter pub get`, then switch the mobile database open path to SQLCipher before a real release build.

## Device E2E

Minimum real-device smoke flow:

1. Start backend with Docker or `dart run server/bin/server.dart`.
2. Run app with:

```powershell
flutter run --dart-define=MEDCARE_API_BASE_URL=https://your-domain.example.com
```

3. Verify:
   - patient login reaches Home.
   - doctor login reaches EMR workstation.
   - admin login reaches Slot Administration.
   - doctor calls next queue number.
   - patient Live Queue screen receives SSE update without pressing refresh.
   - patient sync succeeds with backend token.

## CI/CD

GitHub Actions runs:

- `flutter analyze`
- `flutter test`
- `dart analyze` in `server`
- `dart test` in `server`
- backend Docker image build
