import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../core/network/heartbeat_service.dart';
import '../../../services/ticket_print_service.dart';
import '../../../shared/widgets/widgets.dart';

/// Shows paired Bluetooth devices and returns the selected printer, or null.
Future<BluetoothInfo?> showPrinterPickerSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<BluetoothInfo>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PrinterPickerSheet(),
  );
}

class _PrinterPickerSheet extends ConsumerStatefulWidget {
  const _PrinterPickerSheet();

  @override
  ConsumerState<_PrinterPickerSheet> createState() =>
      _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends ConsumerState<_PrinterPickerSheet> {
  List<BluetoothInfo>? _devices;
  String? _error;
  bool _loading = true;
  bool _needsSettings = false;
  String? _connectingMac;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _needsSettings = false;
    });
    try {
      final devices =
          await ref.read(ticketPrintServiceProvider).getPairedDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
        if (devices.isEmpty) {
          _error =
              'No paired Bluetooth devices found. Pair your 58mm printer in phone Settings first, then refresh.';
        }
      });
    } on PrinterException catch (e) {
      if (!mounted) return;
      final msg = e.message;
      setState(() {
        _loading = false;
        _error = msg;
        _needsSettings = msg.toLowerCase().contains('settings') ||
            msg.toLowerCase().contains('blocked') ||
            msg.toLowerCase().contains('nearby devices');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not list Bluetooth printers.';
      });
    }
  }

  Future<void> _openSettings() async {
    await ref.read(ticketPrintServiceProvider).openBluetoothSettings();
  }

  Future<void> _select(BluetoothInfo device) async {
    setState(() => _connectingMac = device.macAdress);
    try {
      final ok =
          await ref.read(ticketPrintServiceProvider).connectAndSave(device);
      if (!mounted) return;
      if (ok) {
        // Persist printer identity to the server when online.
        unawaited(ref.read(heartbeatServiceProvider).pushNow());
        Navigator.of(context).pop(device);
      } else {
        setState(() {
          _connectingMac = null;
          _error =
              'Could not connect to ${device.name}. Make sure the printer is on and in range.';
        });
      }
    } on PrinterException catch (e) {
      if (!mounted) return;
      setState(() {
        _connectingMac = null;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectingMac = null;
        _error = 'Connection failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select printer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose your paired 58mm Bluetooth thermal printer.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_devices != null && _devices!.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final device = _devices![i];
                    final connecting = _connectingMac == device.macAdress;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: connecting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.print_outlined,
                              color: AppColors.brandRed,
                            ),
                      title: Text(
                        device.name.isEmpty ? 'Unknown device' : device.name,
                      ),
                      subtitle: Text(device.macAdress),
                      onTap: _connectingMac != null
                          ? null
                          : () => _select(device),
                    );
                  },
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_needsSettings) ...[
              AppButton(
                label: 'Open app settings',
                onPressed: _connectingMac != null ? null : _openSettings,
                icon: Icons.settings_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              label: 'Refresh',
              outlined: true,
              onPressed: _connectingMac != null ? null : _load,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}
