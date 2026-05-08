import 'package:flutter/material.dart';

/// Dice Target Design System v2.0 — Premium Tactile
/// 60-30-10 Regel: Deep Charcoal / Cool Silver / Champagne Gold
abstract final class AppColors {

  // ── Backgrounds (60%) ─────────────────────────────────────────
  static const Color backgroundPrimary   = Color(0xFF12171D); // Deep Charcoal
  static const Color backgroundCard      = Color(0xFF1A2030); // Card surface
  static const Color backgroundDeep      = Color(0xFF0D1120); // Deepest bg (Target card)
  static const Color backgroundElevated  = Color(0xFF161D2B); // Slightly raised

  // ── Text / Secondary (30%) ────────────────────────────────────
  static const Color textPrimary         = Color(0xFFE0E6ED); // Cool Silver
  static const Color textSecondary       = Color(0xFF8A9BC0); // Muted blue-gray
  static const Color textHint            = Color(0xFF5A6780); // Hint / labels
  static const Color borderSubtle        = Color(0xFF2A3350); // Card borders
  static const Color borderDivider       = Color(0xFF1E2535); // Dividers

  // ── Accent (10%) ──────────────────────────────────────────────
  static const Color accentGold          = Color(0xFFD4AF37); // Champagne Gold
  static const Color accentGoldDark      = Color(0xFFA88A22); // Gold pressed/dark

  // ── Operators — entsättigte Premium-Farben ────────────────────
  static const Color opPlusBackground    = Color(0xFF2D5A3D);
  static const Color opPlusForeground    = Color(0xFF7ECF9A);
  static const Color opMinusBackground   = Color(0xFF5A2D2D);
  static const Color opMinusForeground   = Color(0xFFCF7E7E);
  static const Color opTimesBackground   = Color(0xFF4A3D1A);
  static const Color opTimesForeground   = Color(0xFFC9A832);
  static const Color opDivBackground     = Color(0xFF1A3A5A);
  static const Color opDivForeground     = Color(0xFF6AABDF);

  // ── Dice ──────────────────────────────────────────────────────
  static const Color diceIvory           = Color(0xFFF0EAD6); // Würfel-Körper
  static const Color diceDot             = Color(0xFF2C2A2A); // Eingravierte Augen

  // ── Mode Colors ───────────────────────────────────────────────
  static const Color modeDaily           = Color(0xFFD4AF37); // Gold (Daily Challenge)
  static const Color modeRush            = Color(0xFF4CAF50); // Green (Rush)
  static const Color modeVS              = Color(0xFF00BCD4); // Cyan (VS Mode)
  static const Color modeFreePlay        = Color(0xFFE0E6ED); // Silver (Free Play)

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success             = Color(0xFF7ECF9A);
  static const Color error               = Color(0xFFCF7E7E);
  static const Color warning             = Color(0xFFC9A832);

  // ── Inner Shadow helpers (für BoxDecoration) ──────────────────
  /// Helle Kante oben-links (Lichtquelle simulieren)
  static const Color innerShadowLight    = Color(0x2EFFFFFF); // rgba(255,255,255,0.18)
  /// Dunkle Kante unten-rechts (Tiefe simulieren)
  static const Color innerShadowDark     = Color(0x59000000); // rgba(0,0,0,0.35)

  // ── Border Radius (als statische Konstanten für Konsistenz) ───
  static const double radiusButton       = 14.0;
  static const double radiusOperator     = 12.0;
  static const double radiusDie          = 12.0;
  static const double radiusCard         = 14.0;
  static const double radiusChip         = 20.0;
}
