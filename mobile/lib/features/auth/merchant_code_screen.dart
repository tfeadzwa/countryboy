import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../shared/widgets/widgets.dart';

class MerchantCodeScreen extends StatefulWidget {
  const MerchantCodeScreen({super.key});

  @override
  State<MerchantCodeScreen> createState() => _MerchantCodeScreenState();
}

class _MerchantCodeScreenState extends State<MerchantCodeScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final code = _controller.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}\d{3}$').hasMatch(code)) {
      setState(() => _error = 'Enter a valid 6-character merchant code (e.g. HRE001)');
      return;
    }
    context.push('/login/agent', extra: code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Merchant code', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter your depot merchant code to begin sign in.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              CharacterCodeField(
                controller: _controller,
                errorText: _error,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onCompleted: _continue,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '3 letters  ·  3 digits',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Example  HRE001',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(label: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}
