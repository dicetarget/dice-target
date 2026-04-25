class VsChallengeModel {
  final String id;
  final String challengerId;
  final String opponentId;
  final String challengerName;
  final String opponentName;
  final int seed;
  final int challengerPuzzles;
  final int challengerTimeMs;
  final int challengerMoves;
  final int? opponentPuzzles;
  final int? opponentTimeMs;
  final int? opponentMoves;
  final bool challengerPlayed;
  final bool opponentPlayed;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String vsMode; // 'rush' or 'speedrun'

  const VsChallengeModel({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    required this.challengerName,
    required this.opponentName,
    required this.seed,
    required this.challengerPuzzles,
    required this.challengerTimeMs,
    required this.challengerMoves,
    this.opponentPuzzles,
    this.opponentTimeMs,
    this.opponentMoves,
    this.challengerPlayed = false,
    this.opponentPlayed = false,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.vsMode,
  });

  static VsChallengeModel create({
    required String challengerId,
    required String opponentId,
    required String challengerName,
    required String opponentName,
    required int seed,
    required String vsMode,
  }) {
    final now = DateTime.now();
    return VsChallengeModel(
      id: now.millisecondsSinceEpoch.toString(),
      challengerId: challengerId,
      opponentId: opponentId,
      challengerName: challengerName,
      opponentName: opponentName,
      seed: seed,
      challengerPuzzles: 0,
      challengerTimeMs: 0,
      challengerMoves: 0,
      opponentPuzzles: null,
      opponentTimeMs: null,
      opponentMoves: null,
      challengerPlayed: false,
      opponentPlayed: false,
      status: 'invited',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      vsMode: vsMode,
    );
  }

  bool get isInvited => status == 'invited';
  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  VsChallengeModel withOpponentResult({
    required int puzzles,
    required int timeMs,
    required int moves,
  }) {
    return VsChallengeModel(
      id: id,
      challengerId: challengerId,
      opponentId: opponentId,
      challengerName: challengerName,
      opponentName: opponentName,
      seed: seed,
      challengerPuzzles: challengerPuzzles,
      challengerTimeMs: challengerTimeMs,
      challengerMoves: challengerMoves,
      opponentPuzzles: puzzles,
      opponentTimeMs: timeMs,
      opponentMoves: moves,
      challengerPlayed: challengerPlayed,
      opponentPlayed: true,
      status: 'completed',
      createdAt: createdAt,
      expiresAt: expiresAt,
      vsMode: vsMode,
    );
  }

  VsChallengeModel withAccepted() {
    return VsChallengeModel(
      id: id,
      challengerId: challengerId,
      opponentId: opponentId,
      challengerName: challengerName,
      opponentName: opponentName,
      seed: seed,
      challengerPuzzles: challengerPuzzles,
      challengerTimeMs: challengerTimeMs,
      challengerMoves: challengerMoves,
      opponentPuzzles: opponentPuzzles,
      opponentTimeMs: opponentTimeMs,
      opponentMoves: opponentMoves,
      challengerPlayed: challengerPlayed,
      opponentPlayed: opponentPlayed,
      status: 'accepted',
      createdAt: createdAt,
      expiresAt: expiresAt,
      vsMode: vsMode,
    );
  }

  VsChallengeModel withChallengerResult({
    required int puzzles,
    required int timeMs,
    required int moves,
  }) {
    return VsChallengeModel(
      id: id,
      challengerId: challengerId,
      opponentId: opponentId,
      challengerName: challengerName,
      opponentName: opponentName,
      seed: seed,
      challengerPuzzles: puzzles,
      challengerTimeMs: timeMs,
      challengerMoves: moves,
      opponentPuzzles: opponentPuzzles,
      opponentTimeMs: opponentTimeMs,
      opponentMoves: opponentMoves,
      challengerPlayed: true,
      opponentPlayed: opponentPlayed,
      status: 'pending',
      createdAt: createdAt,
      expiresAt: expiresAt,
      vsMode: vsMode,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'challengerId': challengerId,
        'opponentId': opponentId,
        'challengerName': challengerName,
        'opponentName': opponentName,
        'seed': seed,
        'challengerPuzzles': challengerPuzzles,
        'challengerTimeMs': challengerTimeMs,
        'challengerMoves': challengerMoves,
        'opponentPuzzles': opponentPuzzles,
        'opponentTimeMs': opponentTimeMs,
        'opponentMoves': opponentMoves,
        'challengerPlayed': challengerPlayed,
        'opponentPlayed': opponentPlayed,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'vsMode': vsMode,
      };

  factory VsChallengeModel.fromMap(Map<String, dynamic> map) => VsChallengeModel(
        id: map['id'] as String,
        challengerId: map['challengerId'] as String,
        opponentId: map['opponentId'] as String,
        challengerName: (map['challengerName'] as String?) ?? '',
        opponentName: (map['opponentName'] as String?) ?? '',
        seed: (map['seed'] as num?)?.toInt() ?? 0,
        challengerPuzzles: (map['challengerPuzzles'] as num?)?.toInt() ?? 0,
        challengerTimeMs: (map['challengerTimeMs'] as num?)?.toInt() ?? 0,
        challengerMoves: (map['challengerMoves'] as num?)?.toInt() ?? 0,
        opponentPuzzles: (map['opponentPuzzles'] as num?)?.toInt(),
        opponentTimeMs: (map['opponentTimeMs'] as num?)?.toInt(),
        opponentMoves: (map['opponentMoves'] as num?)?.toInt(),
        challengerPlayed: (map['challengerPlayed'] as bool?) ?? false,
        opponentPlayed: (map['opponentPlayed'] as bool?) ?? false,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        expiresAt: DateTime.parse(map['expiresAt'] as String),
        vsMode: (map['vsMode'] as String?) ?? 'rush',
      );
}
