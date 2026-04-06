# Countryboy Mobile App - Implementation Plan

## 📱 Overview

The Countryboy mobile app is a **conductor-focused ticketing system** for issuing bus tickets offline and syncing data when connectivity is available. Built for **Android POS terminals** (5-6 inch handheld smart payment devices), the app prioritizes **simplicity, reliability, and offline-first architecture** with **POS-optimized fonts and design**.

---

## 🎯 Core Requirements

### Primary Users
- **Bus Conductors** - Issue passenger and luggage tickets during trips using handheld POS terminals
- **Mobile-only agents** - No web portal access, mobile app is their primary interface

### Target Device
- **Android POS Terminals** (Smart Handheld Payment Devices)
- **Screen Size**: 5-6 inches (480x800 to 720x1280 pixels)
- **Orientation**: Portrait only (locked)
- **Android Version**: 7.0+ (API 24+)
- **Form Factor**: One-handed operation, used while standing/moving

### Key Features
1. **Device Pairing** (one-time) - Enter 6-character pairing code
2. **Daily Login** - Two-step process: Agent identification (codes) → PIN entry
3. **Trip Management** - Start/end trips with fleet and route selection
4. **Ticket Issuance** - Quick passenger and luggage ticket creation
5. **Offline Operation** - Full functionality without internet
6. **Auto-sync** - Background sync when connectivity available
7. **Serial Number Management** - Auto-fetch ticket serial ranges
8. **POS-Optimized UI** - Extra large fonts (18sp+ body), high contrast, large touch targets (56dp+)

---

## 🏗️ Architecture

### Clean Architecture + Feature-First Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp configuration
│
├── core/                              # Shared infrastructure
│   ├── config/
│   │   ├── app_config.dart           # API URLs, constants
│   │   └── app_theme.dart            # Theme configuration
│   ├── network/
│   │   ├── api_client.dart           # HTTP client (Dio)
│   │   ├── api_interceptors.dart     # Auth, logging interceptors
│   │   └── network_info.dart         # Connectivity checker
│   ├── storage/
│   │   ├── secure_storage.dart       # flutter_secure_storage
│   │   ├── local_database.dart       # Drift/Hive database
│   │   └── shared_prefs.dart         # Simple key-value storage
│   ├── errors/
│   │   ├── exceptions.dart           # Custom exceptions
│   │   └── failures.dart             # Result types
│   └── utils/
│       ├── logger.dart               # Logging utility
│       ├── formatters.dart           # Date, currency formatters
│       └── validators.dart           # Input validation
│
├── features/                          # Feature modules
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/               # DTOs
│   │   │   │   ├── device_model.dart
│   │   │   │   ├── agent_model.dart
│   │   │   │   └── login_response.dart
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/             # Business objects
│   │   │   │   ├── device.dart
│   │   │   │   └── agent.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── pair_device.dart
│   │   │       ├── login_agent.dart
│   │   │       └── logout.dart
│   │   └── presentation/
│   │       ├── providers/            # Riverpod providers
│   │       │   ├── auth_provider.dart
│   │       │   └── auth_state.dart
│   │       ├── screens/
│   │       │   ├── pairing_screen.dart
│   │       │   ├── login_screen.dart
│   │       │   └── splash_screen.dart
│   │       └── widgets/
│   │           ├── code_input_field.dart
│   │           └── pin_pad.dart
│   │
│   ├── trips/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── trip_model.dart
│   │   │   │   ├── route_model.dart
│   │   │   │   └── fleet_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── trip_remote_datasource.dart
│   │   │   │   └── trip_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── trip_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── trip.dart
│   │   │   │   ├── route.dart
│   │   │   │   └── fleet.dart
│   │   │   ├── repositories/
│   │   │   │   └── trip_repository.dart
│   │   │   └── usecases/
│   │   │       ├── start_trip.dart
│   │   │       ├── end_trip.dart
│   │   │       ├── get_active_trip.dart
│   │   │       └── fetch_routes.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── trip_provider.dart
│   │       │   └── trip_state.dart
│   │       ├── screens/
│   │       │   ├── trip_start_screen.dart
│   │       │   ├── active_trip_screen.dart
│   │       │   └── trip_history_screen.dart
│   │       └── widgets/
│   │           ├── route_selector.dart
│   │           ├── fleet_selector.dart
│   │           └── trip_card.dart
│   │
│   ├── tickets/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── ticket_model.dart
│   │   │   │   ├── fare_model.dart
│   │   │   │   └── serial_range_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── ticket_remote_datasource.dart
│   │   │   │   └── ticket_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── ticket_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── ticket.dart
│   │   │   │   ├── fare.dart
│   │   │   │   └── serial_range.dart
│   │   │   ├── repositories/
│   │   │   │   └── ticket_repository.dart
│   │   │   └── usecases/
│   │   │       ├── issue_ticket.dart
│   │   │       ├── fetch_serials.dart
│   │   │       ├── get_next_serial.dart
│   │   │       └── link_luggage_ticket.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── ticket_provider.dart
│   │       │   └── ticket_state.dart
│   │       ├── screens/
│   │       │   ├── ticket_issue_screen.dart
│   │       │   ├── ticket_preview_screen.dart
│   │       │   └── tickets_list_screen.dart
│   │       └── widgets/
│   │           ├── fare_selector.dart
│   │           ├── category_toggle.dart
│   │           ├── ticket_summary_card.dart
│   │           └── serial_number_display.dart
│   │
│   ├── sync/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── sync_log_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── sync_datasource.dart
│   │   │   └── repositories/
│   │   │       └── sync_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── sync_log.dart
│   │   │   ├── repositories/
│   │   │   │   └── sync_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sync_pending_tickets.dart
│   │   │       ├── sync_completed_trips.dart
│   │   │       └── fetch_master_data.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── sync_provider.dart
│   │       │   └── sync_state.dart
│   │       ├── screens/
│   │       │   └── sync_status_screen.dart
│   │       └── widgets/
│   │           ├── sync_indicator.dart
│   │           └── sync_log_list.dart
│   │
│   └── dashboard/
│       └── presentation/
│           ├── screens/
│           │   └── home_screen.dart
│           └── widgets/
│               ├── nav_drawer.dart
│               ├── stats_card.dart
│               └── quick_action_button.dart
│
└── shared/                            # Shared UI components
    ├── widgets/
    │   ├── app_button.dart
    │   ├── app_text_field.dart
    │   ├── loading_overlay.dart
    │   ├── error_widget.dart
    │   └── offline_banner.dart
    └── extensions/
        ├── context_extensions.dart
        ├── string_extensions.dart
        └── datetime_extensions.dart
