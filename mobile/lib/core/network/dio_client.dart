import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import 'api_error.dart';
import 'api_interceptor.dart';

/// Singleton Dio client with configured interceptors and error handling
class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient._internal(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout: Duration(seconds: Environment.connectionTimeout),
        receiveTimeout: Duration(seconds: Environment.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      LoggingInterceptor(isDevelopment: Environment.isDevelopment),
      AuthInterceptor(_secureStorage),
      TokenRefreshInterceptor(_dio, _secureStorage, Environment.apiBaseUrl),
    ]);
  }

  /// Get singleton instance
  static DioClient getInstance([FlutterSecureStorage? secureStorage]) {
    _instance ??= DioClient._internal(
      secureStorage ?? const FlutterSecureStorage(),
    );
    return _instance!;
  }

  /// Get Dio instance for API calls
  Dio get dio => _dio;

  /// Safe GET request with error handling
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Safe POST request with error handling
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Safe PUT request with error handling
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Safe DELETE request with error handling
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Central error handling for all API calls
  ApiError _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout();

      case DioExceptionType.connectionError:
        return ApiError.network();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        return ApiError.fromResponse(responseData, statusCode);

      case DioExceptionType.cancel:
        return ApiError(
          type: ApiErrorType.unknown,
          message: 'Request was cancelled',
        );

      default:
        return ApiError(
          type: ApiErrorType.unknown,
          message: error.message ?? 'An unknown error occurred',
        );
    }
  }
}
