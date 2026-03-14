import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:dice/core/theme/app_durations.dart';

class DiceRollController {
  Timer? _frameTimer;
  Timer? _stopTimer;
  Completer<List<int>>? _activeCompleter;

  final ValueNotifier<List<int>> dice = ValueNotifier<List<int>>(
    List<int>.filled(5, 1),
  );

  bool _isRolling = false;

  bool get isRolling => _isRolling;

  void startIdle({List<int>? initialDice}) {
    cancel();
    dice.value = initialDice ?? List<int>.filled(5, 1);
  }

  Future<List<int>> roll({
    required Random random,
    required List<int> finalDice,
    Duration duration = AppDurations.rollDice,
    int intervalMs = 55,
  }) {
    cancel();

    _isRolling = true;

    final completer = Completer<List<int>>();
    _activeCompleter = completer;

    _frameTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      dice.value = List<int>.generate(5, (_) => random.nextInt(6) + 1);
    });

    _stopTimer = Timer(duration, () {
      _frameTimer?.cancel();
      _frameTimer = null;

      dice.value = finalDice;
      _isRolling = false;

      if (!completer.isCompleted) {
        completer.complete(finalDice);
      }
    });

    return completer.future;
  }

  void cancel() {
    _frameTimer?.cancel();
    _frameTimer = null;

    _stopTimer?.cancel();
    _stopTimer = null;

    _isRolling = false;

    final completer = _activeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(dice.value);
    }

    _activeCompleter = null;
  }

  void dispose() {
    cancel();
    dice.dispose();
  }
}
