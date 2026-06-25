/// Normalised error thrown by [ApiClient] so the UI can show clean messages.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}
