import 'package:flutter/material.dart';

/// Semantic color palette for Smart Waste Management System.
class AppColors {
  AppColors._();

  // Primary Brand - Modern Environmental Emerald/Green
  static const Color primary = Color(0xFF16A34A); // Tailwind Green 600
  static const Color primaryDark = Color(0xFF15803D); // Tailwind Green 700
  static const Color primaryLight = Color(0xFFDCFCE7); // Tailwind Green 100
  static const Color primaryContainer = Color(0xFFF0FDF4); // Tailwind Green 50

  // Secondary Accent - Fresh Teal
  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color secondaryLight = Color(0xFFCCFBF1);

  // Background and Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100

  // Neutral Text and Borders
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFF1F5F9);

  // Status Colors (Matching backend state machine)
  static const Color statusPending = Color(0xFFD97706); // Amber 600
  static const Color statusPendingBg = Color(0xFFFEF3C7); // Amber 100

  static const Color statusInProgress = Color(0xFF2563EB); // Blue 600
  static const Color statusInProgressBg = Color(0xFFDBEAFE); // Blue 100

  static const Color statusCompleted = Color(0xFF16A34A); // Green 600
  static const Color statusCompletedBg = Color(0xFFDCFCE7); // Green 100

  static const Color statusRejected = Color(0xFFDC2626); // Red 600
  static const Color statusRejectedBg = Color(0xFFFEE2E2); // Red 100

  // Alerts
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF0284C7);
}
