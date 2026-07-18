import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../network/api_client.dart';

enum ConnectivityStatus {
  online,
  offline,
  syncing,
  serverUnreachable,
}

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) {
  final dio = ref.watch(dioProvider);
  return ConnectivityService(dio);
});

final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) {
  return ref.watch(connectivityServiceProvider).statusStream;
});

class ConnectivityService {
  ConnectivityService(this._dio) {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results);
    });
    _startReachabilityPolling();
  }

  final Dio _dio;
  final _controller = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollTimer;
  ConnectivityStatus _current = ConnectivityStatus.offline;
  bool _syncing = false;

  Stream<ConnectivityStatus> get statusStream => _controller.stream;
  ConnectivityStatus get currentStatus => _current;

  void _startReachabilityPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkReachability();
    });
    _checkReachability();
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (!hasNetwork) {
      _emit(ConnectivityStatus.offline);
      return;
    }
    await _checkReachability();
  }

  Future<bool> checkReachability() => _checkReachability();

  Future<bool> _checkReachability() async {
    if (_syncing) return _current == ConnectivityStatus.online;

    try {
      final origin = _apiOrigin(Env.apiBaseUrl);
      final healthDio = Dio(
        BaseOptions(
          baseUrl: origin,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      await healthDio.get('/api');
      _emit(ConnectivityStatus.online);
      return true;
    } catch (_) {
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork = connectivity.any((r) => r != ConnectivityResult.none);
      _emit(
        hasNetwork
            ? ConnectivityStatus.serverUnreachable
            : ConnectivityStatus.offline,
      );
      return false;
    }
  }

  /// Origin only (scheme + host + port). Avoid [String.replaceAll]('/api') —
  /// that corrupts hosts like `https://api.countryboy.co.zw` (`://api` matches).
  static String _apiOrigin(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl.trim());
    if (uri == null || uri.host.isEmpty) {
      return apiBaseUrl.trim();
    }
    return Uri(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  void setSyncing(bool syncing) {
    _syncing = syncing;
    if (syncing) {
      _emit(ConnectivityStatus.syncing);
    } else {
      _checkReachability();
    }
  }

  void _emit(ConnectivityStatus status) {
    if (_current == status) return;
    _current = status;
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _pollTimer?.cancel();
    _controller.close();
  }
}
