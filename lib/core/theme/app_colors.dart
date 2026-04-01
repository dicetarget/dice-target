import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary UI ─────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF3FE8FF); // Cyan — primärer Akzent
  static const Color accentLt = Color(0xFF90D5F0); // Helles Cyan für Text/Icons
  static const Color ink = Color(0xFFEEEAF6); // Helles Weiss für Text

  // ── Background gradient ────────────────────────────────────────────────────
  static const Color bgTop = Color(0xFF090B18);
  static const Color bgBottom = Color(0xFF0D0F1F);

  // ── Cards / surfaces ───────────────────────────────────────────────────────
  static const Color card = Color(0xFF131628);
  static const Color cardBr = Color(0x33FFFFFF);

  // ── Dice ───────────────────────────────────────────────────────────────────
  static const Color diceFace = Color(0xFF1A1D35);
  static const Color diceFaceShine = Color(0xFF252849);
  static const Color dicePip = Color(0xFFCECBFF);
  static const Color diceSelected = Color(0xFF9B6DFF);

  // ── Operator buttons ───────────────────────────────────────────────────────
  static const Color opAdd = Color(0xFF27AE60); // Grün
  static const Color opSubtract = Color(0xFFC0392B); // Dunkelrot
  static const Color opMultiply = Color(0xFFD4AC0D); // Gold
  static const Color opDivide = Color(0xFF2980B9); // Blau

  // ── Target display ─────────────────────────────────────────────────────────
  static const Color targetNumber = Color(0xFFFFD700);
  static const Color targetGlow = Color(0xFF3FE8FF);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color solved = Color(0xFF4CAF82);
  static const Color failed = Color(0xFFE57373);
  static const Color muted = Color(0xFF5E5878);

  // ── Legacy ─────────────────────────────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color onAccent = Colors.white;
}
