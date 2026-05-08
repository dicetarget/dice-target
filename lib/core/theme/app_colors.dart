import 'package:flutter/material.dart';

/// Dice Target Design System v2.0 — Premium Tactile
/// 60-30-10: Deep Charcoal (bg) / Cool Silver (text) / Champagne Gold (accent)
abstract final class AppColors {

  // ── Backgrounds (60%) ─────────────────────────────────────────
  static const Color bgDark              = Color(0xFF12171D); // Deep Charcoal — Scaffold bg
  static const Color backgroundCard      = Color(0xFF1A2030); // Card surface
  static const Color backgroundDeep      = Color(0xFF0D1120); // Target card bg
  static const Color backgroundElevated  = Color(0xFF161D2B); // Leicht erhöht (Stats, Friends)
  static const Color borderSubtle        = Color(0xFF2A3350); // Card borders
  static const Color borderDivider       = Color(0xFF1E2535); // Dividers

  // ── Text / Secondary (30%) ────────────────────────────────────
  static const Color ink                 = Color(0xFFE0E6ED); // Cool Silver — primary text
  static const Color inkMuted            = Color(0xFF8A9BC0); // Muted blue-gray — subtitles
  static const Color inkHint             = Color(0xFF5A6780); // Hints, labels, metadata

  // ── Accent Gold (10%) ─────────────────────────────────────────
  static const Color gold                = Color(0xFFD4AF37); // Champagne Gold — Logo, Target, CTA
  static const Color goldDark            = Color(0xFFA88A22); // Gold pressed / dark variant

  // ── Dice ──────────────────────────────────────────────────────
  static const Color diceIvory           = Color(0xFFF0EAD6); // Würfel-Körper (Elfenbein)
  static const Color dicePip             = Color(0xFF2C2A2A); // Eingravierte Augen

  // ── Operatoren — entsättigte Premium-Farben ───────────────────
  static const Color opPlusBackground    = Color(0xFF2D5A3D);
  static const Color opPlusForeground    = Color(0xFF7ECF9A);
  static const Color opMinusBackground   = Color(0xFF5A2D2D);
  static const Color opMinusForeground   = Color(0xFFCF7E7E);
  static const Color opTimesBackground   = Color(0xFF4A3D1A);
  static const Color opTimesForeground   = Color(0xFFC9A832);
  static const Color opDivBackground     = Color(0xFF1A3A5A);
  static const Color opDivForeground     = Color(0xFF6AABDF);

  // ── Mode Colors ───────────────────────────────────────────────
  static const Color modeDaily           = Color(0xFFD4AF37); // Gold
  static const Color modeRush            = Color(0xFF4CAF50); // Green
  static const Color modeVS              = Color(0xFF00BCD4); // Cyan
  static const Color modeFreePlay        = Color(0xFFE0E6ED); // Silver

  // ── Inner Shadow (für TactileButton / BoxDecoration) ──────────
  static const Color innerShadowLight    = Color(0x2EFFFFFF); // rgba(255,255,255,0.18) oben
  static const Color innerShadowDark     = Color(0x59000000); // rgba(0,0,0,0.35) unten

  // ── Border Radius ─────────────────────────────────────────────
  static const double radiusButton       = 14.0;
  static const double radiusOperator     = 12.0;
  static const double radiusDie          = 12.0;
  static const double radiusCard         = 14.0;
  static const double radiusChip         = 20.0;

  // ── Legacy aliases (für schrittweise Migration) ───────────────
  static const Color surface         = backgroundCard;
  static const Color surfaceHigh     = backgroundElevated;
  static const Color card            = backgroundCard;
  static const Color cardBr          = Color(0x33FFFFFF);
  static const Color accent          = gold;
  static const Color accentLt        = goldLight;
  static const Color goldLight       = Color(0xFFE8C96A);
  static const Color inkFaint        = inkHint;
  static const Color solved          = Color(0xFF4CAF82);
  static const Color failed          = Color(0xFFE57373);
  static const Color muted           = Color(0xFF3A4A5A);
  static const Color opAdd           = opPlusBackground;
  static const Color opSubtract      = opMinusBackground;
  static const Color opMultiply      = opTimesBackground;
  static const Color opDivide        = opDivBackground;
  static const Color highlight       = innerShadowLight;
  static const Color shadowDeep      = Color(0x8C000000);
  static const Color targetNumber    = gold;
  static const Color diceBody        = diceIvory;
  static const Color diceBodyShadow  = Color(0xFFB8B4A8);
  static const Color diceSelected    = gold;
  static const Color bgTop           = bgDark;
  static const Color bgBottom        = bgDark;
  static const Color white           = Color(0xFFFFFFFF);
  static const Color black           = Color(0xFF000000);
  static const Color onAccent        = Color(0xFF000000);
}
