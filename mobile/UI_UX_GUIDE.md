# UI/UX Design Guide - Countryboy Conductor

## 🎨 Design Philosophy

The Countryboy Conductor app is designed for **bus conductors working in challenging conditions** on **Android POS terminals** (handheld smart payment devices):
- **Device**: 5-6 inch Android POS terminals (portrait orientation)
- **Screen size**: ~480x800 to 720x1280 pixels
- **Environment**: Moving vehicles, bright sunlight (outdoor visibility)
- **Users**: Potentially low literacy, need for speed
- **Context**: No time for mistakes, one-handed operation

### Core Principles
1. **POS-Optimized Layout** - Designed for 5-6" handheld Android terminals
2. **Large & Clear** - All elements must be easily tappable (minimum 56dp for POS)
3. **Extra Large Fonts** - Minimum 18sp body text, 32sp+ for critical info
4. **High Contrast** - Readable in bright sunlight (WCAG AAA where possible)
5. **Minimal Steps** - 3 taps maximum to complete any task
6. **Visual Hierarchy** - Most important info is largest
7. **Error Prevention** - Validate before action, confirm destructive actions
8. **Offline Awareness** - Always show connectivity status
9. **Portrait Only** - Locked to portrait orientation for POS terminal use

---

## 🎨 Color System

### Primary Palette
```dart
// lib/core/config/app_colors.dart

class AppColors {
  // Primary - Transportation Blue
  static const primary = Color(0xFF1976D2);           // Deep blue
  static const primaryLight = Color(0xFF63A4FF);      // Light blue
  static const primaryDark = Color(0xFF004BA0);       // Navy blue
  
  // Accent - Ticket Orange
  static const accent = Color(0xFFFF9800);            // Bright orange
  static const accentLight = Color(0xFFFFD54F);       // Light orange
  static const accentDark = Color(0xFFF57C00);        // Dark orange
  
  // Functional Colors
  static const success = Color(0xFF4CAF50);           // Green
  static const warning = Color(0xFFFFC107);           // Amber
  static const error = Color(0xFFF44336);             // Red
  static const info = Color(0xFF2196F3);              // Blue
  
  // Status Colors
  static const active = Color(0xFF4CAF50);            // Active trip/session
  static const inactive = Color(0xFF9E9E9E);          // Inactive
  static const offline = Color(0xFF757575);           // Offline mode
  static const syncing = Color(0xFF2196F3);           // Syncing in progress
  
  // Text Colors
  static const textPrimary = Color(0xFF212121);       // Almost black
  static const textSecondary = Color(0xFF757575);     // Grey
  static const textHint = Color(0xFFBDBDBD);          // Light grey
  static const textInverse = Color(0xFFFFFFFF);       // White
  
  // Background Colors
  static const background = Color(0xFFF5F5F5);        // Light grey
  static const surface = Color(0xFFFFFFFF);           // White
  static const surfaceDark = Color(0xFF424242);       // Dark surface
  
  // Ticket Categories
  static const passengerTicket = Color(0xFF4CAF50);   // Green
  static const luggageTicket = Color(0xFFFF9800);     // Orange
}
```

### Semantic Colors
```dart
// Usage-based colors
static const buttonPrimary = primary;
static const buttonSuccess = success;
static const buttonDanger = error;
static const buttonDisabled = Color(0xFFE0E0E0);

static const borderDefault = Color(0xFFE0E0E0);
static const borderFocused = primary;
static const borderError = error;
```

---

## 📏 Typography

