import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'app_exception.dart';
import 'connectivity_service.dart';
import 'network_errors.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage _storage;
  final ConnectivityService _connectivity;

  ApiClient(this._storage, [ConnectivityService? connectivity])
      : _connectivity = connectivity ?? ConnectivityService() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: Duration(seconds: kDebugMode ? 30 : 4),
      receiveTimeout: Duration(seconds: kDebugMode ? 30 : 4),
      headers: {'Content-Type': 'application/json'},
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ));
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!await _connectivity.isOnline) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              message: NetworkErrors.noInternet,
            ),
          );
        }

        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final role = await _storage.getRole();
        if (role != null) {
          options.headers['X-Active-Role'] = role;
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refresh = await _storage.getRefreshToken();
          if (refresh != null) {
            try {
              final res = await Dio().post(
                '${AppConfig.apiUrl}/api/v1/auth/refresh',
                data: {'refreshToken': refresh},
              );
              final data = res.data['data'] ?? res.data;
              await _storage.saveTokens(
                accessToken: data['accessToken'],
                refreshToken: data['refreshToken'],
              );
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${data['accessToken']}';
              final clone = await dio.fetch(opts);
              return handler.resolve(clone);
            } catch (_) {
              await _storage.clear();
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _guard(() async {
        final res = await dio.get(path, queryParameters: query);
        return _unwrap(res.data) as T;
      });

  Future<T> post<T>(String path, {dynamic data}) =>
      _guard(() async {
        final res = await dio.post(path, data: data);
        return _unwrap(res.data) as T;
      });

  Future<T> put<T>(String path, {dynamic data}) =>
      _guard(() async {
        final res = await dio.put(path, data: data);
        return _unwrap(res.data) as T;
      });

  Future<T> patch<T>(String path, {dynamic data}) =>
      _guard(() async {
        final res = await dio.patch(path, data: data);
        return _unwrap(res.data) as T;
      });

  Future<T> delete<T>(String path) =>
      _guard(() async {
        final res = await dio.delete(path);
        return _unwrap(res.data) as T;
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkErrors.fromDio(e);
    }
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map && data.containsKey('success')) {
      if (data['success'] == false) {
        final raw = data['error'] is Map ? data['error']['message'] : data['message'];
        final msg = raw is String && raw.isNotEmpty ? raw : NetworkErrors.generic;
        throw AppException(msg, type: AppErrorType.validation);
      }
      return data['data'];
    }
    return data;
  }
}
