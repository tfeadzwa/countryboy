/// Device pairing request
class PairDeviceRequest {
  final String pairingCode;
  final String deviceName;
  final String deviceModel;
  final String appVersion;

  PairDeviceRequest({
    required this.pairingCode,
    required this.deviceName,
    required this.deviceModel,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'pairing_code': pairingCode,
        'device_name': deviceName,
        'device_model': deviceModel,
        'app_version': appVersion,
      };
}

/// Device pairing response
class PairDeviceResponse {
  final String deviceToken;
  final String merchantCode;
  final String message;

  PairDeviceResponse({
    required this.deviceToken,
    required this.merchantCode,
    required this.message,
  });

  factory PairDeviceResponse.fromJson(Map<String, dynamic> json) =>
      PairDeviceResponse(
        deviceToken: json['device_token'] as String,
        merchantCode: json['merchant_code'] as String,
        message: json['message'] as String,
      );
}

/// Agent login request
class LoginRequest {
  final String merchantCode;
  final String agentCode;
  final String pin;

  LoginRequest({
    required this.merchantCode,
    required this.agentCode,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {
        'merchant_code': merchantCode,
        'agent_code': agentCode,
        'pin': pin,
      };
}

/// Agent login response
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final AgentDto agent;
  final String message;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.agent,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        agent: AgentDto.fromJson(json['agent'] as Map<String, dynamic>),
        message: json['message'] as String,
      );
}

/// Agent data transfer object
class AgentDto {
  final String id;
  final String agentCode;
  final String firstName;
  final String lastName;
  final String role;
  final String merchantCode;
  final String merchantName;
  final String depotCode;
  final String depotName;

  AgentDto({
    required this.id,
    required this.agentCode,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.merchantCode,
    required this.merchantName,
    required this.depotCode,
    required this.depotName,
  });

  factory AgentDto.fromJson(Map<String, dynamic> json) => AgentDto(
        id: json['id'] as String,
        agentCode: json['agent_code'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        role: json['role'] as String,
        merchantCode: json['merchant_code'] as String,
        merchantName: json['merchant_name'] as String,
        depotCode: json['depot_code'] as String,
        depotName: json['depot_name'] as String,
      );
}

/// Token refresh request
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };
}

/// Token refresh response
class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      RefreshTokenResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
