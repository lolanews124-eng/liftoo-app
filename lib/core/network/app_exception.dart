enum AppErrorType {
  offline,
  timeout,
  server,
  unauthorized,
  validation,
  unknown,
}

/// User-facing error — never expose raw Dio/status codes in UI.
class AppException implements Exception {
  final String userMessage;
  final AppErrorType type;
  final int? statusCode;

  const AppException(
    this.userMessage, {
    this.type = AppErrorType.unknown,
    this.statusCode,
  });

  @override
  String toString() => userMessage;
}
