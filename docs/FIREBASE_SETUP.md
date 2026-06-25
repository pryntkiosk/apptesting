# Firebase, FCM & Google Maps Setup

This guide wires push notifications and maps for the Prynt app.

## A. Create the Firebase project

1. Go to https://console.firebase.google.com and **Add project**.
2. Disable Google Analytics if you don't need it (optional).

## B. Register the Android app

1. In the project, **Add app → Android**.
2. **Android package name:** `com.prynt.app` (must match exactly).
3. Download **google-services.json** and place it at:
   `prynt_app/android/app/google-services.json`
   (A `.template` is provided showing the required structure.)

The Gradle build auto-detects this file and enables the Google Services plugin.

## C. Generate Dart Firebase options

Use the FlutterFire CLI so `lib/firebase_options.dart` matches your project:

```bash
dart pub global activate flutterfire_cli
cd prynt_app
flutterfire configure --project=<your-firebase-project-id>
```

Select **Android** when prompted. This overwrites `lib/firebase_options.dart`
with real values.

## D. Backend: enable sending (FCM HTTP v1)

The backend sends pushes using a **service account**.

1. Firebase Console → **Project settings → Service accounts →
   Generate new private key**. A JSON file downloads.
2. Place it somewhere readable by the backend, e.g.
   `backend/firebase-service-account.json` (do NOT commit it).
3. Set env vars in `backend/.env`:

   ```dotenv
   FCM_SERVICE_ACCOUNT_FILE=/absolute/path/to/firebase-service-account.json
   FCM_PROJECT_ID=your-firebase-project-id
   ```

4. Restart the backend. On startup you'll see `FCM configured for project ...`.

> Without these vars the backend **logs** notifications instead of sending them,
> so development works without Firebase. Everything else (requests, claiming,
> dashboards) functions normally; only the device push is skipped.

### How delivery works
- On login the app fetches its FCM device token and calls
  `POST /api/mobile/fcm/register`. Tokens are stored on the admin / partner doc.
- When an alert fires, the backend pushes to all admin tokens + all **active**
  partner tokens, and logs it to `notification_logs`.
- Stale tokens (FCM 404/UNREGISTERED) are pruned automatically.

## E. Google Maps (Android)

1. Google Cloud Console → same project → **APIs & Services → Library**.
2. Enable **Maps SDK for Android**.
3. **Credentials → Create credentials → API key**. Restrict it to Android
   apps using package `com.prynt.app` and your signing SHA-1 (recommended).
4. Put the key in `android/app/src/main/res/values/strings.xml`:

   ```xml
   <string name="google_maps_key">AIza...your-key...</string>
   ```

Navigation (the **Navigate** button) uses the `google.navigation:` deep link
and does not require the API key; the embedded map preview does.

## F. Verify

1. `flutter run` on a real device (FCM does not work on some emulators
   without Google Play services).
2. Log in as admin, open a kiosk, tap **Paper Refill** alert.
3. The active delivery partner device should receive a push, and the request
   appears under **Available** in the partner app.
