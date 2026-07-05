import 'package:flutter/material.dart';

/// CountryBoy brand palette — aligned with frontend `index.css` tokens.
abstract final class AppColors {
  // Brand
  static const brandRed = Color(0xFFC1272D);
  static const brandGold = Color(0xFFE8A317);

  // Surfaces
  static const background = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0EDE8);

  // Text
  static const textPrimary = Color(0xFF181C22);
  static const textSecondary = Color(0xFF6B7280);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const success = Color(0xFF2D9B5A);
  static const warning = Color(0xFFE8A317);
  static const error = Color(0xFFDC3545);
  static const offline = Color(0xFF64748B);
  static const pendingSync = Color(0xFF2563EB);
  static const syncing = Color(0xFF7C3AED);

  // Borders
  static const border = Color(0xFFE2DDD4);
  static const focusRing = brandRed;

  // Dark accent (sidebar-inspired)
  static const charcoal = Color(0xFF1A1F26);
}
