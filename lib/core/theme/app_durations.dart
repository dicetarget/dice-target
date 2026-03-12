class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);

  static const Duration shake = Duration(milliseconds: 420);
  static const Duration celebrate = Duration(milliseconds: 720);
  static const Duration snackbar = Duration(milliseconds: 1200);

  static const Duration rollStart = Duration(milliseconds: 700);
  static const Duration rollTarget = Duration(milliseconds: 700);
  static const Duration rollDice = Duration(milliseconds: 1000);

  static const Duration timeoutTick = Duration(milliseconds: 100);
  static const Duration invalidOverlay = Duration(milliseconds: 650);
}
