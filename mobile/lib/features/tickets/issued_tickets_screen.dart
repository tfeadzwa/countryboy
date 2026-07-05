import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/models.dart';
import '../../services/ticket_print_service.dart';
import '../../services/ticket_receipt_builder.dart';
import '../../shared/widgets/widgets.dart';

class IssuedTicketsScreen extends ConsumerStatefulWidget {
  const IssuedTicketsScreen({super.key});

  @override
  ConsumerState<IssuedTicketsScreen> createState() => _IssuedTicketsScreenState();
}

class _IssuedTicketsScreenState extends ConsumerState<IssuedTicketsScreen> {
  String _filter = 'all';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issued Tickets')),
      body: FutureBuilder<List<TicketModel>>(
        future: _loadTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var tickets = snapshot.data ?? [];
          final query = _searchController.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            tickets = tickets
                .where(
                  (t) =>
                      t.displayNumber.toLowerCase().contains(query) ||
                      t.routeLabel.toLowerCase().contains(query) ||
                      (t.passengerName?.toLowerCase().contains(query) ?? false) ||
                      (t.passengerPhone?.toLowerCase().contains(query) ?? false),
                )
                .toList();
          }

          if (_filter == 'pending') {
            tickets = tickets.where((t) => t.syncStatus != 'synced').toList();
          } else if (_filter == 'today') {
            final start = DateTime.now();
            final dayStart = DateTime(start.year, start.month, start.day);
            tickets = tickets.where((t) => t.issuedAt.isAfter(dayStart)).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search ticket or route',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    _FilterChip(
                      label: 'Today',
                      selected: _filter == 'today',
                      onTap: () => setState(() => _filter = 'today'),
                    ),
                    _FilterChip(
                      label: 'Pending sync',
                      selected: _filter == 'pending',
                      onTap: () => setState(() => _filter = 'pending'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tickets.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No tickets issued yet',
                        subtitle: 'Issued tickets will appear here, even when offline.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: tickets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) => _TicketTile(
                            ticket: tickets[i],
                            onPrint: () => _printTicket(tickets[i]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<TicketModel>> _loadTickets() async {
    final trip = await ref.read(tripRepositoryProvider).getActiveTrip();
    if (trip != null) {
      return ref.read(ticketRepositoryProvider).getTickets(tripId: trip.id);
    }
    return ref.read(ticketRepositoryProvider).getTickets();
  }

  Future<void> _printTicket(TicketModel ticket) async {
    try {
      final receipt = await buildReceiptForTicket(ref, ticket);
      await ref.read(ticketPrintServiceProvider).printReceipt(receipt);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not print ticket. Try again.')),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({
    required this.ticket,
    required this.onPrint,
  });

  final TicketModel ticket;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(ticket.displayNumber),
        subtitle: Text(
          [
            if (ticket.passengerName != null && ticket.passengerName!.isNotEmpty)
              ticket.passengerLabel,
            ticket.routeLabel,
            DateFormat.yMMMd().add_jm().format(ticket.issuedAt),
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ticket.currency} ${ticket.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SyncStatusBadge(status: ticket.syncStatus),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print ticket',
              color: AppColors.brandRed,
              onPressed: onPrint,
            ),
          ],
        ),
      ),
    );
  }
}
