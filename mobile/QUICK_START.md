# Quick Start Guide - Countryboy Mobile App

## 🚀 Getting Started in 15 Minutes

This guide will help you set up and run the Countryboy mobile app locally.

---

## ✅ Prerequisites

### 1. Install Flutter
```bash
# Check if Flutter is installed
flutter --version

# Should show: Flutter 3.16.0 or higher
```

**Don't have Flutter?**
- Download from: https://docs.flutter.dev/get-started/install
- Follow OS-specific installation guide
- Add Flutter to PATH

### 2. Install IDE
Choose one:
- **VS Code** + Flutter Extension (Recommended for beginners)
- **Android Studio** + Flutter Plugin (Best for Android dev)

### 3. Set Up Device/Emulator

**Android**:
```bash
# Check connected devices
flutter devices

# Or create an emulator in Android Studio
# Tools → AVD Manager → Create Virtual Device
```

**iOS** (Mac only):
```bash
# Install Xcode from App Store
# Then install CocoaPods
sudo gem install cocoapods
```

---

## 📥 Installation

### Step 1: Navigate to Mobile Folder
```bash
cd countryboy/mobile
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

This will install all packages from `pubspec.yaml`.

### Step 3: Verify Setup
```bash
flutter doctor -v
```

Fix any issues shown (missing Android SDK, licenses, etc.)

---

## ⚙️ Configuration

### 1. Create Environment Configuration

Create `lib/core/config/env.dart`:
```dart
class Environment {
  // API Base URLs
  static const String apiBaseUrlDev = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String apiBaseUrlDev = 'http://localhost:3000/api'; // iOS simulator
  static const String apiBaseUrlProd = 'https://api.countryboy.co.zw/api';
  
  // Current environment
  static const bool isDevelopment = true;
  
  static String get apiBaseUrl => isDevelopment ? apiBaseUrlDev : apiBaseUrlProd;
  
  // Feature flags
  static const bool enableLogging = true;
  static const bool enableMockData = false; // For offline dev
}
```

**Important**: 
- Android emulator uses `10.0.2.2` to access host machine's `localhost`
- iOS simulator uses `localhost` directly
- Physical devices need your computer's IP address (e.g., `http://192.168.1.100:3000/api`)

### 2. Update API Base URL for Physical Devices

If testing on a physical device:
```dart
// Find your IP address:
// Windows: ipconfig
// Mac/Linux: ifconfig

static const String apiBaseUrlDev = 'http://192.168.1.100:3000/api';
```

---

## 🏃 Running the App

### Development Mode
```bash
# Run on connected device/emulator
flutter run

# Run with hot reload enabled (default)
# Press 'r' to hot reload
# Press 'R' to hot restart
# Press 'q' to quit
```

### Debug Build
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Specific device
flutter run -d <device-id>
```

### Release Build (Testing)
```bash
# Android APK
flutter build apk --release

# Find APK at: build/app/outputs/flutter-apk/app-release.apk

# iOS (Mac only)
flutter build ios --release
```

---

## 🧪 Testing Backend Connection

### 1. Start Backend Server
In a separate terminal:
```bash
cd ../server
npm run dev
```

Server should start on `http://localhost:3000`

### 2. Verify API is Running
```bash
# Test endpoint
curl http://localhost:3000/api/health

# Should return: {"status":"ok"}
```

### 3. Test Device Pairing

In app:
1. Launch app
2. Enter pairing code: `ABC234` (from test data)
3. Should successfully pair and show login screen

**Troubleshooting**: 
- If connection fails, check API URL in `env.dart`
- Ensure backend server is running
- Check firewall settings

---

## 📱 Using Test Data

### Test Credentials (from seed data)

**Pairing Codes** (for new devices):
- `ABC234` - Harare depot
- `XYZ789` - Bulawayo depot

**Login Credentials**:
```
// Harare Agent
Merchant Code: HRE001
Agent Code: TMO014
PIN: 1234

// Bulawayo Agent
Merchant Code: BYO001
Agent Code: NDU021
PIN: 1234

// Mutare Agent
Merchant Code: MUT001
Agent Code: PMA031
PIN: 1234
```

### Sample Data Available:
- 3 Depots (Harare, Bulawayo, Mutare)
- 9 Active agents
- 12 Bus fleets
- 12 Routes with fares
- Serial number ranges ready

---

## 🔨 Development Workflow

### 1. Code Generation (For models, providers)
```bash
# Generate once
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch
```

### 2. Linting
```bash
# Check for lint issues
flutter analyze

# Auto-fix some issues
dart fix --apply
```

### 3. Formatting
```bash
# Format all files
dart format .

# Format specific file
dart format lib/main.dart
```

### 4. Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/login_test.dart

