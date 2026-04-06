import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/config/app_typography.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/network/api_error.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Device Pairing Screen
/// First-time setup screen where admin pairs the device with a pairing code
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pairDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.pairDevice(_codeController.text);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to login screen after successful pairing
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pairing failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pasteCode() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      _codeController.text = clipboardData.text!.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.pagePadding.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.xxl.h),
                
                // App Logo/Icon
                Center(
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      size: 72.sp,
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
                
                SizedBox(height: AppSpacing.xl.h),
                
                // Title
                Text(
                  'Device Pairing',
                  style: AppTypography.display2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppSpacing.sm.h),
                
                // Subtitle
                Text(
                  'Enter the 6-character pairing code provided by your administrator',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppSpacing.xxl.h),
                
                // Pairing Code Input
                AppTextField(
                  label: 'Pairing Code',
                  hint: 'ABC123',
                  controller: _codeController,
                  autoUppercase: true,
                  maxLength: 6,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pairing code';
                    }
                    if (value.length != 6) {
                      return 'Pairing code must be 6 characters';
                    }
                    return null;
                  },
                  suffix: IconButton(
                    icon: const Icon(Icons.content_paste),
                    onPressed: _pasteCode,
                    tooltip: 'Paste from clipboard',
                  ),
                ),
                
                SizedBox(height: AppSpacing.xl.h),
                
                // Pair Button
                AppButton(
                  text: 'Pair Device',
                  onPressed: _isLoading ? null : _pairDevice,
                  isLoading: _isLoading,
                  icon: Icons.link_rounded,
                ),
                
                SizedBox(height: AppSpacing.xxl.h),
                
                // Info Card
                Container(
                  padding: EdgeInsets.all(AppSpacing.md.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(color: AppColors.borderDefault, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: AppSpacing.iconMedium.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      Text(
                        'First Time Setup',
                        style: AppTypography.title2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.xs.h),
                      Text(
                        'This is a one-time setup. Once paired, this device will be registered for use by agents in your depot.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppSpacing.xl.h),
                
                // Test Codes (DEBUG only - remove in production)
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TEST CODES (Debug Only)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxs.h),
                        Text(
                          'ABC234 or XYZ789',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
