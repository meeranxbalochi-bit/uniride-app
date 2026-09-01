import 'package:flutter/material.dart';

/// Curated color palette for UniRide — dark, premium, transit-themed.
class AppColors {
  AppColors._();

  // ─── Base Surfaces ────────────────────────────────────
  static const Color scaffold = Color(0xFF020617);       // slate-950
  static const Color surface = Color(0xFF0F172A);        // slate-900
  static const Color surfaceLight = Color(0xFF1E293B);   // slate-800
  static const Color surfaceMedium = Color(0xFF334155);  // slate-700

  // ─── Primary (Indigo) ─────────────────────────────────
  static const Color primary = Color(0xFF6366F1);        // indigo-500
  static const Color primaryLight = Color(0xFF818CF8);   // indigo-400
  static const Color primaryDark = Color(0xFF4F46E5);    // indigo-600
  static const Color primaryContainer = Color(0xFF312E81); // indigo-900

  // ─── Accent (Amber) ───────────────────────────────────
  static const Color accent = Color(0xFFF59E0B);         // amber-500
  static const Color accentLight = Color(0xFFFBBF24);    // amber-400
  static const Color accentDark = Color(0xFFD97706);     // amber-600
  static const Color accentContainer = Color(0xFF78350F); // amber-900

  // ─── Semantic ─────────────────────────────────────────
  static const Color success = Color(0xFF10B981);        // emerald-500
  static const Color successContainer = Color(0xFF064E3B);
  static const Color error = Color(0xFFEF4444);          // red-500
  static const Color errorContainer = Color(0xFF7F1D1D);
  static const Color warning = Color(0xFFF97316);        // orange-500
  static const Color warningContainer = Color(0xFF7C2D12);
  static const Color info = Color(0xFF3B82F6);           // blue-500
  static const Color infoContainer = Color(0xFF1E3A5F);

  // ─── Text ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);    // slate-50
  static const Color textSecondary = Color(0xFF94A3B8);  // slate-400
  static const Color textMuted = Color(0xFF64748B);      // slate-500
  static const Color textDisabled = Color(0xFF475569);   // slate-600

  // ─── Borders & Dividers ───────────────────────────────
  static const Color border = Color(0xFF1E293B);         // slate-800
  static const Color borderLight = Color(0x1AFFFFFF);    // white 10%
  static const Color divider = Color(0xFF1E293B);

  // ─── Status Colors for Bus ────────────────────────────
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusOffline = Color(0xFF6B7280);
  static const Color statusInTransit = Color(0xFF3B82F6);
  static const Color statusIdle = Color(0xFFF59E0B);
  static const Color statusMaintenance = Color(0xFFEF4444);

  // ─── Gradients ────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFA78BFA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the color for a given bus status string.
  static Color busStatusColor(String status) {
    switch (status) {
      case 'online':
        return statusOnline;
      case 'in_transit':
        return statusInTransit;
      case 'idle':
        return statusIdle;
      case 'maintenance':
        return statusMaintenance;
      case 'offline':
      default:
        return statusOffline;
    }
  }
}
