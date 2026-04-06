import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/app_typography.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/app_button.dart';
import '../../data/dto/trip_dto.dart';

/// Start Trip Screen
/// 
/// Allows agents to start a new trip by selecting:
/// - Fleet (bus/vehicle)
/// - Route (origin → destination)
class StartTripScreen extends ConsumerStatefulWidget {
  const StartTripScreen({super.key});

  @override
  ConsumerState<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends ConsumerState<StartTripScreen> {
  FleetDto? _selectedFleet;
  RouteDto? _selectedRoute;
  bool _isLoading = false;
  String? _errorMessage;

  /// Show dialog to manually add a new fleet vehicle
  Future<void> _showAddFleetDialog() async {
    final controller = TextEditingController();
    String? dialogError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add New Fleet Vehicle',
            style: AppTypography.headline2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the vehicle registration number',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                TextField(
                  controller: controller,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Fleet Number',
                    hintText: 'e.g., ABC-123',
                    border: OutlineInputBorder(),
                    errorText: dialogError,
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textHint),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  enabled: !isSubmitting,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: AppTypography.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final fleetNumber = controller.text.trim();
                      if (fleetNumber.isEmpty) {
                        setDialogState(() {
                          dialogError = 'Fleet number is required';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        dialogError = null;
                      });

                      try {
                        final tripRepo = ref.read(tripRepositoryProvider);
                        final newFleet = await tripRepo.createFleet(fleetNumber);

                        if (mounted) {
                          Navigator.pop(dialogContext);

                          // Refresh fleet list
                          ref.invalidate(availableFleetsProvider);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fleet ${newFleet.number} added successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                          String errorMsg = e.toString().replaceAll('Exception: ', '');
                          dialogError = errorMsg.isEmpty ? 'Failed to add fleet' : errorMsg;
                        });
                      }
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Add Fleet'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to manually add a new route
  Future<void> _showAddRouteDialog() async {
    final originController = TextEditingController();
    final destinationController = TextEditingController();
    String? dialogError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add New Route',
            style: AppTypography.headline2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter route details',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                TextField(
                  controller: originController,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Origin',
                    hintText: 'e.g., Harare',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textHint),
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !isSubmitting,
                ),
                SizedBox(height: AppSpacing.md.h),
                TextField(
                  controller: destinationController,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    hintText: 'e.g., Bulawayo',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textHint),
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !isSubmitting,
                ),
                if (dialogError != null) ...[
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    dialogError!,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: AppTypography.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final origin = originController.text.trim();
                      final destination = destinationController.text.trim();

                      if (origin.isEmpty || destination.isEmpty) {
                        setDialogState(() {
                          dialogError = 'Both origin and destination are required';
                        });
                        return;
                      }

                      if (origin.toLowerCase() == destination.toLowerCase()) {
                        setDialogState(() {
                          dialogError = 'Origin and destination must be different';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        dialogError = null;
                      });

                      try {
                        final tripRepo = ref.read(tripRepositoryProvider);
                        final newRoute = await tripRepo.createRoute(origin, destination);

                        if (mounted) {
                          Navigator.pop(dialogContext);

                          // Refresh route list
                          ref.invalidate(availableRoutesProvider);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Route ${newRoute.displayName} added successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                          String errorMsg = e.toString().replaceAll('Exception: ', '');
                          dialogError = errorMsg.isEmpty ? 'Failed to add route' : errorMsg;
                        });
                      }
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Add Route'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTrip() async {
    // Validate selection
    if (_selectedFleet == null) {
      setState(() {
        _errorMessage = 'Please select a fleet vehicle';
      });
      return;
    }

    if (_selectedRoute == null) {
      setState(() {
        _errorMessage = 'Please select a route';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final trip = await tripRepo.startTrip(
        fleetId: _selectedFleet!.id,
        routeId: _selectedRoute!.id,
      );

      if (mounted) {
        // Invalidate active trip provider to refresh
        ref.invalidate(activeTripProvider);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip started successfully on Fleet ${_selectedFleet!.number}'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back to home
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Extract user-friendly message
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        // Remove any additional technical details
        errorMsg = errorMsg.split(':').first.trim();
        _errorMessage = errorMsg.isEmpty ? 'Unable to start trip. Please try again.' : errorMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fleetsAsync = ref.watch(availableFleetsProvider);
    final routesAsync = ref.watch(availableRoutesProvider);
    final fleetsCacheAge = ref.watch(fleetsCacheAgeProvider);
    final routesCacheAge = ref.watch(routesCacheAgeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Start New Trip',
          style: AppTypography.title1.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Container(
                padding: EdgeInsets.all(AppSpacing.md.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.sm.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Expanded(
                      child: Text(
                        'Select the fleet vehicle and route to start your trip',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.lg.h),

              // Cache indicators (show when using offline data)
              if (fleetsCacheAge.hasValue || routesCacheAge.hasValue)
                Column(
                  children: [
                    if (fleetsCacheAge.hasValue && fleetsCacheAge.value != null)
                      _buildCacheIndicator(fleetsCacheAge.value),
                    if (routesCacheAge.hasValue && 
                        routesCacheAge.value != null && 
                        fleetsCacheAge.value != routesCacheAge.value)
                      _buildCacheIndicator(routesCacheAge.value),
                  ],
                ),

              // Fleet Selection
              Text(
                'Select Fleet Vehicle',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              fleetsAsync.when(
                data: (fleets) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (fleets.isNotEmpty) ...[
                        _buildFleetDropdown(fleets),
                        SizedBox(height: AppSpacing.sm.h),
                        TextButton.icon(
                          onPressed: _showAddFleetDialog,
                          icon: Icon(Icons.add_circle_outline, size: 20.sp),
                          label: Text('Or add new fleet vehicle'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ] else ...[
                        _buildEmptyState('No fleet vehicles available'),
                        SizedBox(height: AppSpacing.sm.h),
                        ElevatedButton.icon(
                          onPressed: _showAddFleetDialog,
                          icon: Icon(Icons.add_circle_outline),
                          label: Text('Add Fleet Vehicle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => _buildLoadingState(),
                error: (error, _) {
                  String errorMsg = error.toString().replaceAll('Exception: ', '');
                  return _buildErrorState(errorMsg);
                },
              ),

              SizedBox(height: AppSpacing.lg.h),

              // Route Selection
              Text(
                'Select Route',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              routesAsync.when(
                data: (routes) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (routes.isNotEmpty) ...[
                        _buildRouteDropdown(routes),
                        SizedBox(height: AppSpacing.sm.h),
                        TextButton.icon(
                          onPressed: _showAddRouteDialog,
                          icon: Icon(Icons.add_circle_outline, size: 20.sp),
                          label: Text('Or add new route'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ] else ...[
                        _buildEmptyState('No routes available'),
                        SizedBox(height: AppSpacing.sm.h),
                        ElevatedButton.icon(
                          onPressed: _showAddRouteDialog,
                          icon: Icon(Icons.add_circle_outline),
                          label: Text('Add Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => _buildLoadingState(),
                error: (error, _) {
                  String errorMsg = error.toString().replaceAll('Exception: ', '');
                  return _buildErrorState(errorMsg);
                },
              ),

              SizedBox(height: AppSpacing.lg.h),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(AppSpacing.md.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(AppSpacing.sm.r),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 24.sp,
                      ),
                      SizedBox(width: AppSpacing.sm.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
              ],

              // Start Trip Button
              AppButton(
                text: 'Start Trip',
                onPressed: _isLoading ? null : _startTrip,
                isLoading: _isLoading,
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetDropdown(List<FleetDto> fleets) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FleetDto>(
          value: _selectedFleet,
          hint: Text(
            'Choose fleet vehicle',
            style: AppTypography.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          isExpanded: true,
          style: AppTypography.body1.copyWith(
            color: AppColors.textPrimary,
          ),
          dropdownColor: AppColors.surface,
          items: fleets.map((fleet) {
            return DropdownMenuItem<FleetDto>(
              value: fleet,
              child: Text(
                'Fleet ${fleet.number}',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (fleet) {
            setState(() {
              _selectedFleet = fleet;
              _errorMessage = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRouteDropdown(List<RouteDto> routes) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RouteDto>(
          value: _selectedRoute,
          hint: Text(
            'Choose route',
            style: AppTypography.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          isExpanded: true,
          style: AppTypography.body1.copyWith(
            color: AppColors.textPrimary,
          ),
          dropdownColor: AppColors.surface,
          items: routes.map((route) {
            return DropdownMenuItem<RouteDto>(
              value: route,
              child: Text(
                route.displayName,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (route) {
            setState(() {
              _selectedRoute = route;
              _errorMessage = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Text(
        message,
        style: AppTypography.body1.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppSpacing.sm.r),
        border: Border.all(color: AppColors.error),
      ),
      child: Text(
        error,
        style: AppTypography.body2.copyWith(
          color: AppColors.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build cache indicator widget
  /// Shows when data is loaded from local cache
  Widget _buildCacheIndicator(DateTime? lastCached) {
    if (lastCached == null) return const SizedBox.shrink();
    
    final age = DateTime.now().difference(lastCached);
    final ageText = _formatCacheAge(age);
    final isStale = age.inHours > 24;
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      decoration: BoxDecoration(
        color: isStale 
            ? AppColors.warning.withAlpha((0.1 * 255).round())
            : AppColors.info.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppSpacing.sm.r),
        border: Border.all(
          color: isStale ? AppColors.warning : AppColors.info,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStale ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 20.sp,
            color: isStale ? AppColors.warning : AppColors.info,
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              isStale
                  ? 'Using cached data ($ageText). Connect to internet to update.'
                  : 'Data cached $ageText',
              style: AppTypography.body2.copyWith(
                color: isStale ? AppColors.warning : AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format cache age for display
  String _formatCacheAge(Duration age) {
    if (age.inDays > 0) return '${age.inDays} day${age.inDays > 1 ? 's' : ''} ago';
    if (age.inHours > 0) return '${age.inHours} hour${age.inHours > 1 ? 's' : ''} ago';
    if (age.inMinutes > 0) return '${age.inMinutes} min ago';
    return 'just now';
  }
}
