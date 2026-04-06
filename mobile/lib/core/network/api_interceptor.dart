import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interceptor for adding authentication token to requests
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for pairing endpoint (no token needed)
    if (options.path.contains('/devices/pair')) {
      return handler.next(options);
    }

    // Add auth token to other requests
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}

/// Interceptor for logging API requests and responses (development only)
class LoggingInterceptor extends Interceptor {
  final bool isDevelopment;

  LoggingInterceptor({required this.isDevelopment});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (isDevelopment) {
      developer.log(
        '🌐 REQUEST[${options.method}] => ${options.uri}',
        name: 'API',
      );
      if (options.data != null) {
        developer.log(
          '📤 DATA: ${options.data}',
          name: 'API',
        );
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (isDevelopment) {
      developer.log(
        '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
        name: 'API',
      );
      developer.log(
        '📥 DATA: ${response.data}',
        name: 'API',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (isDevelopment) {
      developer.log(
        '❌ ERROR[${err.response?.statusCode}] => ${err.requestOptions.uri}',
        name: 'API',
        error: err.message,
      );
      if (err.response?.data != null) {
        developer.log(
          '📥 ERROR DATA: ${err.response?.data}',
          name: 'API',
        );
      }
    }
    handler.next(err);
  }
}

/// Interceptor for handling token refresh on 401 errors
class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final String _baseUrl;
  static bool _isRefreshing = false;

  TokenRefreshInterceptor(
    this._dio,
    this._secureStorage,
    this._baseUrl,
  );

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 unauthorized - try to refresh token
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      // Check if this is an offline session (skip refresh for offline tokens)
      final offlineToken = await _secureStorage.read(key: 'offline_token');
      final accessToken = await _secureStorage.read(key: 'access_token');
      
      if (offlineToken != null && accessToken == null) {
        // This is an offline session - token cannot be refreshed
        // Clear offline token and propagate error to force re-login
        await _secureStorage.delete(key: 'offline_token');
        await _secureStorage.delete(key: 'offline_token_expiry');
        return handler.next(err);
      }

      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      
      if (refreshToken != null) {
        _isRefreshing = true;
        try {
          // Attempt token refresh
          final response = await _dio.post(
            '$_baseUrl/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': null, // Don't send expired token
              },
            ),
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];

            // Save new tokens
            await _secureStorage.write(
              key: 'access_token',
              value: newAccessToken,
            );
            await _secureStorage.write(
              key: 'refresh_token',
              value: newRefreshToken,
            );

            // Save token issued timestamp (for monitoring)
            final now = DateTime.now().toIso8601String();
            await _secureStorage.write(
              key: 'token_issued_at',
              value: now,
            );

            developer.log(
              '✅ Token refreshed successfully',
              name: 'TokenRefresh',
            );

            // Retry original request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';
            
            _isRefreshing = false;
            final retryResponse = await _dio.fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          developer.log(
            '❌ Token refresh failed: $e',
            name: 'TokenRefresh',
            error: e,
          );
          
          // Refresh failed - clear all auth data
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          await _secureStorage.delete(key: 'agent_id');
          await _secureStorage.delete(key: 'token_issued_at');
          
          _isRefreshing = false;
          
          // Let error propagate to trigger navigation to login
        }
      } else {
        // No refresh token available
        developer.log(
          '⚠️ No refresh token available, clearing auth data',
          name: 'TokenRefresh',
        );
        
        // Clear any remaining auth data
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'agent_id');
        await _secureStorage.delete(key: 'token_issued_at');
      }
    }

    handler.next(err);
  }
}
