import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage.dart';
import '../models/app_user.dart';
import '../services/fcm_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final SecureStore _store;
  final FcmService _fcm;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;

  AuthProvider(this._store, this._fcm);

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get busy => _busy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Restore a saved session on app launch.
  Future<void> bootstrap() async {
    final token = await _store.readToken();
    final userJson = await _store.readUser();
    if (token != null && userJson != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _status = AuthStatus.authenticated;
        // Re-sync FCM token for the restored session.
        _fcm.syncToken();
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _busy = true;
    notifyListeners();
    try {
      // Login uses a raw client because there is no token yet.
      final res = await http
          .post(
            Uri.parse(AppConfig.loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(AppConfig.requestTimeout);

      final body = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode != 200) {
        final msg = (body is Map && body['detail'] != null)
            ? body['detail'].toString()
            : 'Login failed (${res.statusCode}).';
        throw ApiException(res.statusCode, msg);
      }

      final token = body['token'] as String;
      final user = AppUser.fromJson(body['user'] as Map<String, dynamic>);

      await _store.saveToken(token);
      await _store.saveUser(jsonEncode(user.toJson()));

      _user = user;
      _status = AuthStatus.authenticated;

      // Register this device for push notifications.
      await _fcm.syncToken();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(0, 'Could not reach the server. Check your connection.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _fcm.unregister();
    await _store.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Triggered by ApiClient on a 401 — forces the user back to login.
  void onSessionExpired() {
    _store.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
