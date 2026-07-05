import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              Text('Agent code', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Depot ${widget.merchantCode} — enter your personal agent code.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              CodeInputField(
                controller: _controller,
                label: 'Agent code',
                hint: 'TMO014',
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
