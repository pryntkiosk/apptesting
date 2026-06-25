import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// HTTP client that injects the bearer token, decodes JSON, and converts
/// errors into [ApiException]. Callbacks let the auth layer react to 401s.
class ApiClient {
  final SecureStore _store;
  final http.Client _http;

  /// Invoked when the server rejects the token (401). Used to force logout.
  void Function()? onUnauthorized;

  ApiClient(this._store, {http.Client? client})
      : _http = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = AppConfig.apiBaseUrl + AppConfig.mobilePrefix + path;
    final uri = Uri.parse(base);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, '$v')),
    });
  }

  Future<Map<String, String>> _headers() async {
    final token = await _store.readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send(() async => _http
        .get(_uri(path, query), headers: await _headers())
        .timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> post(String path, {Object? body}) async {
    return _send(() async => _http
        .post(_uri(path),
            headers: await _headers(), body: jsonEncode(body ?? {}))
        .timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> put(String path, {Object? body}) async {
    return _send(() async => _http
        .put(_uri(path),
            headers: await _headers(), body: jsonEncode(body ?? {}))
        .timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> delete(String path) async {
    return _send(() async => _http
        .delete(_uri(path), headers: await _headers())
        .timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } on TimeoutException {
      throw ApiException(0, 'Request timed out. Check your connection.');
    } catch (_) {
      throw ApiException(0, 'Network error. Please try again.');
    }

    final body = res.body.isEmpty ? null : _tryDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }

    final message = (body is Map && body['detail'] != null)
        ? body['detail'].toString()
        : 'Something went wrong (${res.statusCode}).';
    throw ApiException(res.statusCode, message);
  }

  dynamic _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }
}
