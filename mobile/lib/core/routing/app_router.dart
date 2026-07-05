import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/agent_code_screen.dart';
import '../../features/auth/merchant_code_screen.dart';
import '../../features/auth/pin_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/main_shell.dart';
import '../../features/pairing/pairing_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/sync/pending_sync_screen.dart';
import '../../features/tickets/issue_ticket_form_screen.dart';
import '../../features/tickets/ticket_print_screen.dart';
import '../../features/tickets/ticket_review_screen.dart';
import '../../domain/models/ticket_issue_draft.dart';
import '../../features/tickets/issued_tickets_screen.dart';
import '../../features/trips/end_trip_screen.dart';
import '../../features/trips/start_trip_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/pairing', builder: (_, __) => const PairingScreen()),
      GoRoute(path: '/login/merchant', builder: (_, __) => const MerchantCodeScreen()),
      GoRoute(path: '/login/agent', builder: (_, state) {
        final merchant = state.extra as String? ?? '';
        return AgentCodeScreen(merchantCode: merchant);
      }),
      GoRoute(path: '/login/pin', builder: (_, state) {
        final args = state.extra as Map<String, String>? ?? {};
        return PinScreen(
          merchantCode: args['merchant'] ?? '',
          agentCode: args['agent'] ?? '',
        );
      }),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/tickets', builder: (_, __) => const IssuedTicketsScreen()),
          GoRoute(path: '/sync', builder: (_, __) => const PendingSyncScreen()),
        ],
      ),
      GoRoute(path: '/trips/start', builder: (_, __) => const StartTripScreen()),
      GoRoute(path: '/trips/end', builder: (_, __) => const EndTripScreen()),
      GoRoute(path: '/tickets/issue', builder: (_, __) => const IssueTicketFormScreen()),
      GoRoute(
        path: '/tickets/issue/review',
        builder: (_, state) {
          final draft = state.extra as TicketIssueDraft?;
          if (draft == null) {
            return const IssueTicketFormScreen();
          }
          return TicketReviewScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/tickets/issue/print',
        builder: (_, state) {
          final result = state.extra as TicketIssueResult?;
          if (result == null) {
            return const IssueTicketFormScreen();
          }
          return TicketPrintScreen(result: result);
        },
      ),
    ],
  );
});
