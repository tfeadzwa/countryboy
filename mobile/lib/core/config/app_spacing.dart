/// Spacing constants optimized for Android POS terminals (5-6" screens)
/// Increased touch targets and spacing for better usability on handheld devices
class AppSpacing {
  // Private constructor
  AppSpacing._();

  // ============================================================================
  // BASE SPACING UNITS (Based on 8dp grid)
  // ============================================================================
  
  static const double xxs = 2.0; // Extra extra small
  static const double xs = 4.0; // Extra small
  static const double sm = 8.0; // Small
  static const double md = 16.0; // Medium (default)
  static const double lg = 24.0; // Large
  static const double xl = 32.0; // Extra large
  static const double xxl = 48.0; // Extra extra large

  // ============================================================================
  // TOUCH TARGETS - Optimized for POS Terminals
  // Android recommends 48dp minimum, we use 56dp for POS terminals
  // ============================================================================
  
  /// Minimum touch target size for POS terminals (increased from standard 48dp)
  static const double minTouchTarget = 56.0;
  
  /// Recommended touch target for primary actions
  static const double recommendedTouchTarget = 64.0;
  
  /// Large touch target for critical actions (Issue Ticket, Login, etc.)
  static const double largeTouchTarget = 72.0;
  
  /// Keypad button size for PIN entry (extra large for accuracy)
  static const double keypadButtonSize = 72.0;

  // ============================================================================
  // PADDING & MARGINS
  // ============================================================================
  
  /// Page padding (all sides) - standard for all screens
  static const double pagePadding = md; // 16dp
  
  /// Standard screen padding (horizontal)
  static const double screenPadding = md; // 16dp
  
  /// Vertical padding for screens (more generous for small POS screens)
  static const double screenPaddingVertical = lg; // 24dp
  
  /// Card padding
  static const double cardPadding = md; // 16dp
  
  /// Card padding large (for important cards)
  static const double cardPaddingLarge = lg; // 24dp
  
  /// Dialog padding
  static const double dialogPadding = lg; // 24dp
  
  /// Button padding (horizontal)
  static const double buttonPaddingHorizontal = xl; // 32dp
  
  /// Button padding (vertical)
  static const double buttonPaddingVertical = md; // 16dp
  
  /// Input field padding
  static const double inputPadding = md; // 16dp

  // ============================================================================
  // SPACING BETWEEN ELEMENTS
  // ============================================================================
  
  /// Spacing between small elements (e.g., icon and text)
  static const double elementSpacingSmall = sm; // 8dp
  
  /// Standard spacing between elements
  static const double elementSpacing = md; // 16dp
  
  /// Spacing between sections
  static const double sectionSpacing = lg; // 24dp
  
  /// Spacing between major components (generous for POS screens)
  static const double componentSpacing = xl; // 32dp
  
  /// Large spacing for visual separation
  static const double largeSpacing = xxl; // 48dp

  // ============================================================================
  // LIST & GRID SPACING
  // ============================================================================
  
  /// List item padding
  static const double listItemPadding = md; // 16dp
  
  /// Space between list items
  static const double listItemSpacing = sm; // 8dp
  
  /// Grid item spacing
  static const double gridSpacing = md; // 16dp

  // ============================================================================
  // BORDER RADIUS - Rounded corners for modern POS UI
  // ============================================================================
  
  /// Small border radius (chips, tags)
  static const double radiusSmall = 4.0;
  
  /// Medium border radius (buttons, cards)
  static const double radiusMedium = 8.0;
  
  /// Large border radius (dialogs, bottom sheets)
  static const double radiusLarge = 12.0;
  
  /// Extra large border radius (featured cards)
  static const double radiusExtraLarge = 16.0;
  
  /// Circular border radius (avatars, FABs)
  static const double radiusCircular = 999.0;

  // ============================================================================
  // ICON SIZES - Optimized for POS Visibility
  // ============================================================================
  
  /// Small icon size
  static const double iconSmall = 16.0;
  
  /// Standard icon size
  static const double iconMedium = 24.0;
  
  /// Large icon size (for emphasis)
  static const double iconLarge = 32.0;
  
  /// Extra large icon size (app logo, major actions)
  static const double iconExtraLarge = 48.0;

  // ============================================================================
  // ELEVATION - Shadow depths for Material Design
  // ============================================================================
  
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationExtraHigh = 16.0;

  // ============================================================================
  // APP BAR & BOTTOM NAV
  // ============================================================================
  
  /// App bar height (comfortable for POS)
  static const double appBarHeight = 64.0;
  
  /// Bottom navigation bar height
  static const double bottomNavHeight = 64.0;

  // ============================================================================
  // DIVIDER THICKNESS
  // ============================================================================
  
  static const double dividerThickness = 1.0;
  static const double dividerThicknessBold = 2.0;
}
