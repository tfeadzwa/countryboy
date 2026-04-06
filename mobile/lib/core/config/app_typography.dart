import 'package:flutter/material.dart';

/// Typography system optimized for Android POS terminals (5-6" screens)
/// All font sizes increased for better readability on small handheld devices
class AppTypography {
  // Private constructor
  AppTypography._();

  // Font family - Use Roboto (Android system default, excellent POS readability)
  static const String fontFamily = 'Roboto';

  // ============================================================================
  // DISPLAY STYLES - Extra Large for Critical Information
  // Used for: Ticket amounts, serial numbers, PINs
  // ============================================================================
  
  static const TextStyle display1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56, // Extra large for POS terminals
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle display2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 42, // Large for important numbers
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.3,
  );

  // ============================================================================
  // HEADLINE STYLES - For Major Headings
  // Used for: Route names, trip info, agent names, screen titles
  // ============================================================================
  
  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32, // Prominent headings
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28, // Secondary headings
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  // ============================================================================
  // TITLE STYLES - For Card Headers and Section Titles
  // Used for: Card titles, form labels, section headers
  // ============================================================================
  
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22, // Main titles
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20, // Subtitles
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ============================================================================
  // BODY STYLES - Main Content Text
  // Used for: Paragraphs, descriptions, list items
  // IMPORTANT: Minimum 18sp for POS terminal readability
  // ============================================================================
  
  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18, // Primary body text (POS minimum)
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16, // Secondary body text
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // ============================================================================
  // CAPTION STYLES - Small Supporting Text
  // Used for: Hints, helper text, timestamps
  // ============================================================================
  
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14, // Small but still readable on POS
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.2,
  );

  // ============================================================================
  // BUTTON TEXT STYLES - Call-to-Action Text
  // Used for: Buttons, action items
  // Extra large and bold for POS terminals
  // ============================================================================
  
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20, // Large for easy reading
    fontWeight: FontWeight.bold, // Bold for emphasis
    letterSpacing: 0.8,
    height: 1.0,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22, // Extra large for primary actions
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    height: 1.0,
  );

  // ============================================================================
  // SPECIAL PURPOSE STYLES
  // ============================================================================
  
  /// Numeric keypad style - Extra large for PIN entry on POS terminals
  static const TextStyle keypadNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.0,
  );

  /// Input field text style - Large and clear
  static const TextStyle inputText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Label text style - Clear and prominent
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Error message style - Attention-grabbing
  static const TextStyle error = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Success message style
  static const TextStyle success = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ============================================================================
  // Helper method to apply color to text styles
  // ============================================================================
  
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
