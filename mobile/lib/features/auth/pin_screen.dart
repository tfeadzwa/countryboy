import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_spacing.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/api_error.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../services/sync_service.dart';
import '../../shared/widgets/widgets.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({
    super.key,
    required this.merchantCode,
    required this.agentCode,
  });

  final String merchantCode;
  final String agentCode;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  bool _loading = false;
  String? _error;
  static const _pinLength = 4;

  Future<void> _submit() async {
    if (_pin.length < _pinLength) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authRepositoryProvider);
      final connectivity = ref.read(connectivityServiceProvider);
      final online = await connectivity.checkReachability();

      if (!online && !await auth.isOfflineLoginEnabled()) {
        throw ApiError(
          message:
              'Internet required for first sign in. Connect and try again.',
        );
      }

      final result = await auth.login(
        merchantCode: widget.merchantCode,
        agentCode: widget.agentCode,
        pin: _pin,
      );

      final mismatch = await auth.getDeviceDepotMismatch(
        loginMerchantCode: widget.merchantCode,
        agent: result.agent,
      );
      if (mismatch != null) {
        await auth.logout();
        if (!mounted) return;
        final rePair = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Device depot mismatch'),
            content: Text(mismatch.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Re-pair device'),
              ),
            ],
          ),
        );
        if (rePair == true && mounted) {
          context.go('/pairing');
        }
        return;
      }

      if (online && mounted) {
        await auth.enableOfflineAccess(
          merchantCode: widget.merchantCode,
          agentCode: widget.agentCode,
          pin: _pin,
        );

        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Offline sign-in enabled'),
            content: const Text(
              'Offline sign-in has been enabled. Your credentials are securely stored for offline use.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        try {
          await ref.read(syncServiceProvider).syncIfOnline(force: true);
        } catch (_) {}
        await ref.read(tripRepositoryProvider).syncActiveTripFromServer();
      }

      if (mounted) context.go('/home');
    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
        _pin = '';
      });
    } catch (_) {
      setState(() {
        _error = 'Sign in failed. Please try again.';
        _pin = '';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDigit(int d) {
    if (_loading || _pin.length >= _pinLength) return;
    setState(() => _pin += d.toString());
    if (_pin.length == _pinLength) {
      _submit();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityStatusProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              connectivity.when(
                data: (s) => ConnectivityBanner(status: s),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Enter PIN', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${widget.merchantCode} · ${widget.agentCode}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              PinKeypad(
                pinLength: _pin.length,
                maxLength: _pinLength,
                onDigit: _onDigit,
                onDelete: _onDelete,
                error: _error != null,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                AppButton(
                  label: 'Sign in',
                  onPressed: _pin.length == _pinLength ? _submit : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
