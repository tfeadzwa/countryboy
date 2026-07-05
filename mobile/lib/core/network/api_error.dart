class ApiError implements Exception {
  ApiError({
    required this.message,
    this.statusCode,
    this.details,
  });

  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() => message;

  factory ApiError.fromResponse(dynamic data, int? statusCode) {
    if (data is Map) {
      final error = data['error'] ?? data['message'];
      if (error != null) {
        return ApiError(
          message: error.toString(),
          statusCode: statusCode,
          details: data['details'],
        );
      }
    }
    return ApiError(
      message: 'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
  }

  factory ApiError.network() => ApiError(
        message: 'No internet connection. Check your network and try again.',
      );

  factory ApiError.timeout() => ApiError(
        message: 'Request timed out. Please try again.',
      );

  factory ApiError.unreachable() => ApiError(
        message: 'Cannot reach the server. You can continue offline if signed in.',
      );
}
