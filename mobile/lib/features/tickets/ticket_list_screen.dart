import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/app_typography.dart';
import '../../core/providers/providers.dart';
import '../../data/dto/ticket_dto.dart';
import '../../data/dto/trip_dto.dart';
import 'package:intl/intl.dart';

/// Ticket List Screen
/// 
/// Displays all issued tickets for the active trip
/// Offline-first: Shows local tickets immediately, syncs with API when online
class TicketListScreen extends ConsumerStatefulWidget {
  final TripDto activeTrip;

  const TicketListScreen({
    super.key,
    required this.activeTrip,
  });

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  bool _isLoading = true;
  bool _isOnline = true;
  List<TicketDto> _tickets = [];
  String? _errorMessage;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadTickets();
    
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

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticketRepo = ref.read(ticketRepositoryProvider);
      final isLocalTripId = widget.activeTrip.startedOffline;
      
      final tickets = await ticketRepo.getTicketsByTrip(
        widget.activeTrip.id,
        isLocalTripId,
      );

      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  String _formatCurrency(String currency, double amount) {
    if (currency == Currency.usd) {
      return '\$${amount.toStringAsFixed(2)}';
    } else {
      return 'ZWL ${amount.toStringAsFixed(2)}';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case TicketCategory.passenger:
        return AppColors.primary;
      case TicketCategory.passengerWithLuggage:
        return AppColors.success; // Green for combined ticket
      case TicketCategory.luggage:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case TicketCategory.passenger:
        return Icons.person_rounded;
      case TicketCategory.passengerWithLuggage:
        return Icons.people_alt_rounded; // Different icon for combined
      case TicketCategory.luggage:
        return Icons.luggage_rounded;
      default:
        return Icons.confirmation_number_rounded;
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
          'Issued Tickets',
          style: AppTypography.headline2.copyWith(
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _loadTickets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Trip Info Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
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
                      Expanded(
                        child: Text(
                          '${widget.activeTrip.route?.origin} → ${widget.activeTrip.route?.destination}',
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  Row(
                    children: [
                      Text(
                        'Fleet: ${widget.activeTrip.fleet?.number}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md.w),
                      if (!_isOnline)
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.warning,
                              size: 14.sp,
                            ),
                            SizedBox(width: AppSpacing.xs.w),
                            Text(
                              'Offline',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Tickets List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: AppSpacing.md.h),
                          Text(
                            'Loading tickets...',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 48.sp,
                                ),
                                SizedBox(height: AppSpacing.md.h),
                                Text(
                                  'Failed to load tickets',
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.sm.h),
                                Text(
                                  _errorMessage!,
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _tickets.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.lg.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.textSecondary,
                                      size: 64.sp,
                                    ),
                                    SizedBox(height: AppSpacing.md.h),
                                    Text(
                                      'No tickets issued yet',
                                      style: AppTypography.headline2.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.sm.h),
                                    Text(
                                      'Tickets you issue will appear here',
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTickets,
                              color: AppColors.primary,
                              child: ListView.separated(
                                padding: EdgeInsets.all(AppSpacing.md.w),
                                itemCount: _tickets.length,
                                separatorBuilder: (context, index) => 
                                    SizedBox(height: AppSpacing.sm.h),
                                itemBuilder: (context, index) {
                                  final ticket = _tickets[index];
                                  return _buildTicketCard(ticket);
                                },
                              ),
                            ),
            ),

            // Summary Footer
            if (_tickets.isNotEmpty)
              Container(
                padding: EdgeInsets.all(AppSpacing.md.w),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Total Tickets',
                        '${_tickets.length}',
                        Icons.confirmation_number_rounded,
                      ),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: AppColors.borderDefault,
                      ),
                      _buildSummaryItem(
                        'Total Revenue',
                        _calculateTotalRevenue(),
                        Icons.payments_rounded,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(TicketDto ticket) {
    final categoryColor = _getCategoryColor(ticket.ticketCategory);
    final categoryIcon = _getCategoryIcon(ticket.ticketCategory);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: BorderSide(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category & Amount
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.xs.w),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Text(
                    ticket.ticketCategory,
                    style: AppTypography.body1.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatCurrency(ticket.currency, ticket.amount),
                  style: AppTypography.headline2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.sm.h),
            Divider(color: AppColors.borderDefault),
            SizedBox(height: AppSpacing.sm.h),

            // Route Info
            if (ticket.departure != null && ticket.destination != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.textSecondary,
                    size: 16.sp,
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Expanded(
                    child: Text(
                      '${ticket.departure} → ${ticket.destination}',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs.h),
            ],

            // Issued Time
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: AppColors.textSecondary,
                  size: 16.sp,
                ),
                SizedBox(width: AppSpacing.xs.w),
                Text(
                  _formatDateTime(ticket.issuedAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Serial Number (if assigned)
            if (ticket.serialNumber != null) ...[
              SizedBox(height: AppSpacing.xs.h),
              Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    color: AppColors.textSecondary,
                    size: 16.sp,
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Text(
                    'Serial: ${ticket.serialNumber}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            // Linked Ticket Info (for luggage)
            if (ticket.linkedPassengerTicketId != null) ...[
              SizedBox(height: AppSpacing.xs.h),
              Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    color: AppColors.textSecondary,
                    size: 16.sp,
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Text(
                    'Linked to passenger ticket',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 20.sp,
            ),
            SizedBox(width: AppSpacing.xs.w),
            Text(
              value,
              style: AppTypography.headline2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _calculateTotalRevenue() {
    if (_tickets.isEmpty) return '\$0.00';

    // Group by currency
    final usdTotal = _tickets
        .where((t) => t.currency == Currency.usd)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final zwlTotal = _tickets
        .where((t) => t.currency == Currency.zwl)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (usdTotal > 0 && zwlTotal > 0) {
      return '\$${usdTotal.toStringAsFixed(2)} + ZWL ${zwlTotal.toStringAsFixed(2)}';
    } else if (usdTotal > 0) {
      return '\$${usdTotal.toStringAsFixed(2)}';
    } else {
      return 'ZWL ${zwlTotal.toStringAsFixed(2)}';
    }
  }
}