### Font Scale (POS Terminal Optimized)
```dart
// lib/core/config/app_typography.dart
// OPTIMIZED FOR 5-6" ANDROID POS TERMINALS

class AppTypography {
  static const fontFamily = 'Roboto'; // System default, excellent readability on POS
  
  // Display (Largest - for amounts, serial numbers, PINs)
  // Extra large for critical info on small POS screens
  static const display1 = TextStyle(
    fontSize: 56,  // Increased from 48 for POS visibility
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static const display2 = TextStyle(
    fontSize: 42,  // Increased from 36 for POS visibility
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.3,
  );
  
  // Headline (Route names, trip info, agent names)
  static const headline1 = TextStyle(
    fontSize: 32,  // Increased from 28 for POS
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const headline2 = TextStyle(
    fontSize: 28,  // Increased from 24 for POS
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  // Title (Screen titles, card headers)
  static const title1 = TextStyle(
    fontSize: 22,  // Increased from 20 for POS
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const title2 = TextStyle(
    fontSize: 20,  // Increased from 18 for POS
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body (Main text) - MUST BE CLEARLY READABLE ON POS
  static const body1 = TextStyle(
    fontSize: 18,  // Increased from 16 (POS minimum readable)
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const body2 = TextStyle(
    fontSize: 16,  // Increased from 14 for POS
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  // Caption (Small text, labels, hints)
  static const caption = TextStyle(
    fontSize: 14,  // Increased from 12 for POS readability
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  // Button Text (Large and bold for POS terminals)
  static const button = TextStyle(
    fontSize: 20,  // Increased from 18 for POS terminals
    fontWeight: FontWeight.bold,  // Changed to bold for better visibility
    letterSpacing: 0.8,
  );
  
  // Numeric Keypad (Extra large for PIN entry on POS)
  static const keypadNumber = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.0,
  );
}
```

---

## 📐 Spacing System (POS Terminal Optimized)

```dart
// lib/core/config/app_spacing.dart
// OPTIMIZED FOR 5-6" ANDROID POS TERMINALS

class AppSpacing {
  // Base unit: 8dp
  static const xs = 4.0;      // Extra small
  static const sm = 8.0;      // Small
  static const md = 16.0;     // Medium (default)
  static const lg = 24.0;     // Large
  static const xl = 32.0;     // Extra large
  static const xxl = 48.0;    // Extra extra large
  
  // Touch targets (INCREASED FOR POS TERMINALS)
  static const minTouchTarget = 56.0;  // Minimum 56x56dp for POS (was 48dp)
  static const recommendedTouchTarget = 64.0;  // Recommended for primary actions
  static const keypadButtonSize = 72.0;  // Large keypad buttons for PIN entry
  
  // Card/Container padding
  static const cardPadding = md;
  static const screenPadding = md;
  static const screenPaddingVertical = lg;  // Extra vertical padding for POS
  
  // Element spacing (generous for small screens)
  static const elementSpacing = md;
  static const sectionSpacing = lg;
  static const componentSpacing = xl;  // Space between major components
}
```

---

## 🖥️ Screen Specifications

### 1. Splash Screen
**Purpose**: App initialization, check pairing/login status

```dart
┌─────────────────────────────────┐
│                                 │
│                                 │
│         [Bus Icon Logo]         │
│                                 │
│       Countryboy Conductor      │
│                                 │
│     [Loading Indicator]         │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**Implementation**:
- Center logo and text
- Show loading spinner
- Check device paired → Show login or pairing
- Auto-navigate after 2 seconds max

---

### 2. Pairing Screen (One-time)
**Purpose**: Link device to depot using admin-provided code

```dart
┌─────────────────────────────────┐
│  ← Back                         │
├─────────────────────────────────┤
│                                 │
│      [Large Bus Icon]           │
│                                 │
│   Welcome to Countryboy!        │  (headline1)
│                                 │
│   Enter Pairing Code            │  (title1)
│   Get this code from your       │  (body2, grey)
│   depot manager                 │
│                                 │
│   ┌───┬───┬───┬───┬───┬───┐    │
│   │ A │ B │ C │ 2 │ 3 │ 4 │    │  (display2, bold)
│   └───┴───┴───┴───┴───┴───┘    │
│                                 │
│   [Clear]              [Paste]  │  (text buttons)
│                                 │
│   ┌─────────────────────────┐   │
│   │    PAIR DEVICE          │   │  (56dp height)
│   └─────────────────────────┘   │  (primary color)
│                                 │
│   Code must be exactly 6        │  (caption, grey)
│   characters (e.g. ABC234)      │
│                                 │
└─────────────────────────────────┘
```

**Components**:
- 6 large input boxes (auto-focus, uppercase)
- Paste button (detect clipboard)
- Clear button
- Large "Pair Device" button
- Helpful hint text

**Validation**:
- 6 characters required
- Auto-submit when complete
- Show error below button
- Disable button until valid

---

### 3. Login Screen - Step 1 (Agent Identification)
**Purpose**: Identify conductor before PIN entry

```dart
┌─────────────────────────────────┐
│        [Small Logo]             │
│                                 │
│    Welcome Back,                │  (headline2)
│    Let's Get Started            │
│                                 │
│  ┌─────────────────────────────┐│
│  │ Merchant Code              ││ (title2)
│  │ ┌───────────────────────┐  ││
│  │ │ HRE001                │  ││ (display2)
│  │ └───────────────────────┘  ││
│  │ 6 characters (e.g. HRE001) ││ (caption)
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Agent Code                 ││
│  │ ┌───────────────────────┐  ││
│  │ │ TMO014                │  ││ (display2)
│  │ └───────────────────────┘  ││
│  │ Your unique agent code     ││ (caption)
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │         CONTINUE            │ │ (64dp height!)
│  └─────────────────────────────┘│ (primary color)
│                                 │
│  ┌─────────────────────────────┐│
│  │ ⚠ Working Offline          ││ (if offline)
│  │ Will sync when connected    ││ (warning banner)
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

