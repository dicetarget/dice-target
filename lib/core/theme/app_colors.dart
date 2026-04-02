import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary UI ─────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF3FE8FF);
  static const Color accentLt = Color(0xFF90D5F0);
  static const Color ink = Color(0xFFEEEAF6);

  // ── Background gradient ────────────────────────────────────────────────────
  static const Color bgTop = Color(0xFF090B18);
  static const Color bgBottom = Color(0xFF0D0F1F);

  // ── Cards / surfaces ───────────────────────────────────────────────────────
  static const Color card = Color(0xFF131628);
  static const Color cardBr = Color(0x33FFFFFF);

  // ── Dice ───────────────────────────────────────────────────────────────────
  static const Color diceFace = Color(0xFF1A1D35);
  static const Color diceFaceShine = Color(0xFF252849);
  static const Color dicePip = Color(0xFFE8E8F0);
  static const Color diceSelected = Color(0xFF9B6DFF);

  // ── Operator buttons ───────────────────────────────────────────────────────
  static const Color opAdd = Color(0xFF27AE60);
  static const Color opSubtract = Color(0xFFC0392B);
  static const Color opMultiply = Color(0xFFD4AC0D);
  static const Color opDivide = Color(0xFF2980B9);

  // ── Target display ─────────────────────────────────────────────────────────
  static const Color targetNumber = Color(0xFFFFD700);
  static const Color targetGlow = Color(0xFF3FE8FF);

  // ── Ratings ────────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFFFD700);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color solved = Color(0xFF4CAF82);
  static const Color failed = Color(0xFFE57373);
  static const Color muted = Color(0xFF4A5568);

  // ── Legacy ─────────────────────────────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color onAccent = Colors.white;
}
