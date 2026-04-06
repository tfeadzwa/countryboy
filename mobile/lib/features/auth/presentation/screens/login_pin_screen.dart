import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/config/app_typography.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/network/api_error.dart';
import '../../../../shared/widgets/app_button.dart';

/// Login Step 2: PIN Entry
/// Large numeric keypad for entering agent PIN
class LoginPinScreen extends ConsumerStatefulWidget {
  final String merchantCode;
  final String agentCode;

  const LoginPinScreen({
    super.key,
    required this.merchantCode,
    required this.agentCode,
  });

  @override
  ConsumerState<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends ConsumerState<LoginPinScreen> {
  String _pin = '';
  bool _isLoading = false;
  final int _pinLength = 4; // Can be 4-6 digits
  bool _isOnline = true;
  bool _offlineLoginAvailable = false;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _checkOfflineAvailability();
    
    // Listen to real-time connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        // Handle both single ConnectivityResult and List<ConnectivityResult>
        final isConnected = results is List
            ? results.any((result) => result != ConnectivityResult.none)
            : results != ConnectivityResult.none;
        
        setState(() {
          _isOnline = isConnected;
        });
        debugPrint('📡 Connectivity changed: ${isConnected ? "ONLINE" : "OFFLINE"}');
      }
    });
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // Handle both single ConnectivityResult and List<ConnectivityResult>
    final isConnected = connectivityResult is List
        ? connectivityResult.any((result) => result != ConnectivityResult.none)
        : connectivityResult != ConnectivityResult.none;
    
    setState(() {
      _isOnline = isConnected;
    });
    debugPrint('📡 Initial connectivity: ${isConnected ? "ONLINE" : "OFFLINE"}');
  }

  void _checkOfflineAvailability() {
    final authRepo = ref.read(authRepositoryProvider);
    if (mounted) {
      setState(() {
        _offlineLoginAvailable = authRepo.isOfflineLoginEnabled();
      });
    }
  }

  void _onNumberPressed(int number) {
    if (_pin.length >= 6) return; // Max 6 digits
    
    setState(() {
      _pin += number.toString();
    });

    // Auto-submit when PIN is complete (4-6 digits)
    if (_pin.length >= _pinLength) {
      _submitPin();
    }
  }

  void _onDeletePressed() {
    if (_pin.isEmpty) return;
    
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClearPressed() {
    setState(() {
      _pin = '';
    });
  }

  Future<void> _submitPin() async {
    if (_pin.length < _pinLength) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      // Automatically use offline login if offline and available
      if (!_isOnline && _offlineLoginAvailable) {
        await _submitPinOffline();
        return;
      }
      
      // Online login
      final response = await authRepo.login(
        merchantCode: widget.merchantCode,
        agentCode: widget.agentCode,
        pin: _pin,
      );
      
      if (mounted) {
        // Automatically enable offline login on successful login
        try {
          debugPrint('💾 Saving offline credentials...');
          debugPrint('   Merchant: "${widget.merchantCode}"');
          debugPrint('   Agent: "${widget.agentCode}"');
          debugPrint('   PIN length: ${_pin.length}');
          
          await authRepo.enableOfflineLogin(
            merchantCode: widget.merchantCode,
            agentCode: widget.agentCode,
            pin: _pin,
          );
          
          // Verify it was saved successfully by checking immediately
          final isEnabled = authRepo.isOfflineLoginEnabled();
          if (isEnabled) {
            debugPrint('✅ Offline credentials saved successfully');
            // Update local state
            setState(() {
              _offlineLoginAvailable = true;
            });
          } else {
            debugPrint('⚠️ Offline credentials may not have been saved');
          }
        } catch (e) {
          debugPrint('❌ Error saving offline credentials: $e');
          // Show warning but don't block login
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Note: Offline login setup incomplete'),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${response.agent.firstName}!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on ApiError catch (error) {
      if (mounted) {
        // Clear PIN on error
        setState(() {
          _pin = '';
          _isLoading = false;
        });
        
        // If network error and offline is available, try offline automatically
        if (error.type == ApiErrorType.network && _offlineLoginAvailable) {
          // Automatically retry with offline login
          await _submitPinOffline();
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Clear PIN on error
        setState(() {
          _pin = '';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitPinOffline() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      debugPrint('🔍 Attempting offline login...');
      debugPrint('   Merchant: "${widget.merchantCode}"');
      debugPrint('   Agent: "${widget.agentCode}"');
      debugPrint('   PIN length: ${_pin.length}');
      debugPrint('   Offline enabled: ${authRepo.isOfflineLoginEnabled()}');
      
      final success = await authRepo.loginOffline(
        merchantCode: widget.merchantCode,
        agentCode: widget.agentCode,
        pin: _pin,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged in offline successfully'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on ApiError catch (error) {
      if (mounted) {
        setState(() {
          _pin = '';
          _isLoading = false;
        });
        
        debugPrint('❌ Offline login error: ${error.message}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message == 'Invalid offline credentials'
              ? 'Please login online first to enable offline access'
              : error.message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Enter PIN',
          style: AppTypography.title1.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          iconSize: AppSpacing.iconMedium.sp,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding.w),
          child: Column(
            children: [
              // Online/Offline Status Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md.w,
                  vertical: AppSpacing.sm.h,
                ),
                decoration: BoxDecoration(
                  color: _isOnline 
                    ? AppColors.success.withOpacity(0.1) 
                    : (_offlineLoginAvailable 
                        ? AppColors.warning.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: _isOnline 
                      ? AppColors.success 
                      : (_offlineLoginAvailable 
                          ? AppColors.warning
                          : AppColors.error),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: AppSpacing.iconMedium.sp,
                      color: _isOnline 
                        ? AppColors.success 
                        : (_offlineLoginAvailable 
                            ? AppColors.warning
                            : AppColors.error),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Text(
                      _isOnline 
                        ? 'Online Mode' 
                        : (_offlineLoginAvailable
                            ? 'Offline Mode - Using Saved Credentials'
                            : 'No Internet - Online Login Required'),
                      style: AppTypography.body2.copyWith(
                        color: _isOnline 
                          ? AppColors.success 
                          : (_offlineLoginAvailable 
                              ? AppColors.warning
                              : AppColors.error),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppSpacing.lg.h),
              
              // Agent Info
              Text(
                widget.agentCode,
                style: AppTypography.headline1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                'Merchant: ${widget.merchantCode}',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              SizedBox(height: AppSpacing.xl.h),
              
              // Step Indicator
              Text(
                'Step 2 of 2: Enter your PIN',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              SizedBox(height: AppSpacing.xxl.h),
              
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 20.w,
                    height: 20.w,
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? AppColors.primary
                          : AppColors.borderDefault,
                      border: Border.all(
                        color: AppColors.borderDefault,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: AppSpacing.xxl.h),
              
              // Numeric Keypad or Loading with Status
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: AppSpacing.md.h),
                            Text(
                              _isOnline ? 'Logging in online...' : 'Logging in offline...',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildKeypad(),
              ),
              
              SizedBox(height: AppSpacing.md.h),
              
              // Clear Button
              AppButton(
                text: 'Clear PIN',
                onPressed: _pin.isEmpty ? null : _onClearPressed,
                type: ButtonType.secondary,
                size: ButtonSize.medium,
              ),
              
              SizedBox(height: AppSpacing.sm.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton('1', () => _onNumberPressed(1)),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton('2', () => _onNumberPressed(2)),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton('3', () => _onNumberPressed(3)),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        
        // Row 2: 4, 5, 6
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton('4', () => _onNumberPressed(4)),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton('5', () => _onNumberPressed(5)),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton('6', () => _onNumberPressed(6)),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        
        // Row 3: 7, 8, 9
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton('7', () => _onNumberPressed(7)),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton('8', () => _onNumberPressed(8)),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton('9', () => _onNumberPressed(9)),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        
        // Row 4: Delete, 0, Submit
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton(
                'DEL',
                _onDeletePressed,
                icon: Icons.backspace_outlined,
                isSpecial: true,
              ),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton('0', () => _onNumberPressed(0)),
              SizedBox(width: AppSpacing.md.w),
              _buildKeypadButton(
                'OK',
                _pin.length >= _pinLength ? _submitPin : null,
                icon: Icons.check_rounded,
                isSuccess: true,
                isSpecial: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(
    String label,
    VoidCallback? onPressed, {
    IconData? icon,
    bool isSpecial = false,
    bool isSuccess = false,
  }) {
    final isEnabled = onPressed != null;
    
    Color backgroundColor = AppColors.surface;
    Color foregroundColor = AppColors.textPrimary;
    
    if (isSuccess && isEnabled) {
      backgroundColor = AppColors.success;
      foregroundColor = AppColors.textInverse;
    } else if (isSpecial) {
      backgroundColor = AppColors.primary.withOpacity(0.1);
      foregroundColor = AppColors.primary;
    }
    
    return Expanded(
      child: Material(
        color: isEnabled ? backgroundColor : AppColors.buttonDisabled,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        elevation: isEnabled ? AppSpacing.elevationLow : 0,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isEnabled ? AppColors.borderDefault : AppColors.borderDefault.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      size: AppSpacing.iconLarge.sp,
                      color: isEnabled ? foregroundColor : AppColors.textHint,
                    )
                  : Text(
                      label,
                      style: AppTypography.keypadNumber.copyWith(
                        color: isEnabled ? foregroundColor : AppColors.textHint,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
