import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../core/config/env.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/utils/receipt_text.dart';
import '../domain/models/ticket_receipt_data.dart';

final ticketPrintServiceProvider = Provider<TicketPrintService>((ref) {
  return TicketPrintService(ref.read(secureStorageServiceProvider));
});

class SavedPrinter {
  const SavedPrinter({required this.name, required this.mac});

  final String name;
  final String mac;
}

class PrinterException implements Exception {
  PrinterException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Direct ESC/POS printing to a paired 58mm Bluetooth thermal printer.
class TicketPrintService {
  TicketPrintService(this._storage);

  final SecureStorageService _storage;

  static img.Image? _logo;

  /// Drop cached logo so size/layout tweaks apply after hot restart.
  static void clearLogoCache() => _logo = null;

  Future<void> ensureReady() async {
    await _ensureBluetoothPermission();

    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) {
      throw PrinterException(
        'Bluetooth is off. Turn it on to print tickets.',
      );
    }
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    await ensureReady();
    return PrintBluetoothThermal.pairedBluetooths;
  }

  Future<SavedPrinter?> getSavedPrinter() async {
    final mac = await _storage.getPrinterMac();
    if (mac == null || mac.isEmpty) return null;
    final name = await _storage.getPrinterName() ?? 'Printer';
    return SavedPrinter(name: name, mac: mac);
  }

  Future<bool> isConnected() => PrintBluetoothThermal.connectionStatus;

  /// Connects to [device] and remembers it for next print.
  Future<bool> connectAndSave(BluetoothInfo device) async {
    await ensureReady();
    final ok = await PrintBluetoothThermal.connect(
      macPrinterAddress: device.macAdress,
    );
    if (ok) {
      await _storage.savePrinter(
        mac: device.macAdress,
        name: device.name.isEmpty ? 'Printer' : device.name,
      );
    }
    return ok;
  }

  /// Reconnects to the last saved printer, if any.
  Future<bool> connectSaved() async {
    final saved = await getSavedPrinter();
    if (saved == null) return false;
    await ensureReady();
    if (await isConnected()) return true;
    return PrintBluetoothThermal.connect(macPrinterAddress: saved.mac);
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
  }

  Future<void> printReceipt(TicketReceiptData receipt) async {
    await _ensureConnected();
    final bytes = await buildReceiptBytes(receipt);
    final ok = await PrintBluetoothThermal.writeBytes(bytes);
    if (!ok) {
      throw PrinterException('Printer did not accept the ticket. Try again.');
    }
  }

  Future<void> printReceipts(List<TicketReceiptData> receipts) async {
    for (var i = 0; i < receipts.length; i++) {
      await printReceipt(receipts[i]);
      if (i < receipts.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<List<int>> buildReceiptBytes(TicketReceiptData receipt) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    final issued = sanitizeReceiptText(
      DateFormat('dd MMM yyyy HH:mm').format(receipt.ticket.issuedAt),
    );
    final origin = sanitizeReceiptText(
      receipt.ticket.departure ?? receipt.trip.routeOrigin ?? 'Origin',
    );
    final destination = sanitizeReceiptText(
      receipt.ticket.destination ?? receipt.trip.routeDestination ?? 'Dest',
    );
    final routeLine = '$origin -> $destination';
    final amount =
        '${receipt.ticket.currency} ${receipt.ticket.amount.toStringAsFixed(2)}';
    final ticketNo = sanitizeReceiptText(receipt.ticket.displayNumber);

    bytes.addAll(generator.reset());

    final logo = await _loadLogo();
    if (logo != null) {
      bytes.addAll(generator.image(logo));
      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(
      generator.text(
        'BUS TICKET',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        sanitizeReceiptText(receipt.categoryLabel),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    // Compact route + fare (no oversized ticket number / multi-line route).
    bytes.addAll(
      generator.text(
        routeLine,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        amount,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(generator.hr());

    // Ticket number sits with the other detail rows (normal size).
    bytes.addAll(_kv(generator, 'Ticket', ticketNo));
    bytes.addAll(_kv(generator, 'Bus', receipt.trip.fleetNumber ?? '-'));
    if (receipt.ticket.passengerPhone != null &&
        receipt.ticket.passengerPhone!.isNotEmpty) {
      bytes.addAll(_kv(generator, 'Phone', receipt.ticket.passengerPhone!));
    }
    bytes.addAll(_kv(generator, 'Issued', issued));
    bytes.addAll(_kv(generator, 'Depot', receipt.depotName));
    bytes.addAll(_kv(generator, 'Conductor', receipt.agentName));
    if (receipt.deviceSerial != null) {
      bytes.addAll(_kv(generator, 'Device', receipt.deviceSerial!));
    }

    if (receipt.ticket.syncStatus != 'synced') {
      bytes.addAll(generator.feed(1));
      bytes.addAll(
        generator.text(
          'OFFLINE - SYNC PENDING',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      );
    }

    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.qrcode(
        receipt.verifyUrl,
        size: QRSize.size5,
        cor: QRCorrection.M,
      ),
    );
    bytes.addAll(
      generator.text(
        'Scan to verify ticket',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        'Thank you for travelling with us',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        sanitizeReceiptText(Env.appName),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(3));

    return bytes;
  }

  Future<void> _ensureConnected() async {
    await ensureReady();
    if (await isConnected()) return;

    final connected = await connectSaved();
    if (!connected) {
      throw PrinterException(
        'No printer connected. Select a paired Bluetooth printer first.',
      );
    }
  }

  /// Opens the system app settings so the user can enable Nearby devices.
  Future<bool> openBluetoothSettings() => openAppSettings();

  Future<void> _ensureBluetoothPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (!status.isGranted && !status.isLimited) {
        throw PrinterException(
          status.isPermanentlyDenied
              ? 'Bluetooth permission is blocked. Enable it in Settings.'
              : 'Bluetooth permission is required to print.',
        );
      }
      return;
    }

    if (!Platform.isAndroid) return;

    // Android 12+ needs Nearby devices (BLUETOOTH_CONNECT / SCAN).
    // Request one at a time — Samsung devices often drop batch dialogs.
    final connect = await _requestAndroidPermission(Permission.bluetoothConnect);
    final scan = await _requestAndroidPermission(Permission.bluetoothScan);

    // Source of truth for print_bluetooth_thermal (SDK 31+).
    // If this is false, the plugin logs a warning and silently fails other calls.
    final pluginGranted =
        await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (pluginGranted) return;

    final permanentlyDenied =
        connect.isPermanentlyDenied || scan.isPermanentlyDenied;
    throw PrinterException(
      permanentlyDenied
          ? 'Nearby devices permission is blocked. Open Settings → Permissions → Nearby devices and allow it for this app.'
          : 'Allow Nearby devices permission when prompted so the app can reach the printer.',
    );
  }

  Future<PermissionStatus> _requestAndroidPermission(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return status;
    if (status.isPermanentlyDenied) return status;
    return permission.request();
  }

  Future<img.Image?> _loadLogo() async {
    if (_logo != null) return _logo;
    try {
      final data = await rootBundle.load('assets/brand/cboy-receipt-logo.png');
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded == null) return null;
      // Fit ~48mm on 58mm paper (384px printable width at standard density).
      _logo = img.copyResize(decoded, width: 340);
      return _logo;
    } catch (_) {
      return null;
    }
  }

  List<int> _kv(Generator generator, String label, String value) {
    return generator.row([
      PosColumn(
        text: sanitizeReceiptText(label.toUpperCase()),
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: sanitizeReceiptText(value),
        width: 8,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
  }
}
