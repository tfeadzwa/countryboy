import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/connectivity/online_sync_lifecycle.dart';
import '../../core/network/heartbeat_service.dart';
import '../../shared/widgets/widgets.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep presence heartbeat running while the conductor is in the app shell.
    ref.watch(heartbeatLifecycleProvider);
    // Auto sync + clear cashier-ended trips when back online / app resumed.
    ref.watch(onlineSyncLifecycleActiveProvider);

    final connectivity = ref.watch(connectivityStatusProvider);
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    if (location.startsWith('/tickets')) selectedIndex = 1;
    if (location.startsWith('/sync')) selectedIndex = 2;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          connectivity.when(
            data: (s) => ConnectivityBanner(status: s),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/home');
                case 1:
                  context.go('/tickets');
                case 2:
                  context.go('/sync');
              }
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: 'Tickets'),
              NavigationDestination(icon: Icon(Icons.sync_outlined), selectedIcon: Icon(Icons.sync), label: 'Sync'),
            ],
          ),
        ],
      ),
    );
  }
}
