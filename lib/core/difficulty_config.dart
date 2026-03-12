import 'package:dice/core/ui_op.dart';

class DifficultyConfig {
  final int maxTarget;
  final Duration? timeLimit;
  final List<UiOp> allowedOps;

  const DifficultyConfig({
    required this.maxTarget,
    required this.timeLimit,
    required this.allowedOps,
  });

  static const easy = DifficultyConfig(
    maxTarget: 50,
    timeLimit: null,
    allowedOps: [UiOp.add, UiOp.sub, UiOp.mul, UiOp.div],
  );

  static const medium = DifficultyConfig(
    maxTarget: 100,
    timeLimit: null,
    allowedOps: [UiOp.add, UiOp.sub, UiOp.mul, UiOp.div],
  );

  static const hard = DifficultyConfig(
    maxTarget: 150,
    timeLimit: null,
    allowedOps: [UiOp.add, UiOp.sub, UiOp.mul, UiOp.div],
  );
}
