import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../shared/widgets/widgets.dart';

class AgentCodeScreen extends StatefulWidget {
  const AgentCodeScreen({super.key, required this.merchantCode});

  final String merchantCode;

  @override
  State<AgentCodeScreen> createState() => _AgentCodeScreenState();
}

class _AgentCodeScreenState extends State<AgentCodeScreen> {
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
      setState(() => _error = 'Enter a valid 6-character agent code (e.g. TMO014)');
      return;
    }
    context.push('/login/pin', extra: {
      'merchant': widget.merchantCode,
      'agent': code,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
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
              Text('Agent code', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Depot ${widget.merchantCode} — enter your personal agent code.',
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
                'Example  TMO014',
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