```

---

## 🎨 UI/UX Design Principles

### Design Philosophy
- **Conductor-first**: Large touch targets, minimal steps, clear visual feedback
- **Glanceable**: Critical info visible at a glance (serial numbers, amounts)
- **Speed**: 3 taps maximum to issue a ticket
- **Error-proof**: Validation at every step, confirmation dialogs for critical actions
- **Offline-aware**: Clear indicators of sync status, offline mode prominent

### Color Scheme
```dart
// Primary: Transportation blue
primaryColor: Color(0xFF1976D2)
primaryDark: Color(0xFF0D47A1)
accent: Color(0xFFFF9800) // Ticket orange

// Functional colors
success: Color(0xFF4CAF50)
warning: Color(0xFFFFC107)
error: Color(0xFFF44336)
offline: Color(0xFF757575)
```

### Typography
- **Headers**: Bold, 24-28sp (route names, amounts)
- **Body**: Regular, 16-18sp (easy to read in moving vehicle)
- **Captions**: 12-14sp (serial numbers, timestamps)

### Key Screens

#### 1. **Pairing Screen** (One-time setup)
```
┌─────────────────────────┐
│  Countryboy Conductor   │
│                         │
│   [Bus Icon]            │
│                         │
│  Enter Pairing Code     │
│  ┌─┬─┬─┬─┬─┬─┐          │
│  │A│B│C│2│3│4│          │
│  └─┴─┴─┴─┴─┴─┘          │
│                         │
│  [Pair Device] Button   │
│                         │
│  Get code from admin    │
└─────────────────────────┘
```

#### 2. **Login Screen - Step 1** (Agent Identification)
```
┌─────────────────────────┐
│  Welcome Back           │
│  Let's Get Started      │
│                         │
│  Merchant Code          │
│  ┌───────────────────┐  │
│  │ HRE001           │  │
│  └───────────────────┘  │
│  6 characters           │
│                         │
│  Agent Code             │
│  ┌───────────────────┐  │
│  │ TMO014           │  │
│  └───────────────────┘  │
│  Your unique code       │
│                         │
│  [Continue] Button      │
│  (Validates codes)      │
│                         │
│  [Offline Banner]       │
└─────────────────────────┘
```

#### 3. **Login Screen - Step 2** (PIN Entry)
```
┌─────────────────────────┐
│  ← Back                 │
│                         │
│  Welcome,               │
│  Tinashe Moyo           │
│  (Agent: TMO014)        │
│                         │
│  Enter Your PIN         │
│                         │
│  ┌─────────────────┐    │
│  │  ┌───┬───┬───┬───┐  │
│  │  │ • │ • │ • │ • │  │
│  │  └───┴───┴───┴───┘  │
│  └─────────────────┘    │
│                         │
│  [1] [2] [3]            │
│  [4] [5] [6]            │
│  [7] [8] [9]            │
│  [←] [0] [✓]            │
│                         │
│  4-6 digit PIN          │
│                         │
│  [Forgot PIN?]          │
└─────────────────────────┘
```

#### 4. **Home/Dashboard**
```
┌─────────────────────────┐
│  ☰  Countryboy  [Sync]  │
├─────────────────────────┤
│                         │
│  Active Trip            │
│  ┌───────────────────┐  │
│  │ BUS: HRE-101     │  │
│  │ ROUTE: Hre → Byo │  │
│  │ Started: 08:30   │  │
│  │ Tickets: 12      │  │
│  │                  │  │
│  │ [Issue Ticket]   │  │
│  └───────────────────┘  │
│                         │
│  Or                     │
│  [Start New Trip]       │
│                         │
│  Today's Summary        │
│  ├─ Tickets: 45         │
│  ├─ Revenue: $320.00    │
│  └─ Pending Sync: 3     │
│                         │
└─────────────────────────┘
```

#### 5. **Issue Ticket Screen** (Most used!)
```
┌─────────────────────────┐
│  ← Issue Ticket         │
├─────────────────────────┤
│                         │
│  Category               │
│  [Passenger][Luggage]   │
│                         │
│  Route (pre-filled)     │
│  ┌───────────────────┐  │
│  │ Harare → Bulawayo│  │
│  └───────────────────┘  │
│                         │
│  Fare                   │
│  ┌───────────────────┐  │
│  │ $15.00 USD       │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Serial: #1042    │  │
│  └───────────────────┘  │
│                         │
│  [Issue Ticket]         │
│  Large, green button    │
│                         │
└─────────────────────────┘
```

#### 5. **Ticket Confirmation**
```
┌─────────────────────────┐
│  ✓ Ticket Issued        │
├─────────────────────────┤
│                         │
│  SERIAL: #1042          │
│  TYPE: Passenger        │
│  ROUTE: Harare → Byo    │
│  FARE: $15.00 USD       │
│  TIME: 09:42            │
│                         │
│  [Issue Another]        │
│  [Add Luggage]          │
│  [Back to Trip]         │
│                         │
└─────────────────────────┘
```

---

## 🔧 Technology Stack

### Core Dependencies

```yaml
# pubspec.yaml additions

