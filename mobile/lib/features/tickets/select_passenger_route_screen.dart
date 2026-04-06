import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/app_typography.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/app_button.dart';
import '../../data/dto/trip_dto.dart';
import 'issue_ticket_screen.dart';

/// Select Passenger Route Screen
/// 
/// Allows conductor to specify passenger's origin and destination
/// This is different from the trip route - passengers may board/alight at different stops
class SelectPassengerRouteScreen extends ConsumerStatefulWidget {
  final TripDto activeTrip;

  const SelectPassengerRouteScreen({
    super.key,
    required this.activeTrip,
  });

  @override
  ConsumerState<SelectPassengerRouteScreen> createState() => _SelectPassengerRouteScreenState();
}

class _SelectPassengerRouteScreenState extends ConsumerState<SelectPassengerRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  
  bool _isLoadingRoutes = false;
  List<RouteDto> _availableRoutes = [];
  RouteDto? _selectedRoute;
  
  @override
  void initState() {
    super.initState();
    _loadRoutes();
    // Pre-fill with trip route as defaults
    if (widget.activeTrip.route != null) {
      _originController.text = widget.activeTrip.route!.origin;
      _destinationController.text = widget.activeTrip.route!.destination;
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final routes = await tripRepo.getRoutes();
      
      if (mounted) {
        setState(() {
          _availableRoutes = routes;
          _isLoadingRoutes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
      }
    }
  }

  void _selectRoute(RouteDto route) {
    setState(() {
      _selectedRoute = route;
      _originController.text = route.origin;
      _destinationController.text = route.destination;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedRoute = null;
    });
  }

  void _proceedToIssueTicket() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();

    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => IssueTicketScreen(
          activeTrip: widget.activeTrip,
          passengerOrigin: origin,
          passengerDestination: destination,
        ),
      ),
    ).then((result) {
      // Pass result back to home screen
      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Passenger Route',
          style: AppTypography.headline2.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trip Info Card
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.route_rounded,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                                SizedBox(width: AppSpacing.xs.w),
                                Text(
                                  'Trip Route',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.xs.h),
                            Text(
                              '${widget.activeTrip.route?.origin} → ${widget.activeTrip.route?.destination}',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs.h),
                            Text(
                              'Fleet: ${widget.activeTrip.fleet?.number}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.xl.h),

                      // Instructions
                      Text(
                        'Select passenger boarding and alighting points',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs.h),
                      Text(
                        'Choose from existing routes or enter custom locations',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: AppSpacing.lg.h),

                      // Quick Select from Routes
                      if (_availableRoutes.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: AppColors.borderDefault),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                              child: Text(
                                'QUICK SELECT',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppColors.borderDefault),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        
                        Container(
                          constraints: BoxConstraints(maxHeight: 200.h),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _availableRoutes.length,
                            separatorBuilder: (context, index) => SizedBox(height: AppSpacing.sm.h),
                            itemBuilder: (context, index) {
                              final route = _availableRoutes[index];
                              final isSelected = _selectedRoute?.id == route.id;
                              
                              return InkWell(
                                onTap: () => _selectRoute(route),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacing.sm.w),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? AppColors.primary.withOpacity(0.1) 
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                                    border: Border.all(
                                      color: isSelected 
                                          ? AppColors.primary 
                                          : AppColors.borderDefault,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: isSelected 
                                            ? AppColors.primary 
                                            : AppColors.textSecondary,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: AppSpacing.sm.w),
                                      Expanded(
                                        child: Text(
                                          '${route.origin} → ${route.destination}',
                                          style: AppTypography.body2.copyWith(
                                            color: isSelected 
                                                ? AppColors.primary 
                                                : AppColors.textPrimary,
                                            fontWeight: isSelected 
                                                ? FontWeight.w600 
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 20.sp,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: AppSpacing.lg.h),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: AppColors.borderDefault),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                              child: Text(
                                'OR CUSTOM ENTRY',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppColors.borderDefault),
                            ),
                          ],
                        ),

                        SizedBox(height: AppSpacing.md.h),
                      ],

                      // Origin Input
                      Text(
                        'Boarding Point (Origin)',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      TextFormField(
                        controller: _originController,
                        decoration: InputDecoration(
                          hintText: 'Enter boarding location',
                          prefixIcon: Icon(Icons.trip_origin_rounded),
                          suffixIcon: _selectedRoute != null
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 20.sp),
                                  onPressed: () {
                                    _clearSelection();
                                    _originController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.error),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => _clearSelection(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter boarding location';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: AppSpacing.lg.h),

                      // Destination Input
                      Text(
                        'Alighting Point (Destination)',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      TextFormField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Enter alighting location',
                          prefixIcon: Icon(Icons.place_rounded),
                          suffixIcon: _selectedRoute != null
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 20.sp),
                                  onPressed: () {
                                    _clearSelection();
                                    _destinationController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            borderSide: BorderSide(color: AppColors.error),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => _clearSelection(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter alighting location';
                          }
                          if (value.trim() == _originController.text.trim()) {
                            return 'Destination must be different from origin';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: AppSpacing.xxl.h),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Button
            Container(
              padding: EdgeInsets.all(AppSpacing.lg.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: AppButton(
                  text: 'Continue Issue Ticket',
                  onPressed: _proceedToIssueTicket,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
