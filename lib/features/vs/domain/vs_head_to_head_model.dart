class VsHeadToHeadModel {
  final int totalMatches;
  final int userAWins;
  final int userBWins;
  final double userAAvgMoves;
  final double userBAvgMoves;
  final String lastWinnerId;
  final DateTime? lastPlayedAt;

  const VsHeadToHeadModel({
    required this.totalMatches,
    required this.userAWins,
    required this.userBWins,
    required this.userAAvgMoves,
    required this.userBAvgMoves,
    required this.lastWinnerId,
    required this.lastPlayedAt,
  });

  factory VsHeadToHeadModel.empty() => const VsHeadToHeadModel(
        totalMatches: 0,
        userAWins: 0,
        userBWins: 0,
        userAAvgMoves: 0.0,
        userBAvgMoves: 0.0,
        lastWinnerId: '',
        lastPlayedAt: null,
      );

  factory VsHeadToHeadModel.fromMap(Map<String, dynamic> map) {
    final ts = map['lastPlayedAt'];
    DateTime? lastPlayed;
    if (ts != null) {
      try {
        // Firestore Timestamp
        lastPlayed = (ts as dynamic).toDate() as DateTime;
      } catch (_) {
        lastPlayed = null;
      }
    }
    return VsHeadToHeadModel(
      totalMatches: (map['totalMatches'] as int?) ?? 0,
      userAWins: (map['userAWins'] as int?) ?? 0,
      userBWins: (map['userBWins'] as int?) ?? 0,
      userAAvgMoves: ((map['userAAvgMoves'] as num?) ?? 0).toDouble(),
      userBAvgMoves: ((map['userBAvgMoves'] as num?) ?? 0).toDouble(),
      lastWinnerId: (map['lastWinnerId'] as String?) ?? '',
      lastPlayedAt: lastPlayed,
    );
  }

  Map<String, dynamic> toMap() => {
        'totalMatches': totalMatches,
        'userAWins': userAWins,
        'userBWins': userBWins,
        'userAAvgMoves': userAAvgMoves,
        'userBAvgMoves': userBAvgMoves,
        'lastWinnerId': lastWinnerId,
        'lastPlayedAt': lastPlayedAt,
      };

  /// Gibt den doc-ID-String zurück: kleinere userId zuerst
  static String docId(String idA, String idB) {
    final ids = [idA, idB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// true wenn idA === userA im Dokument
  static bool isUserA(String myId, String friendId) {
    final ids = [myId, friendId]..sort();
    return ids[0] == myId;
  }
}
