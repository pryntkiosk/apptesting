# Deployment & Production Guide

## 1. Release signing (Android)

Generate a keystore (once):

```bash
keytool -genkey -v -keystore prynt-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias prynt
```

Create `prynt_app/android/key.properties` (git-ignored):

```properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=prynt
storeFile=/absolute/path/to/prynt-release.jks
```

`android/app/build.gradle` already reads this file and uses it for the
`release` build type (falling back to debug signing if it's absent). Then:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

> After choosing release signing, add the keystore's SHA-1 to your Google Maps
> API key restriction and to the Firebase Android app (Project settings →
> your app → Add fingerprint), otherwise maps/push may fail in release.

## 2. Backend deployment

The mobile features run inside the existing FastAPI app, so deploy as you
already do (e.g. `uvicorn server:app` behind nginx/Kubernetes ingress). New
requirements:

- Env vars: `FCM_SERVICE_ACCOUNT_FILE`, `FCM_PROJECT_ID` (see FIREBASE_SETUP.md).
- The service-account JSON file must be present and readable on the server.
- Outbound HTTPS to `fcm.googleapis.com` must be allowed.
- Set a strong `JWT_SECRET` and a restrictive `CORS_ORIGINS`.

Run example:

```bash
cd backend
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8000
```

Create indexes (see DATABASE_SCHEMA.md) once against your MongoDB.

## 3. Sample data

```bash
cd backend
python seed_data.py
```

Seeds a main admin, a regular admin, two partners, and four kiosks (two of
which are low on paper/ink to demonstrate auto alerts).

| Account | Email | Password | Role |
|---------|-------|----------|------|
| Admin | admin@prynt.app | admin123 | main |
| Manager | manager@prynt.app | manager123 | regular |
| Ravi | ravi@prynt.app | partner123 | delivery |
| Sneha | sneha@prynt.app | partner123 | delivery |

> Change these credentials before going to production.

## 4. Production checklist

- [ ] Strong `JWT_SECRET`; rotate periodically.
- [ ] `CORS_ORIGINS` restricted to known origins.
- [ ] HTTPS everywhere; build the app with an `https://` `API_BASE_URL`.
- [ ] Remove `android:usesCleartextTraffic="true"` from `AndroidManifest.xml`
      once the backend is HTTPS-only.
- [ ] Replace default seed credentials.
- [ ] FCM service account stored as a secret (not in the repo/image layer).
- [ ] Google Maps key restricted to the app's package + signing SHA-1.
- [ ] MongoDB indexes created.
- [ ] Crash/error monitoring on the backend.

## 5. Smoke test after deploy

1. Log in as admin → dashboard loads counts.
2. Create a kiosk with coordinates → appears in list.
3. Tap **Paper Refill** → partner receives push, request appears under
   Available.
4. Partner **Accept** → moves to My Tasks, admin sees assignee.
5. Partner **Start → Complete** → admin notified, kiosk paper restored.
6. Toggle theme (light/dark) persists across restarts.
