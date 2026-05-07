import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bgDark      = Color(0xFF12171D);
  static const Color surface     = Color(0xFF1C2430);
  static const Color surfaceHigh = Color(0xFF243040);

  // ── Tactile light/shadow tokens ────────────────────────────────────────────
  static const Color highlight   = Color(0x12FFFFFF); // top-left light
  static const Color shadowDeep  = Color(0x8C000000); // bottom-right shadow

  // ── Gold accent ────────────────────────────────────────────────────────────
  static const Color gold        = Color(0xFFC8A84B);
  static const Color goldLight   = Color(0xFFE8C96A);
  static const Color goldDark    = Color(0xFF9A7A2E);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color ink         = Color(0xFFE8E2D4);
  static const Color inkMuted    = Color(0xFF7A8A9A);
  static const Color inkFaint    = Color(0xFF3A4A5A);

  // ── Operator buttons ───────────────────────────────────────────────────────
  static const Color opAdd       = Color(0xFF2E7D52);
  static const Color opSubtract  = Color(0xFF8B2E2E);
  static const Color opMultiply  = Color(0xFF8B7020);
  static const Color opDivide    = Color(0xFF1E5A8B);

  // ── Dice ───────────────────────────────────────────────────────────────────
  static const Color diceBody    = Color(0xFFE8E4D8);
  static const Color diceBodyShadow = Color(0xFFB8B4A8);
  static const Color dicePip     = Color(0xFF2A3040);
  static const Color diceSelected = Color(0xFFC8A84B);

  // ── Target display ─────────────────────────────────────────────────────────
  static const Color targetNumber = Color(0xFFC8A84B);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color solved      = Color(0xFF4CAF82);
  static const Color failed      = Color(0xFFE57373);
  static const Color muted       = Color(0xFF3A4A5A);

  // ── Legacy aliases (für schrittweise Migration) ────────────────────────────
  static const Color cardBr      = Color(0x33FFFFFF);
  static const Color accent      = gold;
  static const Color accentLt    = goldLight;
  static const Color bgTop       = bgDark;
  static const Color bgBottom    = bgDark;
  static const Color card        = surface;
  static const Color white       = Colors.white;
  static const Color black       = Colors.black;
  static const Color onAccent    = Colors.black;
}
