import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../core/config/app_typography.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/app_button.dart';
import '../trips/start_trip_screen.dart';
import '../tickets/select_passenger_route_screen.dart';
import '../tickets/ticket_list_screen.dart';

/// Home Screen - Main dashboard for agents
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _refreshTimer;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Check connectivity
    _checkConnectivity();
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // Handle both single ConnectivityResult and List<ConnectivityResult>
      final isConnected = results is List
          ? results.any((result) => result != ConnectivityResult.none)
          : results != ConnectivityResult.none;
      
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
        debugPrint('📡 [HOME] Connectivity changed: ${isConnected ? "ONLINE" : "OFFLINE"}');
      }
    });
    
    // Check token refresh every 5 minutes
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkAndRefreshToken(),
    );
    // Also check on initial load
    Future.microtask(() => _checkAndRefreshToken());
  }
  
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // Handle both single ConnectivityResult and List<ConnectivityResult>
    final isConnected = connectivityResult is List
        ? connectivityResult.any((result) => result != ConnectivityResult.none)
        : connectivityResult != ConnectivityResult.none;
    
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
      });
      debugPrint('📡 [HOME] Initial connectivity: ${isConnected ? "ONLINE" : "OFFLINE"}');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAndRefreshToken() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final success = await authRepo.autoRefreshIfNeeded();
      
      if (!success && mounted) {
        // Token refresh failed - redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to login after short delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      // Silent failure - will retry on next interval
    }
  }

  void _triggerSync(int pendingCount) {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sync requires internet connection'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ All data is synced'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    // Trigger manual sync
    final syncService = ref.read(syncServiceProvider);
    syncService.syncPending();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 Syncing $pendingCount item${pendingCount > 1 ? 's' : ''}...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final authRepo = ref.read(authRepositoryProvider);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Logout',
          style: AppTypography.headline2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.body1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Logout',
              style: AppTypography.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Perform logout
      await authRepo.logout();
      
      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentAsync = ref.watch(currentAgentProvider);
    final activeTripAsync = ref.watch(activeTripProvider);
    final tripStats = ref.watch(tripStatsProvider);
    final pendingSyncAsync = ref.watch(pendingSyncCountProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Countryboy Ticketing',
          style: AppTypography.title1.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        actions: [
          // Online/Offline Status Badge
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: AppSpacing.xs.h,
                ),
                decoration: BoxDecoration(
                  color: _isOnline 
                    ? AppColors.success.withOpacity(0.2) 
                    : AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: _isOnline ? AppColors.success : AppColors.warning,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 16.sp,
                      color: _isOnline ? AppColors.success : AppColors.warning,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: AppTypography.caption.copyWith(
                        color: _isOnline ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Sync Button with Badge
          pendingSyncAsync.when(
            data: (pendingCount) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.sync_rounded),
                  onPressed: () => _triggerSync(pendingCount),
                  tooltip: 'Sync Data',
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w,
                        minHeight: 16.h,
                      ),
                      child: Center(
                        child: Text(
                          pendingCount > 9 ? '9+' : '$pendingCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            loading: () => IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: () => _triggerSync(0),
            ),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: () => _triggerSync(0),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context, ref),
            tooltip: 'Logout',
          ),
        ],
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.pagePadding.w),
            child: agentAsync.when(
              data: (agentData) {
                final agentName = agentData != null
                    ? '${agentData['first_name']} ${agentData['last_name']}'
                    : 'Agent';
                final merchantName = agentData?['merchant_name'] ?? '';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppSpacing.lg.h),
                    
                    // Welcome Message
                    Text(
                      'Welcome, $agentName!',
                      style: AppTypography.headline1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    SizedBox(height: AppSpacing.xs.h),
                    
                    Text(
                      merchantName,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                
                    SizedBox(height: AppSpacing.xxl.h),
                    
                    // Trip Status Section
                    activeTripAsync.when(
                      data: (activeTrip) {
                        if (activeTrip != null) {
                          return _buildActiveTripCard(context, ref, activeTrip, tripStats);
                        } else {
                          return _buildNoActiveTripCard(context);
                        }
                      },
                      loading: () => _buildLoadingCard(),
                      error: (_, __) => _buildNoActiveTripCard(context),
                    ),
                    
                    SizedBox(height: AppSpacing.xxl.h),
                    
                    // Quick Stats Card
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        border: Border.all(color: AppColors.borderDefault, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Tickets',
                                '${tripStats['tickets_count']}',
                                Icons.confirmation_number_rounded,
                              ),
                              Container(
                                width: 1,
                                height: 50.h,
                                color: AppColors.divider,
                              ),
                              _buildStatItem(
                                'Revenue',
                                '\$${(tripStats['total_revenue'] as double).toStringAsFixed(2)}',
                                Icons.attach_money_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: AppSpacing.xxl.h),
                    
                    // Main Actions
                    activeTripAsync.maybeWhen(
                      data: (activeTrip) {
                        if (activeTrip != null) {
                          // Has active trip - show Issue Ticket button
                          return AppButton(
                            text: 'Issue Ticket',
                            onPressed: () async {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => SelectPassengerRouteScreen(
                                    activeTrip: activeTrip,
                                  ),
                                ),
                              );
                              
                              // Refresh trip data if ticket was issued
                              if (result == true) {
                                ref.refresh(activeTripProvider);
                                ref.refresh(tripStatsProvider);
                              }
                            },
                            icon: Icons.add_rounded,
                          );
                        } else {
                          // No active trip - show disabled issue ticket button
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppButton(
                                text: 'Issue Ticket',
                                onPressed: null, // Disabled
                                icon: Icons.add_rounded,
                              ),
                              SizedBox(height: AppSpacing.xs.h),
                              Text(
                                'Start a trip to issue tickets',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        }
                      },
                      orElse: () => AppButton(
                        text: 'Issue Ticket',
                        onPressed: null,
                        icon: Icons.add_rounded,
                      ),
                    ),
                    
                    SizedBox(height: AppSpacing.md.h),
                    
                    activeTripAsync.when(
                      data: (activeTrip) {
                        if (activeTrip == null) {
                          return AppButton(
                            text: 'View My Tickets',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('No active trip. Start a trip to view tickets.'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            },
                            type: ButtonType.secondary,
                            icon: Icons.list_rounded,
                          );
                        }
                        
                        return AppButton(
                          text: 'View My Tickets',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketListScreen(
                                  activeTrip: activeTrip,
                                ),
                              ),
                            );
                          },
                          type: ButtonType.secondary,
                          icon: Icons.list_rounded,
                        );
                      },
                      loading: () => AppButton(
                        text: 'View My Tickets',
                        onPressed: null,
                        type: ButtonType.secondary,
                        icon: Icons.list_rounded,
                      ),
                      error: (e, s) => AppButton(
                        text: 'View My Tickets',
                        onPressed: null,
                        type: ButtonType.secondary,
                        icon: Icons.list_rounded,
                      ),
                    ),
                    
                    SizedBox(height: AppSpacing.xxl.h),
                    
                    // Sync Status
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm.w),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            color: AppColors.success,
                            size: AppSpacing.iconMedium.sp,
                          ),
                          SizedBox(width: AppSpacing.sm.w),
                          Text(
                            'All data synced',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: AppSpacing.lg.h),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading agent data: $error'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(
    BuildContext context,
    WidgetRef ref,
    dynamic activeTrip,
    Map<String, dynamic> tripStats,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                color: AppColors.textInverse,
                size: 28.sp,
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Trip',
                      style: AppTypography.headline2.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    Text(
                      'Fleet ${activeTrip.fleet?.number ?? "N/A"}',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textInverse.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _buildEndTripButton(context, ref, activeTrip.id),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            decoration: BoxDecoration(
              color: AppColors.textInverse.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.route_rounded,
                  color: AppColors.textInverse,
                  size: 20.sp,
                ),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Text(
                    activeTrip.route?.displayName ?? 'Unknown Route',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveTripCard(BuildContext context) {
    return Container(
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
            color: AppColors.textSecondary,
            size: 48.sp,
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            'No Active Trip',
            style: AppTypography.headline2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            'Start a trip to begin issuing tickets',
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Start Trip',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StartTripScreen(),
                  ),
                );
              },
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEndTripButton(BuildContext context, WidgetRef ref, String tripId) {
    return IconButton(
      onPressed: () async {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'End Trip',
              style: AppTypography.headline2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to end this trip? This will calculate your total tickets and revenue.',
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTypography.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(
                  'End Trip',
                  style: AppTypography.button.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          try {
            final tripRepo = ref.read(tripRepositoryProvider);
            await tripRepo.endTrip(tripId);

            // Invalidate active trip to refresh
            ref.invalidate(activeTripProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Trip ended successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  backgroundColor: AppColors.error,
                  ),
                ),
              );
            }
          }
        }
      },
      icon: Icon(
        Icons.stop_rounded,
        color: AppColors.textInverse,
        size: 28.sp,
      ),
      tooltip: 'End Trip',
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconLarge.sp,
          color: AppColors.primary,
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          value,
          style: AppTypography.headline1.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
