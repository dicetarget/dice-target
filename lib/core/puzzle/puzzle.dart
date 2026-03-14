class Puzzle {
  final int target;
  final List<int> dice;
  final int seed;
  final bool isGuaranteedSolvable;
  final int? puzzleIndex;

  Puzzle({
    required this.target,
    required List<int> dice,
    required this.seed,
    this.isGuaranteedSolvable = false,
    this.puzzleIndex,
  }) : dice = List.unmodifiable(dice);

  Puzzle copyWith({
    int? target,
    List<int>? dice,
    int? seed,
    bool? isGuaranteedSolvable,
    int? puzzleIndex,
  }) {
    return Puzzle(
      target: target ?? this.target,
      dice: dice ?? this.dice,
      seed: seed ?? this.seed,
      isGuaranteedSolvable: isGuaranteedSolvable ?? this.isGuaranteedSolvable,
      puzzleIndex: puzzleIndex ?? this.puzzleIndex,
    );
  }
}
