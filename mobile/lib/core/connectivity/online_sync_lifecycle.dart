import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_service.dart';
import '../../services/sync_service.dart';

/// Bumped after reconnect/resume trip reconcile so UI (home, etc.) refreshes.
final tripSessionRevisionProvider = StateProvider<int>((ref) => 0);

final onlineSyncLifecycleProvider = Provider<OnlineSyncLifecycle>((ref) {
  final lifecycle = OnlineSyncLifecycle(
    connectivity: ref.watch(connectivityServiceProvider),
    sync: ref.watch(syncServiceProvider),
    onTripSessionChanged: () {
      ref.read(tripSessionRevisionProvider.notifier).state++;
    },
  );
  ref.onDispose(lifecycle.dispose);
  return lifecycle;
});

/// Starts auto sync + trip reconcile while the main shell is mounted.
final onlineSyncLifecycleActiveProvider = Provider<void>((ref) {
  final lifecycle = ref.watch(onlineSyncLifecycleProvider);
  lifecycle.start();
  ref.onDispose(lifecycle.stop);
});

/// Runs sync + active-trip reconcile when the device regains server reachability
/// (and when the app returns to the foreground while online).
class OnlineSyncLifecycle with WidgetsBindingObserver {
  OnlineSyncLifecycle({
    required ConnectivityService connectivity,
    required SyncService sync,
    required VoidCallback onTripSessionChanged,
  })  : _connectivity = connectivity,
        _sync = sync,
        _onTripSessionChanged = onTripSessionChanged;

  final ConnectivityService _connectivity;
  final SyncService _sync;
  final VoidCallback _onTripSessionChanged;

  StreamSubscription<ConnectivityStatus>? _subscription;
  ConnectivityStatus? _previous;
  bool _started = false;
  bool _inFlight = false;

  void start() {
    if (_started) return;
    _started = true;
    _previous = _connectivity.currentStatus;
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.statusStream.listen(_onStatus);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() => stop();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reconcileIfOnline(force: true));
    }
  }

  void _onStatus(ConnectivityStatus status) {
    final previous = _previous;
    _previous = status;

    final regainedOnline = status == ConnectivityStatus.online &&
        previous != null &&
        previous != ConnectivityStatus.online &&
        previous != ConnectivityStatus.syncing;

    if (regainedOnline) {
      unawaited(_reconcileIfOnline(force: true));
    }
  }

  Future<void> _reconcileIfOnline({bool force = false}) async {
    if (!_started || _inFlight) return;
    if (!await _connectivity.checkReachability()) return;

    _inFlight = true;
    try {
      await _sync.syncIfOnline(force: force);
      await _sync.reconcileActiveTrip();
      _onTripSessionChanged();
    } catch (_) {
      // Best-effort — next reconnect / manual refresh will retry.
    } finally {
      _inFlight = false;
    }
  }
}
