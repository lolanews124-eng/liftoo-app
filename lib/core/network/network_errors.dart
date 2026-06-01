import 'package:dio/dio.dart';
import 'app_exception.dart';

class NetworkErrors {
  NetworkErrors._();

  static const noInternet =
      'No internet connection. Please check your network and try again.';
  static const timeout = 'Connection timed out. Please try again.';
  static const serverError =
      'Server is temporarily unavailable. Please try again later.';
  static const generic = 'Something went wrong. Please try again.';

  static bool isOffline(Object e) {
    if (e is AppException) return e.type == AppErrorType.offline;
    if (e is DioException) return _dioIsOffline(e);
    return _looksOffline(e.toString());
  }

  static String userMessage(Object e) {
    if (e is AppException) return e.userMessage;
    if (e is DioException) return fromDio(e).userMessage;
    final raw = e.toString();
    if (_looksOffline(raw)) return noInternet;
    final cleaned = raw.replaceFirst('Exception: ', '').trim();
    if (cleaned.isNotEmpty && !_isTechnical(cleaned)) return cleaned;
    return generic;
  }

  static AppException fromDio(DioException e) {
    if (_dioIsOffline(e)) {
      return const AppException(noInternet, type: AppErrorType.offline);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const AppException(timeout, type: AppErrorType.timeout);
    }

    final status = e.response?.statusCode;
    if (status != null && status >= 500) {
      return AppException(serverError, type: AppErrorType.server, statusCode: status);
    }

    final apiMsg = _extractApiMessage(e.response?.data);
    if (apiMsg != null && apiMsg.isNotEmpty) {
      return AppException(apiMsg, type: AppErrorType.validation, statusCode: status);
    }

    if (status == 401) {
      return AppException(
        'Session expired. Please login again.',
        type: AppErrorType.unauthorized,
        statusCode: status,
      );
    }

    return AppException(generic, type: AppErrorType.unknown, statusCode: status);
  }

  static bool _dioIsOffline(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        return _looksOffline(e.message ?? e.error?.toString() ?? '');
      default:
        return false;
    }
  }

  static bool _looksOffline(String s) {
    final lower = s.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection errored') ||
        lower.contains('connection error') ||
        lower.contains('connection failed') ||
        lower.contains('xmlhttprequest error') ||
        lower.contains('no address associated') ||
        lower.contains('software caused connection abort') ||
        lower.contains('network unreachable') ||
        lower.contains('errno = 7') ||
        lower.contains('errno = 8');
  }

  static bool _isTechnical(String s) {
    final lower = s.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('status code') ||
        RegExp(r'error code:\s*\d+').hasMatch(lower);
  }

  static String? _extractApiMessage(dynamic data) {
    if (data is! Map) return null;
    final err = data['error'];
    if (err is Map && err['message'] is String) return err['message'] as String;
    if (data['message'] is String) return data['message'] as String;
    return null;
  }
}
