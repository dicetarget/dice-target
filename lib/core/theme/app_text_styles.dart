import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.2,
    color: AppColors.ink,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.ink,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle targetNumber = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );

  static const TextStyle resultTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle resultValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle timer = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
  );

  /// ---- 18.6.1 additions ----

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle sheetTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle snackbar = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle buttonOnAccent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
}
