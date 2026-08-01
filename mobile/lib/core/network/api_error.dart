class ApiError implements Exception {
  ApiError({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;

  /// Stable machine-readable code from the API (e.g. DEVICE_UNPAIRED).
  final String? code;
  final dynamic details;

  @override
  String toString() => message;

  bool get isDeviceCredentialFailure =>
      code == 'DEVICE_UNPAIRED' || code == 'INVALID_DEVICE_TOKEN';

  bool get isNoActiveSession => code == 'NO_ACTIVE_SESSION';

  factory ApiError.fromResponse(dynamic data, int? statusCode) {
    if (data is Map) {
      final error = data['error'] ?? data['message'];
      final code = data['code']?.toString();
      if (error != null) {
        return ApiError(
          message: error.toString(),
          statusCode: statusCode,
          code: code,
          details: data['details'],
        );
      }
      if (code != null) {
        return ApiError(
          message: 'Something went wrong. Please try again.',
          statusCode: statusCode,
          code: code,
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

String? extractApiErrorCode(dynamic data) {
  if (data is Map && data['code'] != null) {
    return data['code'].toString();
  }
  return null;
}
