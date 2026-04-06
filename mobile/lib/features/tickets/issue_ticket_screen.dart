import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/app_typography.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/app_button.dart';
import '../../data/dto/ticket_dto.dart';
import '../../data/dto/trip_dto.dart';

/// Issue Ticket Screen
/// 
/// Allows agents to issue tickets for an active trip
/// Supports:
/// - Passenger only
/// - Passenger + Luggage (paired)
/// - Offline-first operation
class IssueTicketScreen extends ConsumerStatefulWidget {
  final TripDto activeTrip;
  final String passengerOrigin;
  final String passengerDestination;

  const IssueTicketScreen({
    super.key,
    required this.activeTrip,
    required this.passengerOrigin,
    required this.passengerDestination,
  });

  @override
  ConsumerState<IssueTicketScreen> createState() => _IssueTicketScreenState();
}

class _IssueTicketScreenState extends ConsumerState<IssueTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String _ticketType = TicketCategory.passenger; // PASSENGER, PASSENGER_WITH_LUGGAGE, or LUGGAGE
  String _currency = Currency.usd;
  bool _isSubmitting = false;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results is List
          ? results.any((result) => result != ConnectivityResult.none)
          : results != ConnectivityResult.none;
      
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult is List
        ? connectivityResult.any((result) => result != ConnectivityResult.none)
        : connectivityResult != ConnectivityResult.none;
    
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _issueTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ticketRepo = ref.read(ticketRepositoryProvider);
      final amount = double.parse(_amountController.text);
      
      // Determine if trip ID is local or server
      final isLocalTripId = widget.activeTrip.startedOffline ?? false;

      // Issue ticket with selected category
      final ticket = await ticketRepo.issueTicket(
        tripId: widget.activeTrip.id,
        isTripLocalId: isLocalTripId,
        ticketCategory: _ticketType,
        currency: _currency,
        amount: amount,
        departure: widget.passengerOrigin,
        destination: widget.passengerDestination,
      );

      if (mounted) {
        final ticketTypeLabel = _ticketType == TicketCategory.passenger 
            ? 'Passenger'
            : _ticketType == TicketCategory.passengerWithLuggage
              ? 'Passenger + Luggage'
              : 'Luggage';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isOnline 
                  ? '✅ $ticketTypeLabel ticket issued'
                  : '✅ $ticketTypeLabel ticket saved (will sync later)',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to issue ticket: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
          'Issue Ticket',
          style: AppTypography.headline2.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connectivity status
                if (!_isOnline)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm.w),
                    margin: EdgeInsets.only(bottom: AppSpacing.md.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.warning,
                          size: 20.sp,
                        ),
                        SizedBox(width: AppSpacing.xs.w),
                        Expanded(
                          child: Text(
                            'Offline Mode - Ticket will be saved and synced later',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Passenger Route Card
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
                      Text(
                        'Passenger Route',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs.h),
                      Text(
                        '${widget.passengerOrigin} → ${widget.passengerDestination}',
                        style: AppTypography.headline2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm.h),
                      Divider(color: AppColors.primary.withOpacity(0.2)),
                      SizedBox(height: AppSpacing.xs.h),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_bus_rounded,
                            color: AppColors.textSecondary,
                            size: 16.sp,
                          ),
                          SizedBox(width: AppSpacing.xs.w),
                          Text(
                            'Trip Route: ${widget.activeTrip.route?.origin} → ${widget.activeTrip.route?.destination}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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

                // Ticket Type Selection
                Text(
                  'Ticket Type',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                
                _buildTicketTypeOption(
                  value: TicketCategory.passenger,
                  label: 'Passenger Only',
                  icon: Icons.person_rounded,
                  description: 'For passenger travel only',
                ),
                SizedBox(height: AppSpacing.sm.h),
                _buildTicketTypeOption(
                  value: TicketCategory.passengerWithLuggage,
                  label: 'Passenger + Luggage',
                  icon: Icons.luggage_rounded,
                  description: 'Passenger traveling with luggage',
                ),
                SizedBox(height: AppSpacing.sm.h),
                _buildTicketTypeOption(
                  value: TicketCategory.luggage,
                  label: 'Luggage Only',
                  icon: Icons.work_outline_rounded,
                  description: 'Luggage sent without passenger',
                ),

                SizedBox(height: AppSpacing.xl.h),

                // Currency Selection
                Text(
                  'Currency',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildCurrencyOption(Currency.usd, 'USD'),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Expanded(
                      child: _buildCurrencyOption(Currency.zwl, 'ZWL'),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.xl.h),

                // Amount Input
                Text(
                  'Amount',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    prefixIcon: Icon(Icons.payments_rounded),
                    prefixText: _currency == Currency.usd ? '\$' : 'ZWL ',
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount greater than 0';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.xxl.h),

                // Issue Button
                AppButton(
                  text: _isSubmitting 
                      ? 'Issuing...' 
                      : (_ticketType == 'passenger' ? 'Issue Ticket' : 'Issue Tickets'),
                  onPressed: _isSubmitting ? null : _issueTicket,
                  icon: Icons.confirmation_number_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketTypeOption({
    required String value,
    required String label,
    required IconData icon,
    String? description,
  }) {
    final isSelected = _ticketType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _ticketType = value;
        });
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24.sp,
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body1.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String currency, String label) {
    final isSelected = _currency == currency;
    return InkWell(
      onTap: () {
        setState(() {
          _currency = currency;
        });
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body1.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
