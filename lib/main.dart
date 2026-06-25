import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/kiosk_provider.dart';
import 'providers/partner_provider.dart';
import 'providers/request_provider.dart';
import 'services/fcm_service.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — tolerate missing config in dev so the app still boots.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init skipped/failed: $e');
  }

  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final store = SecureStore(storage);
  final apiClient = ApiClient(store);
  final fcm = FcmService(apiClient);

  final auth = AuthProvider(store, fcm);
  // Force logout if the backend rejects the token.
  apiClient.onUnauthorized = auth.onSessionExpired;

  final themeProvider = ThemeProvider(storage);
  await themeProvider.load();
  await auth.bootstrap();

  try {
    await fcm.init();
  } catch (e) {
    debugPrint('FCM init skipped/failed: $e');
  }

  runApp(PryntApp(
    store: store,
    apiClient: apiClient,
    auth: auth,
    themeProvider: themeProvider,
  ));
}

class PryntApp extends StatelessWidget {
  final SecureStore store;
  final ApiClient apiClient;
  final AuthProvider auth;
  final ThemeProvider themeProvider;

  const PryntApp({
    super.key,
    required this.store,
    required this.apiClient,
    required this.auth,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => KioskProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => PartnerProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => RequestProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(apiClient)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Prynt',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
