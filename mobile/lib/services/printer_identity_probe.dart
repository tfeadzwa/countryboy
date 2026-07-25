import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Best-effort ESC/POS identity probe via a temporary Bluetooth socket.
///
/// Uses Android platform code to send GS I queries. Many cheap Bluetooth
/// printers ignore these commands; [serial] will simply be null then.
class PrinterIdentityProbe {
  PrinterIdentityProbe._();

  static const _channel = MethodChannel('countryboy/printer_identity');

  static Future<PrinterIdentityResult> probe(String mac) async {
    if (!Platform.isAndroid) {
      return const PrinterIdentityResult();
    }
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'probeSerial',
        {'mac': mac},
      );
      if (raw == null) return const PrinterIdentityResult();
      return PrinterIdentityResult(
        serial: _clean(raw['serial'] as String?),
        model: _clean(raw['model'] as String?),
        manufacturer: _clean(raw['manufacturer'] as String?),
        error: raw['error'] as String?,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Printer identity probe failed: ${e.message}');
      }
      return PrinterIdentityResult(error: e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Printer identity probe failed: $e');
      }
      return PrinterIdentityResult(error: e.toString());
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    // Reject obvious garbage / control leftovers.
    if (trimmed.length < 2) return null;
    return trimmed;
  }
}

class PrinterIdentityResult {
  const PrinterIdentityResult({
    this.serial,
    this.model,
    this.manufacturer,
    this.error,
  });

  final String? serial;
  final String? model;
  final String? manufacturer;
  final String? error;

  bool get hasSerial => serial != null && serial!.isNotEmpty;
}
