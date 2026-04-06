import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../config/env.dart';
import '../providers/providers.dart';

/// Splash screen - Initial loading and routing screen
/// Shows app logo and checks authentication status
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialization delay for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check authentication status from storage
    final isPaired = await ref.read(isPairedProvider.future);
    final isLoggedIn = await ref.read(isLoggedInProvider.future);
    
    if (!mounted) return;
    
    if (!isPaired) {
      // Device not paired - first time setup
      Navigator.of(context).pushReplacementNamed('/pairing');
    } else if (!isLoggedIn) {
      // Device paired but agent not logged in
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      // Device paired and agent logged in
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            const Icon(
              Icons.directions_bus,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              Environment.appName,
              style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'POS Terminal Edition',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'v${Environment.appVersion}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
