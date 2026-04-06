/// Environment Configuration
/// 
/// Contains all environment-specific settings including API URLs,
/// feature flags, and configuration constants.

class Environment {
  // Prevent instantiation
  Environment._();

  /// API Base URLs
  /// 
  /// For development:
  /// - Android Emulator: Use 10.0.2.2 (maps to host's localhost)
  /// - iOS Simulator: Use localhost
  /// - Physical Device: Use your computer's IP address (e.g., 192.168.1.100)
  static const String apiBaseUrlDev = 'http://192.168.1.240:3000/api';
  static const String apiBaseUrlProd = 'https://api.countryboy.co.zw/api';

  /// Current Environment
  /// 
  /// Toggle between development and production
  static const bool isDevelopment = true;

  /// Active API URL based on environment
  static String get apiBaseUrl => isDevelopment ? apiBaseUrlDev : apiBaseUrlProd;

  /// App Configuration
  static const String appName = 'Countryboy Conductor';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  /// Feature Flags
  /// 
  /// Enable/disable features during development
  static const bool enableLogging = true;
  static const bool enableMockData = false; // For offline development
  static const bool enableDebugBanner = isDevelopment;

  /// Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  /// Sync Configuration
  static const int syncIntervalMinutes = 15; // Background sync frequency
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 5;

  /// Local Storage
  static const String databaseName = 'countryboy_conductor.db';
  static const int databaseVersion = 1;

  /// Session Management
  static const int sessionDurationHours = 12;
  static const bool autoLogoutAtMidnight = true;

  /// Pagination
  static const int defaultPageSize = 50;
  static const int maxTicketsPerTrip = 100;

  /// Validation Rules
  static const int merchantCodeLength = 6;
  static const int agentCodeLength = 6;
  static const int minPinLength = 4;
  static const int maxPinLength = 6;
  static const int pairingCodeLength = 6;

  /// Ticket Serial Numbers
  static const int serialRangeSize = 1000;
  static const int serialLowWarningThreshold = 50; // Warn when < 50 serials left

  /// UI Configuration - Optimized for Android POS Terminals (5-6" screens)
  static const double minTouchTargetSize = 56.0; // Increased from 48dp for POS
  static const double recommendedTouchTargetSize = 64.0; // For primary actions
  static const double keypadButtonSize = 72.0; // Large buttons for PIN entry
  static const int maxRecentTickets = 20;
  
  /// POS Terminal Configuration
  static const bool lockPortraitOrientation = true; // POS terminals are handheld
  static const bool enableHapticFeedback = true; // Tactile feedback for POS
  static const double minTextScaleFactor = 1.0; // Accessibility
  static const double maxTextScaleFactor = 1.3; // Prevent layout breaking

  /// Test Credentials (Development only)
  /// 
  /// These are available in the seeded database
  /// DO NOT use in production!
  static const testPairingCodes = ['ABC234', 'XYZ789'];
  static const testMerchantCode = 'HRE001';
  static const testAgentCode = 'TMO014';
  static const testPin = '1234';
}
