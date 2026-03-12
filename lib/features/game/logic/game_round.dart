// lib/features/game/logic/game_round.dart

class GameRound {
  final int target;
  final List<int> dice;
  final int moves;
  final RoundStatus status;
  final EndReason? endReason;

  const GameRound({
    required this.target,
    required this.dice,
    this.moves = 0,
    this.status = RoundStatus.playing,
    this.endReason,
  });

  GameRound copyWith({
    int? target,
    List<int>? dice,
    int? moves,
    RoundStatus? status,
    EndReason? endReason,
    bool clearEndReason = false,
  }) {
    return GameRound(
      target: target ?? this.target,
      dice: dice ?? this.dice,
      moves: moves ?? this.moves,
      status: status ?? this.status,
      endReason: clearEndReason ? null : (endReason ?? this.endReason),
    );
  }
}

enum RoundStatus { playing, ended }

enum EndReason { solved, failed, timeout }
