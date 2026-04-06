import 'package:flutter/material.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/app_typography.dart';
import '../../core/config/app_colors.dart';

/// Custom button widget optimized for POS terminals
/// Large touch target, clear text, haptic feedback
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonSize size;
  final ButtonType type;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.size = ButtonSize.large,
    this.type = ButtonType.primary,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    final double height = switch (size) {
      ButtonSize.large => AppSpacing.largeTouchTarget,
      ButtonSize.medium => AppSpacing.recommendedTouchTarget,
      ButtonSize.small => AppSpacing.minTouchTarget,
    };

    final Color bgColor = backgroundColor ?? _getBackgroundColor();
    final Color fgColor = textColor ?? _getForegroundColor();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: _buildButton(context, isEnabled, bgColor, fgColor),
    );
  }

  Widget _buildButton(BuildContext context, bool isEnabled, Color bgColor, Color fgColor) {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            disabledBackgroundColor: AppColors.buttonDisabled,
            elevation: AppSpacing.elevationLow,
          ),
          child: _buildContent(fgColor),
        );
      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: fgColor,
            side: BorderSide(color: isEnabled ? fgColor : AppColors.buttonDisabled, width: 2),
          ),
          child: _buildContent(fgColor),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: fgColor,
          ),
          child: _buildContent(fgColor),
        );
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSpacing.iconMedium),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTypography.button),
        ],
      );
    }

    return Text(text, style: AppTypography.button);
  }

  Color _getBackgroundColor() {
    return switch (type) {
      ButtonType.primary => AppColors.primary,
      ButtonType.secondary => AppColors.surface,
      ButtonType.text => Colors.transparent,
    };
  }

  Color _getForegroundColor() {
    return switch (type) {
      ButtonType.primary => AppColors.textInverse,
      ButtonType.secondary => AppColors.primary,
      ButtonType.text => AppColors.primary,
    };
  }
}

enum ButtonSize { small, medium, large }
enum ButtonType { primary, secondary, text }

/// Success button variant (green)
class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const SuccessButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.success,
      textColor: AppColors.textInverse,
      size: ButtonSize.large,
    );
  }
}

/// Danger button variant (red)  
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.error,
      textColor: AppColors.textInverse,
      size: ButtonSize.large,
    );
  }
}
