import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// How often the conductor app reports presence while signed in online.
const heartbeatInterval = Duration(seconds: 30);

final heartbeatServiceProvider = Provider<HeartbeatService>((ref) {
  final service = HeartbeatService(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Keeps [HeartbeatService] alive and running while the main shell is mounted.
final heartbeatLifecycleProvider = Provider<void>((ref) {
  final service = ref.watch(heartbeatServiceProvider);
  service.start();
  ref.onDispose(service.stop);
});

class HeartbeatService with WidgetsBindingObserver {
  HeartbeatService({
    required Dio dio,
    required SecureStorageService storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorageService _storage;

  Timer? _timer;
  bool _started = false;
  bool _inFlight = false;
  bool _appInForeground = true;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(heartbeatInterval, (_) => _tick());
    // Immediate first beat so admin sees Online soon after login.
    unawaited(_tick());
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground =
        state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    if (state == AppLifecycleState.resumed) {
      unawaited(_tick());
    }
  }

  /// Immediate presence/printer push (e.g. right after selecting a printer).
  Future<void> pushNow() => _tick(force: true);

  Future<void> _tick({bool force = false}) async {
    if (!force && (!_started || !_appInForeground || _inFlight)) return;
    if (force && _inFlight) return;

    if (!await _storage.hasOnlineAuth()) return;
    if (!await _storage.isDevicePaired()) return;

    final deviceToken = await _storage.getDeviceToken();
    if (deviceToken == null || deviceToken.isEmpty) return;

    _inFlight = true;
    try {
      final printerName = await _storage.getPrinterName();
      final printerMac = await _storage.getPrinterMac();
      final printerSerial = await _storage.getPrinterSerial();
      final body = <String, dynamic>{};
      // Always send the trio together so a new printer clears a prior serial.
      if (printerMac != null && printerMac.isNotEmpty) {
        body['printer_mac'] = printerMac;
        body['printer_name'] =
            (printerName != null && printerName.isNotEmpty) ? printerName : 'Printer';
        body['printer_serial'] = (printerSerial != null && printerSerial.isNotEmpty)
            ? printerSerial
            : null;
      }

      await _dio.post(
        '/agents/heartbeat',
        data: body.isEmpty ? null : body,
        options: Options(
          headers: {'x-device-token': deviceToken},
          // Presence should never block the UI or spam retries.
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // Offline / unpaired / no session — admin will flip to offline via threshold.
    } finally {
      _inFlight = false;
    }
  }
}