dependencies:
  # State Management
  flutter_riverpod: ^2.6.1           # Modern state management
  riverpod_annotation: ^2.3.5        # Code generation for providers
  
  # Networking
  dio: ^5.7.0                         # HTTP client
  retrofit: ^4.4.1                    # Type-safe REST client
  json_annotation: ^4.9.0             # JSON serialization
  
  # Local Storage
  drift: ^2.22.0                      # SQL database (offline-first)
  sqlite3_flutter_libs: ^0.5.24      # SQLite support
  path_provider: ^2.1.5               # File paths
  flutter_secure_storage: ^9.2.2     # Secure token storage
  shared_preferences: ^2.3.3         # Simple key-value storage
  
  # Connectivity
  connectivity_plus: ^6.1.1           # Network status
  internet_connection_checker_plus: ^2.5.2  # True internet check
  
  # UI Components
  flutter_hooks: ^0.20.5              # Lifecycle hooks
  flutter_screenutil: ^5.9.3          # Responsive sizing
  google_fonts: ^6.2.1                # Typography
  flutter_svg: ^2.0.10+1              # SVG support
  cached_network_image: ^3.4.1       # Image caching
  shimmer: ^3.0.0                     # Loading skeletons
  
  # Forms & Validation
  flutter_form_builder: ^9.4.1        # Form handling
  form_builder_validators: ^11.0.0   # Validation rules
  pinput: ^5.0.0                      # PIN input
  
  # Utilities
  intl: ^0.19.0                       # Internationalization & formatting
  uuid: ^4.5.1                        # UUID generation
  logger: ^2.4.0                      # Logging
  equatable: ^2.0.7                   # Value equality
  freezed_annotation: ^2.4.4          # Immutable classes
  
  # Background Tasks
  workmanager: ^0.5.2                 # Background sync
  
