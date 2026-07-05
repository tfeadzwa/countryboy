import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';

class IssueFlowStepHeader extends StatelessWidget {
  const IssueFlowStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.label,
  });

  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = step / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Step $step of $total',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.brandRed,
                  ),
            ),
            const Spacer(),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.surfaceMuted,
            color: AppColors.brandRed,
          ),
        ),
      ],
    );
  }
}
