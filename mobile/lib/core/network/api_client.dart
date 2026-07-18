import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/secure_storage_service.dart';
import 'api_error.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    TokenRefreshInterceptor(storage, dio),
    ApiErrorInterceptor(),
  ]);
  return dio;
});

/// Converts HTTP error responses into [ApiError] on [DioException.error].
class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(mapDioException(err));
  }
}

ApiError? asApiError(Object error) {
  if (error is ApiError) return error;
  if (error is DioException && error.error is ApiError) {
    return error.error as ApiError;
  }
  return null;
}

/// Handles 401 by refreshing agent tokens and retrying once.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(this._storage, this._dio);

  final SecureStorageService _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    final deviceToken = await _storage.getDeviceToken();
    if (deviceToken != null && deviceToken.isNotEmpty) {
      final path = options.uri.path;
      final isPairRequest = path.contains('/devices/pair');
      if (!isPairRequest) {
        options.headers['x-device-token'] = deviceToken;
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');
    if (isRefreshCall) {
      await _storage.clearAuthTokens();
      return handler.next(err);
    }

    final isOfflineSession = await _storage.isOfflineSession();
    if (isOfflineSession) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      try {
        final response = await _retry(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storage.clearAuthTokens();
        return handler.next(err);
      }

      final refreshDio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = refreshResponse.data!;
      await _storage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );

      final response = await _retry(err.requestOptions);
      return handler.resolve(response);
    } catch (_) {
      await _storage.clearAuthTokens();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final accessToken = await _storage.getAccessToken();
    final deviceToken = await _storage.getDeviceToken();
    final headers = Map<String, dynamic>.from(options.headers);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (deviceToken != null && deviceToken.isNotEmpty) {
      headers['x-device-token'] = deviceToken;
    }
    return _dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(method: options.method, headers: headers),
    );
  }
}

DioException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return DioException(
        requestOptions: e.requestOptions,
        error: ApiError.timeout(),
      );
    case DioExceptionType.connectionError:
      return DioException(
        requestOptions: e.requestOptions,
        error: ApiError.network(),
      );
    default:
      if (e.response != null) {
        return DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          error: ApiError.fromResponse(e.response?.data, e.response?.statusCode),
        );
      }
      return e;
  }
}
