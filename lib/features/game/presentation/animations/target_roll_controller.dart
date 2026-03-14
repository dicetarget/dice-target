import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/theme/app_durations.dart';

class TargetRollController {
  Timer? _frameTimer;
  Timer? _lockTimer;
  Completer<int>? _activeCompleter;

  final ValueNotifier<int> value = ValueNotifier<int>(0);
  final ValueNotifier<bool> locked = ValueNotifier<bool>(false);

  bool _isRolling = false;

  bool get isRolling => _isRolling;

  void startIdle({int initialValue = 0}) {
    cancel();
    value.value = initialValue;
    locked.value = false;
  }

  Future<int> roll({
    required Random random,
    required DifficultyConfig config,
    required int finalTarget,
    Duration lockDelay = AppDurations.rollStart,
    int intervalMs = 40,
  }) {
    cancel();

    _isRolling = true;
    locked.value = false;
    value.value = random.nextInt(config.maxTarget) + 1;

    final completer = Completer<int>();
    _activeCompleter = completer;

    _frameTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      value.value = random.nextInt(config.maxTarget) + 1;
    });

    _lockTimer = Timer(lockDelay, () {
      _frameTimer?.cancel();
      _frameTimer = null;

      value.value = finalTarget;
      locked.value = true;
      _isRolling = false;

      if (!completer.isCompleted) {
        completer.complete(finalTarget);
      }
    });

    return completer.future;
  }

  void cancel() {
    _frameTimer?.cancel();
    _frameTimer = null;

    _lockTimer?.cancel();
    _lockTimer = null;

    _isRolling = false;

    final completer = _activeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(value.value);
    }
    _activeCompleter = null;
  }

  void dispose() {
    cancel();
    value.dispose();
    locked.dispose();
  }
}
