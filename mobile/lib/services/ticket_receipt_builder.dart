import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/secure_storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/reference_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../domain/models/models.dart';
import '../domain/models/ticket_issue_draft.dart';
import '../domain/models/ticket_receipt_data.dart';

Future<List<TicketReceiptData>> buildReceiptData(
  WidgetRef ref,
  TicketIssueResult result,
) {
  return buildReceiptDataForTickets(ref, result.tickets, trip: result.trip);
}

Future<List<TicketReceiptData>> buildReceiptDataForTickets(
  WidgetRef ref,
  List<TicketModel> tickets, {
  TripModel? trip,
}) async {
  final context = await _loadReceiptContext(ref);

  final receipts = <TicketReceiptData>[];
  for (final ticket in tickets) {
    receipts.add(
      await _buildReceipt(
        ref,
        ticket: ticket,
        trip: trip,
        context: context,
      ),
    );
  }
  return receipts;
}

Future<TicketReceiptData> buildReceiptForTicket(
  WidgetRef ref,
  TicketModel ticket,
) {
  return _buildReceipt(ref, ticket: ticket);
}

Future<TicketReceiptData> _buildReceipt(
  WidgetRef ref, {
  required TicketModel ticket,
  TripModel? trip,
  _ReceiptContext? context,
}) async {
  final ctx = context ?? await _loadReceiptContext(ref);
  var resolvedTrip = trip ??
      await ref.read(tripRepositoryProvider).getTripById(ticket.tripId) ??
      _fallbackTripForTicket(ticket);

  if (resolvedTrip.fleetRegistrationNumber == null ||
      resolvedTrip.fleetRegistrationNumber!.trim().isEmpty) {
    try {
      final fleets = await ref.read(referenceRepositoryProvider).getFleets();
      FleetModel? fleet;
      for (final candidate in fleets) {
        if (candidate.id == resolvedTrip.fleetId) {
          fleet = candidate;
          break;
        }
      }
      final reg = fleet?.registrationNumber?.trim();
      if (reg != null && reg.isNotEmpty) {
        resolvedTrip =
            resolvedTrip.copyWith(fleetRegistrationNumber: reg);
      }
    } catch (_) {
      // Keep trip as-is when fleet cache is unavailable.
    }
  }

  return TicketReceiptData(
    ticket: ticket,
    trip: resolvedTrip,
    merchantCode: ctx.merchantCode,
    depotName: ctx.depotName,
    agentName: ctx.agentName,
    agentCode: ctx.agentCode,
    deviceSerial: ctx.deviceSerial,
    printerName: ctx.printerName,
    printerMac: ctx.printerMac,
    printerSerial: ctx.printerSerial,
  );
}

Future<_ReceiptContext> _loadReceiptContext(WidgetRef ref) async {
  final agent = await ref.read(authRepositoryProvider).getCurrentAgent();
  final storage = ref.read(secureStorageServiceProvider);

  return _ReceiptContext(
    merchantCode:
        agent?.merchantCode ?? await storage.getMerchantCode() ?? '-',
    depotName: agent?.depotName ?? '-',
    agentCode: agent?.agentCode ?? '-',
    agentName: agent != null
        ? '${agent.firstName} ${agent.lastName}'.trim()
        : 'Conductor',
    deviceSerial: await storage.getSerialNumber(),
    printerName: await storage.getPrinterName(),
    printerMac: await storage.getPrinterMac(),
    printerSerial: await storage.getPrinterSerial(),
  );
}

TripModel _fallbackTripForTicket(TicketModel ticket) => TripModel(
      id: ticket.tripId,
      agentId: '',
      fleetId: '',
      routeId: '',
      status: 'ENDED',
      startedAt: ticket.issuedAt,
      routeOrigin: ticket.departure,
      routeDestination: ticket.destination,
    );

class _ReceiptContext {
  const _ReceiptContext({
    required this.merchantCode,
    required this.depotName,
    required this.agentName,
    required this.agentCode,
    this.deviceSerial,
    this.printerName,
    this.printerMac,
    this.printerSerial,
  });

  final String merchantCode;
  final String depotName;
  final String agentName;
  final String agentCode;
  final String? deviceSerial;
  final String? printerName;
  final String? printerMac;
  final String? printerSerial;
}
