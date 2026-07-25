import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/models.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../shared/widgets/widgets.dart';

enum _TicketScope { trip, today, all, pending }

class IssuedTicketsScreen extends ConsumerStatefulWidget {
  const IssuedTicketsScreen({super.key});

  @override
  ConsumerState<IssuedTicketsScreen> createState() => _IssuedTicketsScreenState();
}

class _IssuedTicketsScreenState extends ConsumerState<IssuedTicketsScreen> {
  _TicketScope _scope = _TicketScope.today;
  final _searchController = TextEditingController();
  Future<_TicketsPageData>? _future;
  final Set<String> _collapsedTrips = {};
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final activeTrip = await ref.read(tripRepositoryProvider).getActiveTrip();
    if (!mounted) return;
    setState(() {
      if (activeTrip != null) _scope = _TicketScope.trip;
      _future = _loadPage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _future = _loadPage());
    await _future;
  }

  void _setScope(_TicketScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _future = _loadPage();
    });
  }

  Future<_TicketsPageData> _loadPage() async {
    final tripRepo = ref.read(tripRepositoryProvider);
    final ticketRepo = ref.read(ticketRepositoryProvider);
    final activeTrip = await tripRepo.getActiveTrip();

    final List<TicketModel> tickets;
    switch (_scope) {
      case _TicketScope.trip:
        tickets = activeTrip == null
            ? <TicketModel>[]
            : await ticketRepo.getTickets(tripId: activeTrip.id);
      case _TicketScope.today:
        tickets = await ticketRepo.getTodayTickets();
      case _TicketScope.all:
        tickets = await ticketRepo.getTickets();
      case _TicketScope.pending:
        tickets = (await ticketRepo.getTickets())
            .where((t) => t.syncStatus != 'synced')
            .toList();
    }

    final tripIds = tickets.map((t) => t.tripId).toSet();
    final tripsById = <String, TripModel?>{};
    for (final id in tripIds) {
      tripsById[id] = await tripRepo.getTripById(id);
    }

    return _TicketsPageData(
      tickets: tickets,
      activeTrip: activeTrip,
      tripsById: tripsById,
    );
  }

  List<TicketModel> _applySearch(List<TicketModel> tickets) {
          final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return tickets;
    return tickets
                .where(
                  (t) =>
                      t.displayNumber.toLowerCase().contains(query) ||
                      t.routeLabel.toLowerCase().contains(query) ||
              _categoryLabel(t.ticketCategory).toLowerCase().contains(query) ||
              (t.passengerName?.toLowerCase().contains(query) ?? false) ||
                      (t.passengerPhone?.toLowerCase().contains(query) ?? false),
                )
                .toList();
          }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sales & Tickets')),
      body: _future == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<_TicketsPageData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data;
                if (data == null) {
                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Could not load tickets',
                    action: AppButton(label: 'Retry', onPressed: _reload),
                  );
                }

                final tickets = _applySearch(data.tickets);
                final summary = _SalesSummary.from(tickets);
                final groups = _groupByTrip(tickets, data.tripsById);

          return Column(
            children: [
              Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                          hintText: 'Search ticket, route, phone, type…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                child: Row(
                  children: [
                          if (data.activeTrip != null)
                            _ScopeChip(
                              label: 'This trip',
                              selected: _scope == _TicketScope.trip,
                              onTap: () => _setScope(_TicketScope.trip),
                            ),
                          _ScopeChip(
                      label: 'Today',
                            selected: _scope == _TicketScope.today,
                            onTap: () => _setScope(_TicketScope.today),
                          ),
                          _ScopeChip(
                            label: 'All',
                            selected: _scope == _TicketScope.all,
                            onTap: () => _setScope(_TicketScope.all),
                          ),
                          _ScopeChip(
                      label: 'Pending sync',
                            selected: _scope == _TicketScope.pending,
                            onTap: () => _setScope(_TicketScope.pending),
                    ),
                  ],
                ),
              ),
                    const SizedBox(height: AppSpacing.sm),
              Expanded(
                      child: RefreshIndicator(
                        color: AppColors.brandRed,
                        onRefresh: _reload,
                child: tickets.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.sizeOf(context).height * 0.45,
                                    child: EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                                      title: _emptyTitle(),
                                      subtitle:
                                          'Issued tickets stay on this device until synced.',
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.sm,
                                  AppSpacing.md,
                                  AppSpacing.xl,
                                ),
                                children: [
                                  _SalesSummaryCard(
                                    summary: summary,
                                    scopeLabel: _scopeLabel(data.activeTrip),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    groups.length == 1
                                        ? 'Tickets'
                                        : 'Trips',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Tickets listed from first issued to latest',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ...groups.map((group) {
                                    final expanded = !_collapsedTrips
                                        .contains(group.tripId);
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: _TripSalesSection(
                                        group: group,
                                        expanded: expanded,
                                        onPrinted: _reload,
                                        onToggle: () {
                                          setState(() {
                                            if (expanded) {
                                              _collapsedTrips.add(group.tripId);
                                            } else {
                                              _collapsedTrips
                                                  .remove(group.tripId);
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _emptyTitle() {
    switch (_scope) {
      case _TicketScope.trip:
        return 'No tickets on this trip yet';
      case _TicketScope.today:
        return 'No tickets issued today';
      case _TicketScope.pending:
        return 'Nothing waiting to sync';
      case _TicketScope.all:
        return 'No tickets issued yet';
    }
  }

  String _scopeLabel(TripModel? activeTrip) {
    switch (_scope) {
      case _TicketScope.trip:
        return activeTrip == null
            ? 'This trip'
            : 'This trip · ${activeTrip.routeLabel}';
      case _TicketScope.today:
        return "Today's sales";
      case _TicketScope.all:
        return 'All sales on this device';
      case _TicketScope.pending:
        return 'Waiting to sync';
    }
  }

  List<_TripTicketGroup> _groupByTrip(
    List<TicketModel> tickets,
    Map<String, TripModel?> tripsById,
  ) {
    final map = <String, List<TicketModel>>{};
    for (final ticket in tickets) {
      map.putIfAbsent(ticket.tripId, () => []).add(ticket);
    }

    final groups = map.entries.map((entry) {
      final trip = tripsById[entry.key];
      final list = List<TicketModel>.from(entry.value)
        ..sort(_compareTicketOrder);
      final summary = _SalesSummary.from(list);
      final routeLabel = trip?.routeLabel ??
          (list.isNotEmpty ? list.first.routeLabel : 'Trip');
      return _TripTicketGroup(
        tripId: entry.key,
        trip: trip,
        routeLabel: routeLabel,
        tickets: list,
        summary: summary,
      );
    }).toList()
      ..sort((a, b) {
        final aTime = a.tickets.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : a.tickets.last.issuedAt;
        final bTime = b.tickets.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : b.tickets.last.issuedAt;
        return bTime.compareTo(aTime);
      });

    return groups;
  }

}

int _compareTicketOrder(TicketModel a, TicketModel b) {
  final aSerial = a.serialNumber;
  final bSerial = b.serialNumber;
  if (aSerial != null && bSerial != null) {
    final bySerial = aSerial.compareTo(bSerial);
    if (bySerial != 0) return bySerial;
  } else if (aSerial != null) {
    return -1;
  } else if (bSerial != null) {
    return 1;
  }
  return a.issuedAt.compareTo(b.issuedAt);
}

class _TicketsPageData {
  const _TicketsPageData({
    required this.tickets,
    required this.activeTrip,
    required this.tripsById,
  });

  final List<TicketModel> tickets;
  final TripModel? activeTrip;
  final Map<String, TripModel?> tripsById;
}

class _SalesSummary {
  const _SalesSummary({
    required this.totalTickets,
    required this.passengerCount,
    required this.combinedCount,
    required this.luggageCount,
    required this.otherCount,
    required this.pendingSync,
    required this.revenueByCurrency,
  });

  final int totalTickets;
  final int passengerCount;
  final int combinedCount;
  final int luggageCount;
  final int otherCount;
  final int pendingSync;
  final Map<String, double> revenueByCurrency;

  factory _SalesSummary.from(List<TicketModel> tickets) {
    var passenger = 0;
    var combined = 0;
    var luggage = 0;
    var other = 0;
    var pending = 0;
    final revenue = <String, double>{};

    for (final t in tickets) {
      switch (t.ticketCategory) {
        case 'PASSENGER':
          passenger++;
        case 'PASSENGER_WITH_LUGGAGE':
          combined++;
        case 'LUGGAGE':
          luggage++;
        default:
          other++;
      }
      if (t.syncStatus != 'synced') pending++;
      revenue.update(
        t.currency,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    return _SalesSummary(
      totalTickets: tickets.length,
      passengerCount: passenger,
      combinedCount: combined,
      luggageCount: luggage,
      otherCount: other,
      pendingSync: pending,
      revenueByCurrency: revenue,
    );
  }

  String get revenueLabel {
    if (revenueByCurrency.isEmpty) return '—';
    return revenueByCurrency.entries
        .map((e) => '${e.key} ${e.value.toStringAsFixed(2)}')
        .join(' · ');
  }
}

class _TripTicketGroup {
  const _TripTicketGroup({
    required this.tripId,
    required this.trip,
    required this.routeLabel,
    required this.tickets,
    required this.summary,
  });

  final String tripId;
  final TripModel? trip;
  final String routeLabel;
  final List<TicketModel> tickets;
  final _SalesSummary summary;
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.brandRed.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: selected ? AppColors.brandRed : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.brandRed
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesSummaryCard extends StatelessWidget {
  const _SalesSummaryCard({
    required this.summary,
    required this.scopeLabel,
  });

  final _SalesSummary summary;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              scopeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: summary.totalTickets == 1 ? 'Ticket' : 'Tickets',
                  value: '${summary.totalTickets}',
                  accent: AppColors.brandRed,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppColors.border,
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Total sales',
                  value: summary.revenueLabel,
                  accent: AppColors.textPrimary,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatPill(
                  icon: Icons.person_outline,
                  label: 'Passenger',
                  value: '${summary.passengerCount}',
                ),
                _StatPill(
                  icon: Icons.luggage_outlined,
                  label: 'Luggage',
                  value: '${summary.luggageCount}',
                ),
                _StatPill(
                  icon: Icons.groups_outlined,
                  label: 'Combined',
                  value: '${summary.combinedCount}',
                ),
                if (summary.otherCount > 0)
                  _StatPill(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Other',
                    value: '${summary.otherCount}',
                  ),
                _StatPill(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Pending',
                  value: '${summary.pendingSync}',
                  emphasize: summary.pendingSync > 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accent,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            value,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final color = emphasize ? AppColors.pendingSync : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TripSalesSection extends StatelessWidget {
  const _TripSalesSection({
    required this.group,
    required this.expanded,
    required this.onToggle,
    required this.onPrinted,
  });

  final _TripTicketGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onPrinted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = group.trip;
    final isActive = trip?.isActive ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: expanded
              ? AppColors.brandRed.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: expanded
                ? AppColors.brandRed.withValues(alpha: 0.05)
                : AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppSpacing.radiusLg),
              bottom: expanded
                  ? Radius.zero
                  : const Radius.circular(AppSpacing.radiusLg),
            ),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(AppSpacing.radiusLg),
                bottom: expanded
                    ? Radius.zero
                    : const Radius.circular(AppSpacing.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.brandRed.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            isActive
                                ? Icons.directions_bus
                                : Icons.directions_bus_outlined,
                            color: AppColors.brandRed,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.routeLabel,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm,
                                        ),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                trip?.fleetNumber != null
                                    ? 'Bus ${trip!.fleetNumber}'
                                    : 'Trip sales',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _TripStatBox(
                            label: 'Tickets',
                            value: '${group.summary.totalTickets}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _TripStatBox(
                            label: 'Sales',
                            value: group.summary.revenueLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      [
                        if (group.summary.passengerCount > 0)
                          '${group.summary.passengerCount} passenger',
                        if (group.summary.luggageCount > 0)
                          '${group.summary.luggageCount} luggage',
                        if (group.summary.combinedCount > 0)
                          '${group.summary.combinedCount} combined',
                      ].join('  ·  '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            Container(height: 1, color: AppColors.border),
            Container(
              width: double.infinity,
              color: AppColors.surfaceMuted.withValues(alpha: 0.55),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < group.tickets.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _TicketTile(
                      ticket: group.tickets[i],
                      onPrinted: onPrinted,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripStatBox extends StatelessWidget {
  const _TripStatBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends ConsumerWidget {
  const _TicketTile({
    required this.ticket,
    required this.onPrinted,
  });

  final TicketModel ticket;
  final VoidCallback onPrinted;

  Future<void> _openPrint(BuildContext context, WidgetRef ref) async {
    final trip = await ref.read(tripRepositoryProvider).getTripById(ticket.tripId);
    if (!context.mounted) return;
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip details not found for this ticket.')),
      );
      return;
    }

    await context.push(
      '/tickets/issue/print',
      extra: TicketIssueResult(trip: trip, single: ticket),
    );
    onPrinted();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final details = [
      if (ticket.passengerName != null &&
          ticket.passengerName!.trim().isNotEmpty)
        ticket.passengerName!.trim(),
      if (ticket.passengerPhone != null && ticket.passengerPhone!.isNotEmpty)
        ticket.passengerPhone!,
      ticket.routeLabel,
      DateFormat.MMMd().add_jm().format(ticket.issuedAt),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: ticket.printed
              ? AppColors.border
              : AppColors.brandGold.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              ticket.displayNumber,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryBadge(category: ticket.ticketCategory),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  details,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    SyncStatusBadge(status: ticket.syncStatus),
                    if (!ticket.printed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandGold.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'Not printed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.brandGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${ticket.currency} ${ticket.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (!ticket.printed)
                TextButton.icon(
                  onPressed: () => _openPrint(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandRed,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print'),
                )
              else
                Icon(
                  Icons.check_circle_outline,
                  size: 22,
                  color: AppColors.success.withValues(alpha: 0.85),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabel(category);
    final color = switch (category) {
      'PASSENGER' => AppColors.brandRed,
      'LUGGAGE' => AppColors.brandGold,
      'PASSENGER_WITH_LUGGAGE' => AppColors.pendingSync,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _categoryLabel(String category) => switch (category) {
      'PASSENGER' => 'Passenger',
      'PASSENGER_WITH_LUGGAGE' => 'Passenger + luggage',
      'LUGGAGE' => 'Luggage',
      _ => category,
    };
