import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/env.dart';
import '../../data/repositories/auth_repository.dart';
import '../../services/sync_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final auth = ref.read(authRepositoryProvider);
    final paired = await auth.isDevicePaired();
    if (!paired) {
      context.go('/pairing');
      return;
    }

    final hasSession = await auth.hasSession();
    if (hasSession) {
      ref.read(syncServiceProvider).syncIfOnline();
      if (mounted) context.go('/home');
      return;
    }

    if (mounted) context.go('/login/merchant');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.brandRed,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 44),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              Env.appName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bus conductor operations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
