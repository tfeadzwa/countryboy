import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';

/// Why the conductor was kicked out of the current app session.
enum SessionInvalidationReason {
  /// Admin unpaired the device (or device token was rotated / invalidated).
  deviceUnpaired,

  /// Server has no open conductor session for this device (ended remotely).
  sessionEnded,
}

class SessionInvalidationEvent {
  const SessionInvalidationEvent({
    required this.reason,
    required this.message,
  });

  final SessionInvalidationReason reason;
  final String message;

  String get route =>
      reason == SessionInvalidationReason.deviceUnpaired
          ? '/pairing'
          : '/login/merchant';
}

/// Latest forced-logout event for the UI to navigate + show a message.
final sessionInvalidationProvider =
    StateProvider<SessionInvalidationEvent?>((ref) => null);

final sessionInvalidationServiceProvider =
    Provider<SessionInvalidationService>((ref) {
  return SessionInvalidationService(
    storage: ref.watch(secureStorageServiceProvider),
    onInvalidated: (event) {
      // Avoid notifying during an interceptor stack frame when possible.
      Future.microtask(() {
        ref.read(sessionInvalidationProvider.notifier).state = event;
      });
    },
  );
});

class SessionInvalidationService {
  SessionInvalidationService({
    required SecureStorageService storage,
    required void Function(SessionInvalidationEvent event) onInvalidated,
  })  : _storage = storage,
        _onInvalidated = onInvalidated;

  final SecureStorageService _storage;
  final void Function(SessionInvalidationEvent event) _onInvalidated;

  bool _handling = false;

  static const deviceUnpairedMessage =
      'This device was unpaired by an admin. Pair it again with a new code.';
  static const sessionEndedMessage =
      'Your session on this device ended. Please sign in again.';

  /// Device token no longer valid / device unpaired — clear auth + pairing.
  Future<void> handleDeviceUnpaired() => _invalidate(
        SessionInvalidationEvent(
          reason: SessionInvalidationReason.deviceUnpaired,
          message: deviceUnpairedMessage,
        ),
        clearPairing: true,
      );

  /// Open session closed on the server but device may still be paired.
  Future<void> handleSessionEnded() => _invalidate(
        SessionInvalidationEvent(
          reason: SessionInvalidationReason.sessionEnded,
          message: sessionEndedMessage,
        ),
        clearPairing: false,
      );

  Future<void> _invalidate(
    SessionInvalidationEvent event, {
    required bool clearPairing,
  }) async {
    if (_handling) return;
    _handling = true;
    try {
      await _storage.clearAllAuth();
      if (clearPairing) {
        await _storage.clearDevicePairing();
        await _storage.clearOfflineCredentials();
        await _storage.clearPrinter();
      }
      _onInvalidated(event);
    } finally {
      _handling = false;
    }
  }
}

/// Server `code` values that mean the local device credential is dead.
bool isDeviceCredentialFailureCode(String? code) {
  return code == 'DEVICE_UNPAIRED' || code == 'INVALID_DEVICE_TOKEN';
}

bool isNoActiveSessionCode(String? code) => code == 'NO_ACTIVE_SESSION';
