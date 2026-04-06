# Countryboy Conductor - Mobile App

🚍 A Flutter-based mobile ticketing application for bus conductors to issue tickets offline and sync data automatically.

## 📱 Overview

The Countryboy Conductor app enables bus conductors to:
- Issue passenger and luggage tickets
- Manage trips (start/end)
- Work fully offline with automatic sync
- Track ticket serial numbers
- View daily statistics

## 🚀 Quick Start

### Prerequisites
- Flutter 3.16.0 or higher
- Android Studio / Xcode (for simulators)
- Backend API running (see `../server`)

### Installation
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### First Time Setup
1. Start backend server: `cd ../server && npm run dev`
2. Run mobile app: `flutter run`
3. Use pairing code: `ABC234` (test data)
4. Login with: `HRE001` / `TMO014` / `1234`

For detailed setup instructions, see [QUICK_START.md](./QUICK_START.md)

## 📚 Documentation

- **[Quick Start Guide](./QUICK_START.md)** - Get up and running in 15 minutes
- **[Implementation Plan](./IMPLEMENTATION_PLAN.md)** - Complete architecture and development roadmap
- **[API Integration](./API_INTEGRATION.md)** - Detailed API endpoints and usage examples

## 🏗️ Architecture

This project follows **Clean Architecture** principles with a **feature-first** structure:

```
lib/
├── core/          # Shared infrastructure (network, storage, utils)
├── features/      # Feature modules (auth, trips, tickets, sync)
└── shared/        # Reusable UI components
```

### Key Technologies
- **State Management**: Riverpod
- **Networking**: Dio + Retrofit
- **Local Database**: Drift (SQLite)
- **Secure Storage**: flutter_secure_storage
- **Background Sync**: WorkManager

## 🎯 Key Features

### ✅ Implemented
- Project structure and documentation

### 🚧 In Progress
- Device pairing flow
- Agent authentication
- Trip management

### 📋 Planned
- Ticket issuance
- Offline-first sync
- Dashboard and reporting

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

## 🔧 Development

### Code Generation
```bash
# Generate files (models, providers)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode
flutter pub run build_runner watch
```

### Linting
```bash
flutter analyze
dart format .
```

## 📦 Building

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🌐 API Configuration

API endpoints are configured in `lib/core/config/env.dart`:

```dart
// For Android Emulator
static const apiBaseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator  
static const apiBaseUrl = 'http://localhost:3000/api';

// For Physical Device (use your computer's IP)
static const apiBaseUrl = 'http://192.168.1.100:3000/api';
```

## 🔐 Test Credentials

Pairing Codes: `ABC234`, `XYZ789`

Login:
- Merchant: `HRE001`
- Agent: `TMO014`
- PIN: `1234`

See [../server/TEST_CREDENTIALS.md](../server/TEST_CREDENTIALS.md) for more test data.

## 📱 Supported Platforms

- ✅ Android 7.0+ (API 24+)
- ✅ iOS 12.0+
- ❌ Web (not planned)
- ❌ Desktop (not planned)

## 🤝 Contributing

1. Follow the [Implementation Plan](./IMPLEMENTATION_PLAN.md)
2. Write tests for new features
3. Run linter before committing
4. Update documentation as needed

## 📄 License

Private - Countryboy Bus Services

---

**Version**: 1.0.0  
**Last Updated**: March 1, 2026

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
