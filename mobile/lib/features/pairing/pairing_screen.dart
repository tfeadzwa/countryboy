import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_spacing.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/widgets.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final code = _controller.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-character pairing code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(deviceRepositoryProvider).pairDevice(code);
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/login/merchant');
    } on ApiError catch (e) {
      if (e.statusCode == 409 && mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pairing code already used'),
            content: Text(
              e.message.isNotEmpty
                  ? e.message
                  : 'This pairing code has already been used on another device. '
                      'Ask your depot admin to unpair the device and generate a new code.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() => _error = null);
      } else {
        setState(() => _error = e.message);
      }
    } catch (_) {
      setState(() => _error = 'Pairing failed. Check the code and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pair this device',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter the one-time pairing code from your depot admin. '
                'This links the device to your depot for ticket sync.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_success)
                const Icon(Icons.check_circle, color: Colors.green, size: 64)
              else
                CodeInputField(
                  controller: _controller,
                  label: 'Pairing code',
                  hint: 'ABC234',
                  errorText: _error,
                  onSubmitted: _pair,
                ),
              const Spacer(),
              AppButton(
                label: _success ? 'Paired!' : 'Pair Device',
                loading: _loading,
                onPressed: _success ? null : _pair,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
