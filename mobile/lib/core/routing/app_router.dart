import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/pairing_screen.dart';
import '../../features/auth/presentation/screens/login_codes_screen.dart';
import '../../features/auth/presentation/screens/login_pin_screen.dart';
import '../../features/home/home_screen.dart';
import '../presentation/splash_screen.dart';

/// Application Routes Configuration
/// 
/// Centralized routing configuration for the entire app.
/// Keeps named routes and route generation logic separate from main.dart
class AppRouter {
  // Prevent instantiation
  AppRouter._();

  /// Route names as constants for type safety
  static const String splash = '/';
  static const String pairing = '/pairing';
  static const String login = '/login';
  static const String loginPin = '/login/pin';
  static const String home = '/home';

  /// Named routes map
  /// 
  /// Simple routes without arguments
  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        pairing: (context) => const PairingScreen(),
        login: (context) => const LoginCodesScreen(),
        home: (context) => const HomeScreen(),
      };

  /// Route generator for routes requiring arguments
  /// 
  /// Handles dynamic routes that need to pass data between screens
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginPin:
        // Login PIN screen requires merchant and agent codes
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (context) => LoginPinScreen(
            merchantCode: args?['merchantCode'] ?? '',
            agentCode: args?['agentCode'] ?? '',
          ),
          settings: settings,
        );

      // Add more dynamic routes here as needed
      // case someOtherRoute:
      //   final args = settings.arguments as SomeType;
      //   return MaterialPageRoute(builder: (context) => SomeScreen(args));

      default:
        // Route not found
        return null;
    }
  }

  /// Fallback route for undefined routes
  /// 
  /// Shown when a route doesn't exist
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Route not found: ${settings.name}'),
        ),
      ),
    );
  }

  /// Navigation helpers for type-safe navigation
  /// 
  /// These methods provide a cleaner API for navigating between screens

  static Future<void> goToSplash(BuildContext context) {
    return Navigator.pushReplacementNamed(context, splash);
  }

  static Future<void> goToPairing(BuildContext context) {
    return Navigator.pushReplacementNamed(context, pairing);
  }

  static Future<void> goToLogin(BuildContext context) {
    return Navigator.pushReplacementNamed(context, login);
  }

  static Future<void> goToLoginPin(
    BuildContext context, {
    required String merchantCode,
    required String agentCode,
  }) {
    return Navigator.pushNamed(
      context,
      loginPin,
      arguments: {
        'merchantCode': merchantCode,
        'agentCode': agentCode,
      },
    );
  }

  static Future<void> goToHome(BuildContext context) {
    return Navigator.pushReplacementNamed(context, home);
  }

  /// Pop current route
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}