**Features**:
- Large input fields
- Auto-uppercase merchant/agent codes
- Remember merchant code (SharedPreferences)
- Offline banner if no connection
- Continue button disabled until both codes filled
- Validates codes before proceeding to PIN

**Validation Rules**:
- Merchant: 6 chars, XXX### format
- Agent: 6 chars, XXX### format  
- Show format hint on error
- If offline: Store codes, proceed to PIN (will validate when online)

---

### 4. Login Screen - Step 2 (PIN Entry)
**Purpose**: Secure PIN authentication on separate screen

```dart
┌─────────────────────────────────┐
│  ← Back to codes                │
├─────────────────────────────────┤
│                                 │
│        [Agent Avatar]           │
│                                 │
│    Welcome,                     │  (headline2)
│    Tinashe Moyo                 │  (title1, bold)
│                                 │
│    Agent: TMO014                │  (body1, grey)
│    Depot: Harare Main Terminal  │  (body2, grey)
│                                 │
│                                 │
│    Enter Your PIN               │  (title1)
│                                 │
│    ┌───────────────────────┐    │
│    │  ┌───┬───┬───┬───┐   │    │
│    │  │ • │ • │ • │ • │   │    │  (display1, dots)
│    │  └───┴───┴───┴───┘   │    │
│    └───────────────────────┘    │
│                                 │
│    ┌───────────────────────┐    │
│    │ [1]   [2]   [3]      │    │  (72dp each)
│    │ [4]   [5]   [6]      │    │
│    │ [7]   [8]   [9]      │    │
│    │ [←]   [0]   [✓]      │    │  (backspace, zero, submit)
│    └───────────────────────┘    │
│                                 │
│    4-6 digit PIN                │  (caption)
│                                 │
│    [Forgot PIN?]                │  (text link)
│                                 │
└─────────────────────────────────┘
```

**Features**:
- Shows agent name (fetched from server after Step 1)
- Large numeric keypad (72x72dp buttons)
- Visual feedback on each digit entry
- Auto-submit when 4-6 digits entered
- Backspace to correct mistakes
- Back button returns to code entry
- Haptic feedback on keypress
- Forgot PIN leads to contact admin message

**Validation**:
- 4-6 digits required
- Auto-submit on completion
- Show error if incorrect (shake animation)
- Lock account after 5 failed attempts
- Clear message: "Incorrect PIN. 3 attempts remaining"

**Why Separate PIN Screen?**
- ✅ Cleaner, less cluttered interface
- ✅ Focus mode - only one task at a time
- ✅ Shows agent info after validation (personalized)
- ✅ Larger numeric keypad (better UX)
- ✅ Matches ATM/banking app patterns (familiar)
- ✅ Better security (PIN not visible with codes)

---

