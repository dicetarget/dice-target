import 'dart:convert';

const int kVsChallengeTtlDays = 7;

class VsChallenge {
  final int seed;
  final int puzzlesSolved;
  final int timeUsedMs;
  final int movesUsed;
  final DateTime createdAt;

  const VsChallenge({
    required this.seed,
    required this.puzzlesSolved,
    required this.timeUsedMs,
    required this.movesUsed,
    required this.createdAt,
  });

  String toBase64() {
    final map = {
      'seed': seed,
      'puzzlesSolved': puzzlesSolved,
      'timeUsedMs': timeUsedMs,
      'movesUsed': movesUsed,
      'createdAt': createdAt.toIso8601String(),
    };
    final json = jsonEncode(map);
    return base64Url.encode(utf8.encode(json));
  }

  factory VsChallenge.fromBase64(String base64) {
    final json = utf8.decode(base64Url.decode(base64));
    final map = jsonDecode(json) as Map<String, dynamic>;
    return VsChallenge(
      seed: map['seed'] as int,
      puzzlesSolved: map['puzzlesSolved'] as int,
      timeUsedMs: map['timeUsedMs'] as int,
      movesUsed: map['movesUsed'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  bool isExpired() {
    final age = DateTime.now().difference(createdAt);
    return age.inDays >= kVsChallengeTtlDays;
  }
}
