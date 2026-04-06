import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/config/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Login Step 1: Agent Identification
/// Enter merchant code and agent code
class LoginCodesScreen extends StatefulWidget {
  const LoginCodesScreen({super.key});

  @override
  State<LoginCodesScreen> createState() => _LoginCodesScreenState();
}

class _LoginCodesScreenState extends State<LoginCodesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantCodeController = TextEditingController();
  final _agentCodeController = TextEditingController();
  bool _isOffline = false; // TODO: Check actual connectivity

  @override
  void dispose() {
    _merchantCodeController.dispose();
    _agentCodeController.dispose();
    super.dispose();
  }

  void _continueToPin() {
    if (!_formKey.currentState!.validate()) return;

    // Navigate to PIN screen with codes using AppRouter
    // Trim and normalize inputs to prevent whitespace issues
    Navigator.of(context).pushNamed(
      '/login/pin',
      arguments: {
        'merchantCode': _merchantCodeController.text.trim().toUpperCase(),
        'agentCode': _agentCodeController.text.trim().toUpperCase(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Agent Login',
          style: AppTypography.title1.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.pagePadding.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Offline Banner
                if (_isOffline)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm.w),
                    margin: EdgeInsets.only(bottom: AppSpacing.md.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      border: Border.all(color: AppColors.warning, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.warning,
                          size: AppSpacing.iconMedium.sp,
                        ),
                        SizedBox(width: AppSpacing.sm.w),
                        Expanded(
                          child: Text(
                            'Offline Mode - Using cached data',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: AppSpacing.lg.h),
                
                // Logo
                Center(
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      size: 60.sp,
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
                
                SizedBox(height: AppSpacing.xl.h),
                
                // Title
                Text(
                  'Identify Yourself',
                  style: AppTypography.headline1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppSpacing.sm.h),
                
                // Subtitle
                Text(
                  'Step 1 of 2: Enter your codes',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppSpacing.xxl.h),
                
                // Merchant Code Input
                AppTextField(
                  label: 'Merchant Code',
                  hint: 'HRE001',
                  controller: _merchantCodeController,
                  autoUppercase: true,
                  maxLength: 6,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter merchant code';
                    }
                    if (value.length != 6) {
                      return 'Merchant code must be 6 characters';
                    }
                    return null;
                  },
                  onSubmitted: (_) {
                    // Focus next field
                    FocusScope.of(context).nextFocus();
                  },
                ),
                
                SizedBox(height: AppSpacing.lg.h),
                
                // Agent Code Input
                AppTextField(
                  label: 'Agent Code',
                  hint: 'TMO014',
                  controller: _agentCodeController,
                  autoUppercase: true,
                  maxLength: 6,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter agent code';
                    }
                    if (value.length != 6) {
                      return 'Agent code must be 6 characters';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _continueToPin(),
                ),
                
                SizedBox(height: AppSpacing.xxl.h),
                
                // Continue Button
                AppButton(
                  text: 'Continue to PIN',
                  onPressed: _continueToPin,
                  icon: Icons.arrow_forward_rounded,
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
                          'Merchant: HRE001',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Agent: TMO014 or FNC015',
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
