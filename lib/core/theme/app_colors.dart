import 'package:flutter/material.dart';

/// Centralized color system for Scope Guard
/// Designed for premium SaaS UI across all platforms.
class AppColors {
  // Backgrounds
  static const bg = Color(0xFFF9FAFB); // main app background
  static const surface = Color(0xFFFFFFFF); // cards, sheets
  static const surfaceMuted = Color(0xFFF3F4F6); // subtle containers

  // Text
  static const text = Color(0xFF111827); // primary text
  static const subtext = Color(0xFF6B7280); // secondary text
  static const disabled = Color(0xFF9CA3AF);

  // Brand / Primary
  static const primary = Color(0xFF1F2937); // dark slate
  static const primarySoft = Color(0xFF374151); // hover / secondary
  static const primaryTint = Color(0xFFEEF2FF); // light overlay

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Borders / dividers
  static const border = Color(0xFFE5E7EB);
  static const borderStrong = Color(0xFFD1D5DB);

  // Overlays (for hover, pressed, glass)
  static Color hoverOverlay(Color base) => base.withValues(alpha: 0.06);

  static Color pressedOverlay(Color base) => base.withValues(alpha: 0.10);

  static Color glassOverlay = Colors.white.withValues(alpha: 0.72);

  // Shadows (used sparingly for premium depth)
  static const shadowSoft = Color(0x11000000);
  static const shadowMedium = Color(0x1A000000);
}