dev_dependencies:
  # Code Generation
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  retrofit_generator: ^9.1.4
  drift_dev: ^2.22.0
  
  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  integration_test:
    sdk: flutter
  
  # Linting
  flutter_lints: ^6.0.0
```

---

## 🔐 Authentication Flow

### 1. Device Pairing (One-time)
```dart
// Sequence:
1. User opens app → Check if device paired
2. If not paired → Show PairingScreen
3. User enters 6-char code (e.g., ABC234)
4. POST /api/devices/pair { pairing_code: "ABC234" }
5. Receive device token (UUID)
6. Store token securely → flutter_secure_storage
7. Mark device as paired → Never show pairing again
```

### 2. Daily Login
```dart
// Sequence:
1. User opens app → Check if token exists
2. Show LoginScreen (merchant_code, agent_code, PIN)
3. Validate formats locally first (XXX### patterns)
4. POST /api/agents/login {
     merchant_code: "HRE001",
     agent_code: "TMO014",
     pin: "1234"
   }
   Headers: { Authorization: "Bearer {device_token}" }
5. Receive agent details + permissions
6. Store agent session → SharedPreferences
7. Navigate to HomeScreen
```

### 3. Session Management
```dart
// Auto-refresh strategy:
- Session expires after 12 hours of inactivity
- Auto-logout at midnight (new day = new login)
- Keep device token permanently unless explicitly logged out
- Allow offline mode with cached agent data
```

---

## 💾 Offline-First Strategy

### Principles
1. **Local database is source of truth** during offline operation
2. **API is synchronization layer** when online
3. **Conflict resolution**: Server wins (tickets can't be edited, only created)
4. **Queue all writes** for later sync

### Data Flow

#### Issuing Tickets (Offline)
```dart
1. User issues ticket
2. Generate temporary UUID
3. Get next serial from local range
4. Save to local Drift database
5. Mark as "pending_sync: true"
6. Show success immediately
7. When online → Sync queue processes
```

#### Syncing (Background)
```dart
// Auto-sync triggers:
- App foreground + online
- Every 15 minutes in background (WorkManager)
- Manual pull-to-refresh

// Sync sequence:
1. Check connectivity
2. Upload pending tickets (POST /api/tickets)
3. Upload completed trips (PATCH /api/trips/{id}/end)
4. Download master data (routes, fares, fleets)
5. Update last_sync timestamp
6. Clear successfully synced items
```

### Local Database Schema (Drift)

```dart
// lib/core/storage/database.dart

@DriftDatabase(tables: [
  Devices,
  Agents,
  Trips,
  Tickets,
  Routes,
  Fares,
  Fleets,
  SerialRanges,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// Example table
class Tickets extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get agentId => text()();
  TextColumn get serialNumber => integer().nullable()();
  TextColumn get category => text()(); // PASSENGER, LUGGAGE
  TextColumn get currency => text()();
  RealColumn get amount => real()();
  TextColumn get departure => text().nullable()();
  TextColumn get destination => text().nullable()();
  TextColumn get linkedPassengerTicketId => text().nullable()();
  DateTimeColumn get issuedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 🔄 State Management with Riverpod

### Provider Architecture

```dart
// lib/features/auth/presentation/providers/auth_provider.dart

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    // Initialize: Check if device paired and logged in
    final devicePaired = await ref.read(authRepositoryProvider).isDevicePaired();
    final agent = await ref.read(authRepositoryProvider).getCurrentAgent();
    
    if (!devicePaired) {
      return const AuthState.unpairedDevice();
    }
    
    if (agent == null) {
      return const AuthState.loggedOut();
    }
    
    return AuthState.loggedIn(agent);
  }

  Future<void> pairDevice(String pairingCode) async {
    state = const AsyncValue<AuthState>.loading();
    
    state = await AsyncValue.guard(() async {
      final device = await ref.read(authRepositoryProvider).pairDevice(pairingCode);
      return const AuthState.devicePaired();
    });
  }

  Future<void> login({
    required String merchantCode,
    required String agentCode,
    required String pin,
  }) async {
    state = const AsyncValue<AuthState>.loading();
    
    state = await AsyncValue.guard(() async {
      final agent = await ref.read(authRepositoryProvider).login(
        merchantCode: merchantCode,
        agentCode: agentCode,
        pin: pin,
      );
      return AuthState.loggedIn(agent);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(AuthState.loggedOut());
  }
}

// State classes (using Freezed)
@freezed
class AuthState with _$AuthState {
  const factory AuthState.unpairedDevice() = UnpairedDevice;
  const factory AuthState.devicePaired() = DevicePaired;
  const factory AuthState.loggedOut() = LoggedOut;
  const factory AuthState.loggedIn(Agent agent) = LoggedIn;
}
```

### Usage in UI

```dart
// lib/features/auth/presentation/screens/login_screen.dart

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      loading: () => const LoadingOverlay(),
      error: (error, stack) => ErrorWidget(error: error.toString()),
      data: (state) => state.when(
        unpairedDevice: () => const PairingScreen(),
        devicePaired: () => const LoginForm(),
        loggedOut: () => const LoginForm(),
        loggedIn: (agent) {
          // Navigate to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

---

## 🧪 Testing Strategy

### 1. Unit Tests
```dart
// Test repositories, use cases, providers
// Coverage target: 80%+

test/
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── login_agent_test.dart
│   │   └── data/
│   │       └── repositories/
│   │           └── auth_repository_impl_test.dart
│   └── tickets/
│       └── domain/
│           └── usecases/
│               └── issue_ticket_test.dart
└── core/
    └── network/
        └── api_client_test.dart
```

### 2. Widget Tests
```dart
// Test individual widgets and screens
// Coverage target: 60%+

test/
└── features/
    └── auth/
        └── presentation/
            └── screens/
                └── login_screen_test.dart
```

### 3. Integration Tests
```dart
// Test complete user flows
// Priority: Critical paths

integration_test/
├── auth_flow_test.dart              # Pairing + Login
├── ticket_issuance_flow_test.dart   # Full ticket creation
└── offline_sync_test.dart           # Offline operation + sync
```

---

## 📦 Project Setup Steps

### Phase 1: Foundation (Week 1)
1. ✅ Set up folder structure
2. ✅ Add dependencies to pubspec.yaml
3. ✅ Configure Drift database
4. ✅ Set up Dio HTTP client with interceptors
5. ✅ Create app theme and constants
6. ✅ Set up Riverpod providers structure
7. ✅ Configure code generation (build_runner)

### Phase 2: Authentication (Week 1-2)
1. ✅ Implement device pairing feature
2. ✅ Implement agent login feature
3. ✅ Create secure storage service
4. ✅ Build pairing screen UI
5. ✅ Build login screen - Step 1 (codes entry)
6. ✅ Build login screen - Step 2 (PIN entry with numeric keypad)
7. ✅ Test auth flow end-to-end

### Phase 3: Trip Management (Week 2-3)
1. ✅ Implement trip repository
2. ✅ Create trip entities and models
3. ✅ Build start trip screen
4. ✅ Build active trip dashboard
5. ✅ Implement trip end functionality
6. ✅ Test trip lifecycle

### Phase 4: Ticket Issuance (Week 3-4)
1. ✅ Implement ticket repository
2. ✅ Serial number management logic
3. ✅ Build issue ticket screen
4. ✅ Implement passenger ticket creation
5. ✅ Implement luggage ticket linking
6. ✅ Build ticket preview/confirmation
7. ✅ Test ticket issuance offline

### Phase 5: Sync & Offline (Week 4-5)
1. ✅ Implement sync repository
2. ✅ Create sync queue manager
3. ✅ Set up WorkManager background tasks
4. ✅ Implement connectivity monitoring
5. ✅ Build sync status UI
6. ✅ Test offline → online sync
7. ✅ Test conflict resolution

### Phase 6: Dashboard & Polish (Week 5-6)
1. ✅ Build home dashboard
2. ✅ Implement navigation drawer
3. ✅ Add statistics/reporting
4. ✅ Implement error handling
5. ✅ Add loading states
6. ✅ Offline banner indicator
7. ✅ Polish UI/UX

### Phase 7: Testing & Deployment (Week 6-7)
1. ✅ Write unit tests
2. ✅ Write widget tests
3. ✅ Write integration tests
4. ✅ Performance testing
5. ✅ Build APK/IPA
6. ✅ Deploy to test devices
7. ✅ User acceptance testing

---

## 🚀 Quick Start Commands

```bash
# Navigate to mobile folder
cd mobile

# Install dependencies
flutter pub get

# Generate code (Riverpod, Freezed, JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release
```

---

## 📋 Development Checklist

### Before Starting
- [ ] Review API documentation (server/MOBILE_AUTH_FLOW.md)
- [ ] Understand authentication flow
- [ ] Review test credentials (server/TEST_CREDENTIALS.md)
- [ ] Set up Android emulator or physical device

### During Development
- [ ] Follow Clean Architecture principles
- [ ] Write tests alongside features
- [ ] Use code generation (Freezed, Riverpod)
- [ ] Handle all error states
- [ ] Test offline scenarios
- [ ] Optimize for performance (60fps target)
- [ ] Use meaningful commit messages

### Before Release
- [ ] All tests passing (unit, widget, integration)
- [ ] No linter warnings
- [ ] Performance profiling done
- [ ] Tested on multiple devices
- [ ] Error tracking configured (e.g., Sentry)
- [ ] Analytics configured (e.g., Firebase Analytics)
- [ ] App icons and splash screen added
- [ ] Version numbers updated

---

## 🎯 Success Metrics

### Performance
- App launch: < 2 seconds
- Ticket issuance: < 1 second offline
- Sync 100 tickets: < 10 seconds
- Frame rate: 60fps sustained

### Reliability
- Crash-free rate: > 99.5%
- Offline operation: 100% functional
- Sync success rate: > 98%
- Data loss: 0%

### Usability
- Conductor onboarding: < 5 minutes
- Daily login: < 10 seconds
- Ticket issuance: < 3 taps
- Intuitive UI: < 2% support requests

---

## 📚 Additional Resources

### Documentation
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Riverpod Docs](https://riverpod.dev/docs/introduction/getting_started)
- [Drift Database](https://drift.simonbinder.eu/docs/getting-started/)
- [API Integration](../server/MOBILE_AUTH_FLOW.md)

### Tools
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools)
- [Postman Collection](../server/postman-test-dummy-data.json)

---

## 👥 Team Roles

- **Backend Developer**: API support, troubleshooting sync issues
- **Flutter Developer**: App implementation, UI/UX
- **QA Tester**: Test all flows, especially offline scenarios
- **Product Owner**: Feature prioritization, user feedback
- **Conductor (Beta)**: Real-world testing, usability feedback

---

## 🔄 Next Steps

1. **Review this document** with the team
2. **Set up development environment** (Flutter SDK, IDE)
3. **Start with Phase 1** (Foundation setup)
4. **Daily standups** to track progress
5. **Weekly demos** to stakeholders
6. **Beta testing** with real conductors in Week 6

---

**Document Version**: 1.0  
**Last Updated**: March 1, 2026  
**Maintained By**: Development Team