# Run with coverage
flutter test --coverage
```

---

## 🗂️ Project Structure Overview

```
mobile/
├── lib/
│   ├── main.dart              # App entry point
│   ├── app.dart               # MaterialApp config
│   │
│   ├── core/                  # Shared infrastructure
│   │   ├── config/            # Environment, theme
│   │   ├── network/           # API client
│   │   ├── storage/           # Database, secure storage
│   │   └── utils/             # Helpers, formatters
│   │
│   ├── features/              # Feature modules
│   │   ├── auth/              # Authentication
│   │   ├── trips/             # Trip management
│   │   ├── tickets/           # Ticket issuance
│   │   ├── sync/              # Background sync
│   │   └── dashboard/         # Home screen
│   │
│   └── shared/                # Reusable widgets
│       └── widgets/
│
├── test/                      # Unit & widget tests
├── integration_test/          # End-to-end tests
└── pubspec.yaml              # Dependencies
```

---

## 🐛 Troubleshooting

### Issue: "flutter: command not found"
```bash
# Add Flutter to PATH
# Mac/Linux: Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/flutter/bin"

# Windows: Add to System Environment Variables
# C:\path\to\flutter\bin
```

### Issue: "Unable to connect to API"
```bash
# Check backend is running
curl http://localhost:3000/api/health

# For Android emulator, use 10.0.2.2 instead of localhost
static const apiBaseUrl = 'http://10.0.2.2:3000/api';

# For physical device, use your computer's IP
static const apiBaseUrl = 'http://192.168.1.100:3000/api';
```

### Issue: "Certificate verification failed"
For development HTTPS issues:
```dart
// In lib/core/network/api_client.dart (DEV ONLY!)
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
  (HttpClient client) {
    client.badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;
    return client;
  };
```

### Issue: "Build failed - Gradle error"
```bash
# Clean and rebuild
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "CocoaPods error" (iOS)
```bash
cd ios
pod install
cd ..
flutter run
```

---

## 📚 Next Steps

### Phase 1: Set Up Foundation ✅
You're here! You've:
- ✅ Installed Flutter
- ✅ Run the default app
- ✅ Connected to backend

### Phase 2: Implement Core Features
1. **Read Documentation**:
   - [Implementation Plan](./IMPLEMENTATION_PLAN.md) - Full architecture
   - [API Integration](./API_INTEGRATION.md) - API endpoints

2. **Start Coding**:
   ```bash
   # Create feature structure
   mkdir -p lib/features/auth/{data,domain,presentation}
   mkdir -p lib/core/{config,network,storage}
   ```

3. **Follow Architecture**:
   - Start with `auth` feature (pairing + login)
   - Then `trips` (start/end trips)
   - Then `tickets` (issue tickets)
   - Finally `sync` (offline support)

### Phase 3: Test & Deploy
1. Write tests alongside features
2. Test on multiple devices
3. Build release APK
4. Beta test with real conductors

---

## 🔗 Useful Commands Cheat Sheet

```bash
# Project
flutter create mobile              # Create new project
flutter pub get                    # Install dependencies
flutter pub upgrade                # Update dependencies
flutter clean                      # Clean build files

# Running
flutter run                        # Run app
flutter run -d android             # Run on Android
flutter run --release              # Release mode
flutter devices                    # List devices

# Code Generation
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch

# Testing
flutter test                       # Run tests
flutter test --coverage            # With coverage
flutter drive --target=integration_test/app_test.dart

# Building
flutter build apk --release        # Android APK
flutter build appbundle            # Android App Bundle
flutter build ios --release        # iOS build

# Analysis
flutter analyze                    # Lint check
dart format .                      # Format code
dart fix --apply                   # Auto-fix issues

# Debugging
flutter logs                       # View logs
flutter doctor -v                  # Check setup
flutter channel stable             # Switch to stable
flutter upgrade                    # Update Flutter
```

---

## 📞 Getting Help

### Documentation
- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Riverpod Docs](https://riverpod.dev/)
- [Project Implementation Plan](./IMPLEMENTATION_PLAN.md)
- [API Integration Guide](./API_INTEGRATION.md)

### Common Issues
- Check `flutter doctor` output
- Review error logs in terminal
- Search Flutter GitHub issues
- Stack Overflow with `flutter` tag

### Project-Specific Help
- Review backend test credentials: `../server/TEST_CREDENTIALS.md`
- Check API documentation: `../server/MOBILE_AUTH_FLOW.md`
- Test with Postman: `../server/postman-test-dummy-data.json`

---

## ✅ Checklist

Before you start coding:
- [ ] Flutter installed and working (`flutter doctor`)
- [ ] IDE set up with Flutter plugin
- [ ] Device/emulator connected (`flutter devices`)
- [ ] Backend server running (`npm run dev`)
- [ ] Test API connection (curl health endpoint)
- [ ] App runs successfully (`flutter run`)
- [ ] Read Implementation Plan
- [ ] Read API Integration Guide
- [ ] Understand Clean Architecture
- [ ] Ready to code! 🚀

---

**Happy Coding!** 🎉

If you encounter issues, refer to the troubleshooting section or review the full implementation plan.

---

**Document Version**: 1.0  
**Last Updated**: March 1, 2026
