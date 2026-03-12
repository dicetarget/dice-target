import 'package:flutter/foundation.dart';

@immutable
class DiceState {
  final int value;
  final bool isUsed;
  final bool isSelected;
  final String? maskLabel;

  const DiceState({
    required this.value,
    this.isUsed = false,
    this.isSelected = false,
    this.maskLabel,
  });

  DiceState copyWith({
    int? value,
    bool? isUsed,
    bool? isSelected,
    String? maskLabel,
    bool clearMaskLabel = false,
  }) {
    return DiceState(
      value: value ?? this.value,
      isUsed: isUsed ?? this.isUsed,
      isSelected: isSelected ?? this.isSelected,
      maskLabel: clearMaskLabel ? null : (maskLabel ?? this.maskLabel),
    );
  }
}