### 5. Home/Dashboard Screen
**Purpose**: Hub for all conductor activities

```dart
┌─────────────────────────────────┐
│  ☰  Countryboy     🔄 [Sync]   │ (App bar)
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🚌 Active Trip              ││ (card, elevated)
│  │                             ││
│  │ BUS: HRE-101                ││ (headline2)
│  │ ROUTE: Harare → Bulawayo    ││ (title1)
│  │                             ││
│  │ ├─ Started: 08:30 AM        ││ (body1)
│  │ ├─ Duration: 2h 15m         ││
│  │ └─ Tickets: 12              ││
│  │                             ││
│  │ ┌───────────────────────┐   ││
│  │ │  📄 ISSUE TICKET      │   ││ (56dp, accent)
│  │ └───────────────────────┘   ││
│  │                             ││
│  │ [View Details] [End Trip]   ││ (text buttons)
│  └─────────────────────────────┘│
│                                 │
│          - OR -                 │ (if no active trip)
│                                 │
│  ┌─────────────────────────────┐│
│  │    🚏 START NEW TRIP        ││ (64dp, primary)
│  └─────────────────────────────┘│
│                                 │
│  Today's Summary                │ (title1)
│  ┌────────────┬────────────────┐│
│  │ 🎫 Tickets │ 💵 Revenue     ││ (stat cards)
│  │    45      │   $320.00      ││ (display2)
│  └────────────┴────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ ⏳ 3 Tickets Pending Sync   ││ (if pending)
│  │ [Sync Now]                  ││ (info banner)
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

**Active Trip Card**:
- Prominent, elevated
- Green accent border (for active status)
- Large "Issue Ticket" button (most common action)
- Quick access to trip details

**No Active Trip**:
- Large "Start New Trip" button
- Previous trip info (collapsed card)

**Stats**:
- Grid layout (2 columns)
- Large numbers
- Icons for visual recognition

---

### 6. Start Trip Screen
**Purpose**: Select fleet and route to begin trip

```dart
┌─────────────────────────────────┐
│  ← Start New Trip               │
├─────────────────────────────────┤
│                                 │
│  Select Fleet                   │ (title1)
│  ┌─────────────────────────────┐│
│  │ 🚌 HRE-101               ▼ ││ (dropdown)
│  └─────────────────────────────┘│
│                                 │
│  Select Route                   │
│  ┌─────────────────────────────┐│
│  │ 📍 Harare → Bulawayo     ▼ ││ (dropdown)
│  └─────────────────────────────┘│
│                                 │
│  Route Details                  │ (if route selected)
│  ├─ Distance: 439 km            │
│  ├─ Est. Time: 5 hours          │
│  └─ Base Fare: $15.00           │
│                                 │
│  Start Time                     │
│  ┌─────────────────────────────┐│
│  │ 🕐 08:30 AM              ▼ ││ (time picker)
│  └─────────────────────────────┘│
│  [Use Current Time]             │ (checkbox)
│                                 │
│                                 │
│  ┌─────────────────────────────┐│
│  │      START TRIP             ││ (64dp, success)
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

**Features**:
- Large dropdowns (56dp height)
- Clear labels
- Route details preview
- Default to current time
- Validation before start
- Confirmation dialog

---

### 7. Issue Ticket Screen ⭐ MOST IMPORTANT
**Purpose**: Fastest ticket issuance possible

```dart
┌─────────────────────────────────┐
│  ← Issue Ticket          [Help] │
├─────────────────────────────────┤
│                                 │
│  Ticket Category                │ (title1)
│  ┌──────────────┬──────────────┐│
│  │              │              ││
│  │  🙋 PASSENGER│  🧳 LUGGAGE ││ (toggle buttons)
│  │   (Active)   │              ││ (72dp height)
│  │              │              ││
│  └──────────────┴──────────────┘│
│                                 │
│  Route (from active trip)       │
│  ┌─────────────────────────────┐│
│  │ 📍 Harare → Bulawayo        ││ (display, locked)
│  └─────────────────────────────┘│
│                                 │
│  Fare                           │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │    $15.00 USD               ││ (display1, center)
│  │                             ││
│  └─────────────────────────────┘│
│  [Edit Amount]                  │ (text button)
│                                 │
│  ┌─────────────────────────────┐│
│  │  Serial Number: #1042       ││ (info box)
│  └─────────────────────────────┘│
│                                 │
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │   ✓ ISSUE TICKET            ││ (80dp height!)
│  │                             ││ (success color)
│  └─────────────────────────────┘│
│                                 │
│  Last issued: 09:42  |  Today: 12 │ (caption)
│                                 │
└─────────────────────────────────┘
```

