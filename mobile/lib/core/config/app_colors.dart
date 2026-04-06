import 'package:flutter/material.dart';

/// Application color palette optimized for Android POS terminals
/// Designed for high contrast and visibility in bright sunlight
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // PRIMARY COLORS - Transportation Blue
  // ============================================================================
  static const Color primary = Color(0xFF1976D2); // Deep blue
  static const Color primaryLight = Color(0xFF63A4FF); // Light blue
  static const Color primaryDark = Color(0xFF004BA0); // Navy blue

  // ============================================================================
  // ACCENT COLORS - Ticket Orange
  // ============================================================================
  static const Color accent = Color(0xFFFF9800); // Bright orange
  static const Color accentLight = Color(0xFFFFD54F); // Light orange
  static const Color accentDark = Color(0xFFF57C00); // Dark orange

  // ============================================================================
  // FUNCTIONAL COLORS - Status & Actions
  // ============================================================================
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // ============================================================================
  // STATUS COLORS - Trip & Sync States
  // ============================================================================
  static const Color active = Color(0xFF4CAF50); // Active trip/session
  static const Color inactive = Color(0xFF9E9E9E); // Inactive
  static const Color offline = Color(0xFF757575); // Offline mode
  static const Color syncing = Color(0xFF2196F3); // Syncing in progress
  static const Color pending = Color(0xFFFFC107); // Pending sync

  // ============================================================================
  // TEXT COLORS - High Contrast for POS Screens
  // ============================================================================
  static const Color textPrimary = Color(0xFF212121); // Almost black
  static const Color textSecondary = Color(0xFF757575); // Grey
  static const Color textHint = Color(0xFFBDBDBD); // Light grey
  static const Color textInverse = Color(0xFFFFFFFF); // White
  static const Color textDisabled = Color(0xFF9E9E9E); // Disabled state

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================
  static const Color background = Color(0xFFF5F5F5); // Light grey
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceDark = Color(0xFF424242); // Dark surface
  static const Color surfaceLight = Color(0xFFFAFAFA); // Very light grey

  // ============================================================================
  // TICKET CATEGORY COLORS
  // ============================================================================
  static const Color passengerTicket = Color(0xFF4CAF50); // Green
  static const Color luggageTicket = Color(0xFFFF9800); // Orange

  // ============================================================================
  // BUTTON COLORS - Semantic Usage
  // ============================================================================
  static const Color buttonPrimary = primary;
  static const Color buttonSuccess = success;
  static const Color buttonDanger = error;
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonText = textInverse;

  // ============================================================================
  // BORDER COLORS
  // ============================================================================
  static const Color borderDefault = Color(0xFFE0E0E0);
  static const Color borderFocused = primary;
  static const Color borderError = error;
  static const Color borderSuccess = success;

  // ============================================================================
  // SHADOW COLORS
  // ============================================================================
  static const Color shadowLight = Color(0x1A000000); // 10% black
  static const Color shadowMedium = Color(0x33000000); // 20% black
  static const Color shadowDark = Color(0x4D000000); // 30% black

  // ============================================================================
  // OVERLAY COLORS
  // ============================================================================
  static const Color overlayLight = Color(0x0A000000); // 4% black
  static const Color overlayMedium = Color(0x14000000); // 8% black
  static const Color overlayDark = Color(0x29000000); // 16% black

  // ============================================================================
  // DIVIDER COLORS
  // ============================================================================
  static const Color divider = Color(0xFFBDBDBD);
  static const Color dividerLight = Color(0xFFE0E0E0);
}
