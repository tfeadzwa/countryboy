import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/connectivity/connectivity_service.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: loading ? null : onPressed, child: child);
    }
    return ElevatedButton(onPressed: loading ? null : onPressed, child: child);
  }
}

class CodeInputField extends StatelessWidget {
  const CodeInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
            LengthLimitingTextInputFormatter(7),
          ],
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
          onSubmitted: (_) => onSubmitted?.call(),
        ),
      ],
    );
  }
}

/// OTP-style row of character boxes for fixed-length codes (e.g. HRE001).
class CharacterCodeField extends StatefulWidget {
  const CharacterCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.groupAfter = 3,
    this.errorText,
    this.autofocus = true,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  /// Insert a visual gap after this many characters (0 = no gap).
  final int groupAfter;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCompleted;

  @override
  State<CharacterCodeField> createState() => _CharacterCodeFieldState();
}

class _CharacterCodeFieldState extends State<CharacterCodeField> {
  late final FocusNode _focusNode;

  static const _boxSize = 48.0;
  static const _boxGap = 6.0;
  static const _groupGap = 12.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleChanged(String raw) {
    var cleaned =
        raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.length > widget.length) {
      cleaned = cleaned.substring(0, widget.length);
    }

    if (cleaned != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }

    widget.onChanged?.call(cleaned);
    if (cleaned.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.toUpperCase();
    final hasError = widget.errorText != null;
    final focused = _focusNode.hasFocus;
    final activeIndex = code.length.clamp(0, widget.length - 1);

    final boxes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (widget.groupAfter > 0 && i == widget.groupAfter) ...[
            SizedBox(
              width: _groupGap,
              child: Center(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasError
                        ? AppColors.error.withValues(alpha: 0.55)
                        : AppColors.brandGold.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ],
          _CharacterBox(
            char: i < code.length ? code[i] : null,
            isActive: focused && !hasError && i == activeIndex,
            hasError: hasError,
            isFilled: i < code.length,
            size: _boxSize,
          ),
          if (i < widget.length - 1 &&
              !(widget.groupAfter > 0 && i + 1 == widget.groupAfter))
            const SizedBox(width: _boxGap),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Scales down on narrow screens so the row never overflows.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: boxes,
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    maxLength: widget.length,
                    enableInteractiveSelection: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9]'),
                      ),
                      LengthLimitingTextInputFormatter(widget.length),
                      _UpperCaseTextFormatter(),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _handleChanged,
                    onSubmitted: (_) {
                      if (code.length == widget.length) {
                        widget.onCompleted?.call();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    widget.errorText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CharacterBox extends StatelessWidget {
  const _CharacterBox({
    required this.char,
    required this.isActive,
    required this.hasError,
    required this.isFilled,
    required this.size,
  });

  final String? char;
  final bool isActive;
  final bool hasError;
  final bool isFilled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color fillColor;
    final List<BoxShadow>? shadows;

    if (hasError) {
      borderColor = AppColors.error;
      fillColor = AppColors.error.withValues(alpha: 0.06);
      shadows = [
        BoxShadow(
          color: AppColors.error.withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (isActive) {
      borderColor = AppColors.brandRed;
      fillColor = AppColors.brandRed.withValues(alpha: 0.07);
      shadows = [
        BoxShadow(
          color: AppColors.brandRed.withValues(alpha: 0.22),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isFilled) {
      borderColor = AppColors.charcoal.withValues(alpha: 0.22);
      fillColor = AppColors.surfaceMuted;
      shadows = [
        BoxShadow(
          color: AppColors.charcoal.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      borderColor = AppColors.border;
      fillColor = AppColors.surface;
      shadows = [
        BoxShadow(
          color: AppColors.charcoal.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: size,
      height: size + 8,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 2.25 : 1.5,
        ),
        boxShadow: shadows,
      ),
      child: char == null
          ? (isActive ? const _BlinkCaret() : const SizedBox.shrink())
          : TweenAnimationBuilder<double>(
              key: ValueKey(char),
              tween: Tween(begin: 0.72, end: 1),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Text(
                char!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: 0,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
              ),
            ),
    );
  }
}

class _BlinkCaret extends StatefulWidget {
  const _BlinkCaret();

  @override
  State<_BlinkCaret> createState() => _BlinkCaretState();
}

class _BlinkCaretState extends State<_BlinkCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.brandRed,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.pinLength,
    required this.maxLength,
    required this.onDigit,
    required this.onDelete,
    this.error = false,
  });

  final int pinLength;
  final int maxLength;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxLength, (i) {
            final filled = i < pinLength;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (error ? AppColors.error : AppColors.brandRed)
                    : AppColors.border,
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildPad(context),
      ],
    );
  }

  Widget _buildPad(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 56);
              }
              if (key == 'del') {
                return _KeyButton(
                  label: '',
                  icon: Icons.backspace_outlined,
                  onTap: onDelete,
                );
              }
              return _KeyButton(
                label: key,
                onTap: () => onDigit(int.parse(key)),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, this.icon, required this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: 72,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: icon != null
              ? Icon(icon, color: AppColors.textPrimary)
              : Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'synced' => (AppColors.success, 'Synced'),
      'syncing' => (AppColors.syncing, 'Syncing'),
      'failed' => (AppColors.error, 'Failed'),
      _ => (AppColors.pendingSync, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontSize: 11,
            ),
      ),
    );
  }
}

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.status});

  final ConnectivityStatus status;

  @override
  Widget build(BuildContext context) {
    final styled = switch (status) {
      ConnectivityStatus.offline => (
          AppColors.offline,
          'Offline — tickets save locally and sync when connected',
          Icons.cloud_off_outlined,
        ),
      ConnectivityStatus.serverUnreachable => (
          AppColors.warning,
          'Network available but server unreachable',
          Icons.cloud_queue_outlined,
        ),
      ConnectivityStatus.syncing => (
          AppColors.syncing,
          'Syncing pending items…',
          Icons.sync,
        ),
      ConnectivityStatus.online => null,
    };

    if (styled == null) return const SizedBox.shrink();

    final (color, message, icon) = styled;

    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppColors.brandRed : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: highlight ? AppColors.brandRed : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlight
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: highlight ? Colors.white : AppColors.brandRed,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: highlight ? Colors.white : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: highlight
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: highlight ? Colors.white : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
