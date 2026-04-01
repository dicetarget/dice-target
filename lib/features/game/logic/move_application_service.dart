import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_engine.dart';

class MoveApplicationResult {
  final List<int> removeIndicesDesc;
  final int mergedValue;
  final bool willEndAfterMove;

  const MoveApplicationResult({
    required this.removeIndicesDesc,
    required this.mergedValue,
    required this.willEndAfterMove,
  });
}

class MoveProgressResult {
  final int moves;

  const MoveProgressResult({required this.moves});
}

class MoveApplicationService {
  final MoveEngine _moveEngine;

  const MoveApplicationService({MoveEngine moveEngine = const MoveEngine()})
    : _moveEngine = moveEngine;

  MoveApplicationResult? buildMove({
    required List<int> diceValues,
    required List<int> selectedIndices,
    required UiOp op,
    GameMode? gameMode,
  }) {
    if (selectedIndices.length < 2) return null;

    if (gameMode == GameMode.daily && selectedIndices.length > 4) {
      return null;
    }

    final sortedIndices = List<int>.from(selectedIndices)..sort();

    final selectedValues = sortedIndices.map((i) => diceValues[i]).toList();

    final merged = _moveEngine.combineValues(selectedValues, op);
    if (merged == null) return null;

    final willEndAfterMove = (diceValues.length - sortedIndices.length + 1) == 1;

    final removeIndicesDesc = List<int>.from(sortedIndices)..sort((a, b) => b.compareTo(a));

    return MoveApplicationResult(
      removeIndicesDesc: removeIndicesDesc,
      mergedValue: merged,
      willEndAfterMove: willEndAfterMove,
    );
  }

  List<int> applyToDiceValues({
    required List<int> diceValues,
    required List<int> removeIndicesDesc,
    required int mergedValue,
  }) {
    final next = List<int>.from(diceValues);

    for (final i in removeIndicesDesc) {
      next.removeAt(i);
    }

    next.add(mergedValue);

    return next;
  }

  MoveProgressResult registerMove({required int currentMoves}) {
    return MoveProgressResult(moves: currentMoves + 1);
  }

  List<String?> buildMaskLabels({required int diceCount, required String? mergedMaskLabel}) {
    if (diceCount <= 0) return const [];

    return [for (var i = 0; i < diceCount - 1; i++) null, mergedMaskLabel];
  }
}
