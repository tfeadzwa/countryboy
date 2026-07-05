import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Merchant code', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter your depot merchant code to begin sign in.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              CodeInputField(
                controller: _controller,
                label: 'Merchant code',
                hint: 'HRE001',
                errorText: _error,
                onSubmitted: _continue,
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