**Critical Features**:
- Category toggle (2 options only)
- Route pre-filled from active trip
- Fare prominent and editable
- Serial number auto-fetched
- HUGE issue button (can't miss it)
- Quick stats at bottom

**Speed Optimizations**:
- Default to passenger
- Auto-select fare from route
- One tap to issue
- Instant feedback
- No loading spinners (offline-first)

---

### 8. Ticket Confirmation
**Purpose**: Quick confirmation with options for next action

```dart
┌─────────────────────────────────┐
│  ✓ Ticket Issued Successfully   │ (success banner)
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │   SERIAL #1042              ││ (display1, center)
│  │                             ││
│  │   PASSENGER                 ││ (headline2)
│  │   Harare → Bulawayo         ││ (title1)
│  │   $15.00 USD                ││ (headline2, accent)
│  │                             ││
│  │   Issued: 09:42 AM          ││ (body1)
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  Quick Actions                  │ (title2)
│  ┌─────────────────────────────┐│
│  │  📄 ISSUE ANOTHER TICKET    ││ (56dp, primary)
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │  🧳 ADD LUGGAGE TICKET      ││ (56dp, accent)
│  └─────────────────────────────┘│
│                                 │
│  [Back to Trip]                 │ (text button)
│                                 │
│  Auto-return in 5 seconds...    │ (caption, timer)
│                                 │
└─────────────────────────────────┘
```

**Features**:
- Clear success state
- Ticket details prominent
- Quick actions (most common: issue another)
- Auto-return to trip (conductor friendly)
- Manual back option

---

### 9. Navigation Drawer
**Purpose**: Access all app sections

```dart
┌─────────────────────┐
│                     │
│  [Avatar]           │
│  Tinashe Moyo       │ (title1)
│  Agent: TMO014      │ (body2)
│                     │
├─────────────────────┤
│  🏠 Home            │
│  🚏 Active Trip     │
│  📜 History         │
│  📊 Statistics      │
│  🔄 Sync Status     │
│  ⚙️  Settings       │
│  ❓ Help            │
├─────────────────────┤
│  🚪 Logout          │ (error color)
│                     │
│  ┌─────────────────┐│
│  │ 🟢 Online       ││ (status indicator)
│  │ Last sync: 2m   ││
│  └─────────────────┘│
│                     │
│  v1.0.0             │ (caption)
└─────────────────────┘
```

---

## 📱 Component Library

### Buttons

```dart
// Primary Button (most important actions)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    minimumSize: Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('BUTTON TEXT', style: AppTypography.button),
)

// Success Button (issue ticket, start trip)
// Same as primary but backgroundColor: AppColors.success

// Text Button (secondary actions)
TextButton(
  style: TextButton.styleFrom(
    minimumSize: Size(0, 48),
  ),
  child: Text('Action'),
)
```

### Input Fields

```dart
TextFormField(
  style: AppTypography.display2,
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Hint',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: EdgeInsets.all(16),
  ),
)
```

### Cards

```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: // Content
  ),
)
```

---

## ✅ Accessibility Checklist

- [ ] All touch targets ≥ 48dp
- [ ] Color contrast ≥ 4.5:1 (WCAG AA)
- [ ] Text size ≥ 16sp for body
- [ ] Semantic labels for screen readers
- [ ] Error messages descriptive
- [ ] Loading states announced
- [ ] Focus indicators visible
- [ ] Keyboard navigation supported

---

**Document Version**: 1.0  
**Last Updated**: March 1, 2026  
**Implementation**: Use with Flutter Material Design widgets
