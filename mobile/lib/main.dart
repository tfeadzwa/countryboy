import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_theme.dart';
import 'core/config/env.dart';
import 'core/network/heartbeat_service.dart';
import 'core/routing/app_router.dart';
import 'core/session/session_invalidation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CountryBoyConductorApp()));
}

class CountryBoyConductorApp extends ConsumerWidget {
  const CountryBoyConductorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Presence (and unpair detection) while signed in — including trip screens
    // that sit outside the bottom-nav shell.
    ref.watch(heartbeatLifecycleProvider);

    ref.listen<SessionInvalidationEvent?>(sessionInvalidationProvider, (
      previous,
      next,
    ) {
      if (next == null) return;
      final message = next.message;
      final route = next.route;
      // Clear before navigating so a rebuild doesn't re-trigger.
      ref.read(sessionInvalidationProvider.notifier).state = null;
      router.go(route);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = rootScaffoldMessengerKey.currentState;
        messenger
          ?..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 5),
            ),
          );
      });
    });

    return MaterialApp.router(
      title: Env.appName,
      theme: AppTheme.light(),
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
