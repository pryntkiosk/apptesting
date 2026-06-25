# Prynt — Admin & Delivery Partner App (Flutter)

Production Android app for the Prynt self-service printing kiosk network. It
connects to the existing Prynt FastAPI + MongoDB backend and adds delivery
operations: kiosk monitoring, automatic low paper/ink alerts, service requests
with first-come claiming, push notifications (FCM), and Google Maps navigation.

## Roles

| Role | Capabilities |
|------|--------------|
| **Admin** (`main` / `regular`) | Full kiosk CRUD, delivery-partner management, manual alerts, dashboard, all service requests. Only `main` admins can delete kiosks. |
| **Delivery Partner** | See available requests, accept (first-come), navigate, update status to in-progress / completed. |

## Architecture (clean, layered)

```
lib/
├── core/                 # cross-cutting concerns
│   ├── config/           # AppConfig (API base url, timeouts)
│   ├── network/          # ApiClient + ApiException
│   ├── storage/          # secure token/user storage
│   ├── theme/            # Material 3 light/dark + ThemeProvider
│   ├── utils/            # maps launcher, formatters
│   └── widgets/          # shared UI (cards, level bars, states)
├── models/               # immutable data models (fromJson)
├── providers/            # ChangeNotifier state (auth, kiosk, partner, request, dashboard)
├── services/             # FcmService (push notifications)
└── features/             # screens grouped by feature
    ├── auth/             # login
    ├── splash/           # session router
    ├── admin/            # dashboard, kiosks, partners, requests
    ├── delivery/         # dashboard, available/assigned requests
    └── common/           # activity feed
```

State management: **Provider**. Networking: **http**. Storage: **flutter_secure_storage**.

## Prerequisites

- Flutter SDK 3.19+ (Dart 3.3+)
- Android Studio / Android SDK (API 34), JDK 17
- A running Prynt backend (this repo's `backend/`)
- A Firebase project (for push) and a Google Maps Android API key

## 1. Configure the backend connection

The app reads the API base URL from a compile-time define (defaults to the
Android emulator host `http://10.0.2.2:8000`).

```bash
# Local backend on your machine, Android emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Physical device on same Wi-Fi (use your PC's LAN IP):
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000

# Production:
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com
```

> All app endpoints live under `/api/mobile`. The client adds that prefix; you
> only supply the host in `API_BASE_URL`.

## 2. Materialize platform binaries (one time)

This repo ships **all source + custom Android config**, but two binary
artifacts can't be delivered as text: the Gradle wrapper jar and the launcher
icon PNGs. Generate them once with Flutter without losing the custom code:

```bash
cd prynt_app
# Regenerates ONLY missing native scaffolding (gradle wrapper, default icons).
flutter create --org com.prynt --project-name prynt_app --platforms=android .
```

`flutter create` will not delete your `lib/` code. If it offers to overwrite
`android/app/build.gradle`, `AndroidManifest.xml`, `MainActivity.kt`, or
`lib/main.dart`, **keep the versions in this repo** (they contain the app
configuration). The only things you need from the regeneration are:
`android/gradle/wrapper/gradle-wrapper.jar`, `android/gradlew`, `gradlew.bat`,
and `android/app/src/main/res/mipmap-*/ic_launcher.png`.

Then install dependencies:

```bash
flutter pub get
```

## 3. Firebase (push notifications)

See **docs/FIREBASE_SETUP.md**. Summary:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

This overwrites `lib/firebase_options.dart` and creates
`android/app/google-services.json`. The Google Services Gradle plugin
auto-activates once that file exists.

> The app is built to **boot even without Firebase** (it logs a warning and
> push is disabled), so you can run and test everything else first.

## 4. Google Maps

Put your **Maps SDK for Android** key in
`android/app/src/main/res/values/strings.xml` (`google_maps_key`). See
docs/FIREBASE_SETUP.md → "Google Maps" for enabling the API.

## 5. Run

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Default admin (seeded by the backend): **admin@prynt.app / admin123**.
Run `python backend/seed_data.py` to add sample partners + kiosks.

## 6. Build an APK

```bash
# Debug APK (quick, for testing)
flutter build apk --debug --dart-define=API_BASE_URL=https://api.yourdomain.com

# Release APK (single, universal)
flutter build apk --release --dart-define=API_BASE_URL=https://api.yourdomain.com

# Smaller, per-ABI release APKs
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://api.yourdomain.com

# Play Store bundle
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.yourdomain.com
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

For **release signing** (required for Play Store / sharing a stable build) see
**docs/DEPLOYMENT.md**.

## Documentation

- `docs/FIREBASE_SETUP.md` — Firebase + FCM + Maps setup
- `docs/DATABASE_SCHEMA.md` — MongoDB collections and fields
- `docs/API_REFERENCE.md` — mobile API endpoints
- `docs/DEPLOYMENT.md` — signing, backend deployment, production checklist
