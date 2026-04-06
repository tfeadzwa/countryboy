/// API error types and models for consistent error handling
enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  serverError,
  notFound,
  badRequest,
  unknown,
}

/// API error model with details for error handling
class ApiError implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiError.network() => ApiError(
        type: ApiErrorType.network,
        message: 'No internet connection. Please check your network.',
      );

  factory ApiError.timeout() => ApiError(
        type: ApiErrorType.timeout,
        message: 'Request timeout. Please try again.',
      );

  factory ApiError.unauthorized() => ApiError(
        type: ApiErrorType.unauthorized,
        message: 'Session expired. Please login again.',
        statusCode: 401,
      );

  factory ApiError.serverError([String? message]) => ApiError(
        type: ApiErrorType.serverError,
        message: message ?? 'Server error occurred. Please try again later.',
        statusCode: 500,
      );

  factory ApiError.notFound([String? message]) => ApiError(
        type: ApiErrorType.notFound,
        message: message ?? 'Resource not found.',
        statusCode: 404,
      );

  factory ApiError.badRequest([String? message]) => ApiError(
        type: ApiErrorType.badRequest,
        message: message ?? 'Invalid request.',
        statusCode: 400,
      );

  factory ApiError.fromResponse(dynamic response, int? statusCode) {
    String message = 'An error occurred';
    
    if (response is Map) {
      message = response['message'] ?? response['error'] ?? message;
    } else if (response is String) {
      message = response;
    }

    switch (statusCode) {
      case 400:
        return ApiError.badRequest(message);
      case 401:
        return ApiError.unauthorized();
      case 404:
        return ApiError.notFound(message);
      case 500:
      case 502:
      case 503:
        return ApiError.serverError(message);
      default:
        return ApiError(
          type: ApiErrorType.unknown,
          message: message,
          statusCode: statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
