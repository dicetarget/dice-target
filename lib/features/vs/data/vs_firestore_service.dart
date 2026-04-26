import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/vs_challenge_model.dart';
import '../domain/vs_player.dart';
import '../domain/vs_winner_logic.dart';
import 'vs_head_to_head_service.dart';

class VsFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _players => _db.collection('players');
  CollectionReference get _friendships => _db.collection('friendships');
  CollectionReference get _challenges => _db.collection('challenges');
  final _h2h = VsHeadToHeadService();

  Future<void> savePlayer(VsPlayer player) async {
    await _players.doc(player.id).set(player.toMap());
  }

  Future<VsPlayer?> findPlayer(String displayName) async {
    final snap = await _players
        .where('displayName', isEqualTo: displayName)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return VsPlayer.fromMap(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> addFriend(String myId, String friendId) async {
    final ids = [myId, friendId]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';
    await _friendships.doc(friendshipId).set({
      'playerA': ids[0],
      'playerB': ids[1],
      'requestedBy': myId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, String>> loadFriends(String myId) async {
    final asA = await _friendships
        .where('playerA', isEqualTo: myId)
        .where('status', isEqualTo: 'accepted')
        .get();
    final asB = await _friendships
        .where('playerB', isEqualTo: myId)
        .where('status', isEqualTo: 'accepted')
        .get();
    final friendIds = <String>[];
    for (final doc in asA.docs) {
      final data = doc.data() as Map<String, dynamic>;
      friendIds.add(data['playerB'] as String);
    }
    for (final doc in asB.docs) {
      final data = doc.data() as Map<String, dynamic>;
      friendIds.add(data['playerA'] as String);
    }
    final result = <String, String>{};
    for (final id in friendIds) {
      final snap = await _players.doc(id).get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final name = (data['displayName'] as String?) ?? '';
        result[id] = name.isNotEmpty ? name : id;
      } else {
        result[id] = id;
      }
    }
    return result;
  }

  Future<void> createChallenge(VsChallengeModel challenge) async {
    await _challenges.doc(challenge.id).set(challenge.toMap());
  }

  Future<List<VsChallengeModel>> loadChallenges(String myId) async {
    final asChallenger =
        await _challenges.where('challengerId', isEqualTo: myId).get();
    final asOpponent =
        await _challenges.where('opponentId', isEqualTo: myId).get();

    final seen = <String>{};
    final results = <VsChallengeModel>[];

    for (final doc in [...asChallenger.docs, ...asOpponent.docs]) {
      if (!seen.add(doc.id)) continue;
      final data = doc.data() as Map<String, dynamic>;

      final isChallenger = data['challengerId'] == myId;
      final deletedByMe = isChallenger
          ? (data['deletedByChallenger'] as bool? ?? false)
          : (data['deletedByOpponent'] as bool? ?? false);
      if (deletedByMe) continue;

      final model = VsChallengeModel.fromMap(data);
      if (!model.isExpired) results.add(model);
    }

    // Auto-delete oldest completed challenges beyond limit of 10
    const maxCompleted = 20;
    final completed = results
        .where((c) => c.isCompleted)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (completed.length > maxCompleted) {
      final toDelete = completed.take(completed.length - maxCompleted).toList();
      for (final c in toDelete) {
        final field = c.challengerId == myId
            ? 'deletedByChallenger'
            : 'deletedByOpponent';
        await _challenges.doc(c.id).update({field: true});
        results.removeWhere((r) => r.id == c.id);
      }
    }

    return results;
  }

  Future<VsChallengeModel?> loadChallenge(String challengeId) async {
    final snap = await _challenges.doc(challengeId).get();
    if (!snap.exists) return null;
    return VsChallengeModel.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> updateChallengeWithChallengerResult({
    required String challengeId,
    required int puzzles,
    required int timeMs,
    required int moves,
  }) async {
    final snap = await _challenges.doc(challengeId).get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;

    final challengerId = data['challengerId'] as String;
    final opponentId = data['opponentId'] as String;
    final opponentPlayed = (data['opponentPlayed'] as bool?) ?? false;
    final opponentPuzzles = (data['opponentPuzzles'] as int?) ?? 0;
    final opponentTimeMs = (data['opponentTimeMs'] as int?) ?? 0;
    final opponentMoves = (data['opponentMoves'] as int?) ?? 0;

    final newStatus = opponentPlayed ? 'completed' : 'pending';

    await _challenges.doc(challengeId).update({
      'challengerPuzzles': puzzles,
      'challengerTimeMs': timeMs,
      'challengerMoves': moves,
      'challengerPlayed': true,
      'status': newStatus,
    });

    if (opponentPlayed) {
      final vsMode = (data['vsMode'] as String?) ?? 'rush';
      final totalPuzzles = vsMode == 'speedrun_advanced' ? 5 : 3;
      final winner = VsWinnerLogic.determine(
        challengerPuzzles: puzzles,
        challengerTimeMs: timeMs,
        challengerMoves: moves,
        opponentPuzzles: opponentPuzzles,
        opponentTimeMs: opponentTimeMs,
        opponentMoves: opponentMoves,
        vsMode: vsMode,
        totalPuzzles: totalPuzzles,
      );
      final winnerId = winner == VsWinner.challenger
          ? challengerId
          : winner == VsWinner.opponent
              ? opponentId
              : '';

      await _h2h.update(
        userAId: challengerId,
        userBId: opponentId,
        winnerId: winnerId,
        userAMoves: moves,
        userBMoves: opponentMoves,
      );
    }
  }

  Future<void> updateChallengeWithOpponentResult({
    required String challengeId,
    required int puzzles,
    required int timeMs,
    required int moves,
  }) async {
    final snap = await _challenges.doc(challengeId).get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;

    final challengerId = data['challengerId'] as String;
    final opponentId = data['opponentId'] as String;
    final challengerPlayed = (data['challengerPlayed'] as bool?) ?? false;
    final challengerMoves = (data['challengerMoves'] as int?) ?? 0;
    final challengerPuzzles = (data['challengerPuzzles'] as int?) ?? 0;
    final challengerTimeMs = (data['challengerTimeMs'] as int?) ?? 0;

    final newStatus = challengerPlayed ? 'completed' : 'pending';

    await _challenges.doc(challengeId).update({
      'opponentPuzzles': puzzles,
      'opponentTimeMs': timeMs,
      'opponentMoves': moves,
      'opponentPlayed': true,
      'status': newStatus,
    });

    if (challengerPlayed) {
      final vsMode = (data['vsMode'] as String?) ?? 'rush';
      final totalPuzzles = vsMode == 'speedrun_advanced' ? 5 : 3;
      final winner = VsWinnerLogic.determine(
        challengerPuzzles: challengerPuzzles,
        challengerTimeMs: challengerTimeMs,
        challengerMoves: challengerMoves,
        opponentPuzzles: puzzles,
        opponentTimeMs: timeMs,
        opponentMoves: moves,
        vsMode: vsMode,
        totalPuzzles: totalPuzzles,
      );
      final winnerId = winner == VsWinner.challenger
          ? challengerId
          : winner == VsWinner.opponent
              ? opponentId
              : '';

      await _h2h.update(
        userAId: challengerId,
        userBId: opponentId,
        winnerId: winnerId,
        userAMoves: challengerMoves,
        userBMoves: moves,
      );
    }
  }

  Future<void> deleteChallenge(String challengeId, String myId) async {
    final snap = await _challenges.doc(challengeId).get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final challengerId = data['challengerId'] as String;

    // Nur ich markiere mein eigenes "deleted" Flag
    final field = myId == challengerId ? 'deletedByChallenger' : 'deletedByOpponent';
    await _challenges.doc(challengeId).update({field: true});
  }

  Future<void> acceptChallenge(String challengeId) async {
    await _challenges.doc(challengeId).update({
      'status': 'accepted',
    });
  }

  Future<void> declineChallenge(String challengeId) async {
    await _challenges.doc(challengeId).delete();
  }

  Future<Map<String, String>> loadPendingRequests(String myId) async {
    final asA = await _friendships
        .where('playerA', isEqualTo: myId)
        .where('status', isEqualTo: 'pending')
        .get();
    final asB = await _friendships
        .where('playerB', isEqualTo: myId)
        .where('status', isEqualTo: 'pending')
        .get();
    final result = <String, String>{};
    for (final doc in [...asA.docs, ...asB.docs]) {
      final data = doc.data() as Map<String, dynamic>;
      final requestedBy = data['requestedBy'] as String;
      if (requestedBy == myId) continue;
      final senderId = requestedBy;
      final playerSnap = await _players.doc(senderId).get();
      if (playerSnap.exists) {
        final playerData = playerSnap.data() as Map<String, dynamic>;
        final name = (playerData['displayName'] as String?) ?? '';
        result[senderId] = name.isNotEmpty ? name : senderId;
      } else {
        result[senderId] = senderId;
      }
    }
    return result;
  }

  Future<void> acceptFriend(String myId, String friendId) async {
    final ids = [myId, friendId]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';
    await _friendships.doc(friendshipId).update({'status': 'accepted'});
  }

  Future<void> declineFriend(String myId, String friendId) async {
    final ids = [myId, friendId]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';
    await _friendships.doc(friendshipId).delete();
  }

  Future<void> removeFriend(String myId, String friendId) async {
    final ids = [myId, friendId]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';
    await _friendships.doc(friendshipId).delete();
  }

  Future<bool> hasOpenChallenge(String myId, String friendId, String vsMode) async {
    final asChallenger = await _challenges
        .where('challengerId', isEqualTo: myId)
        .where('opponentId', isEqualTo: friendId)
        .where('vsMode', isEqualTo: vsMode)
        .get();
    final asOpponent = await _challenges
        .where('challengerId', isEqualTo: friendId)
        .where('opponentId', isEqualTo: myId)
        .where('vsMode', isEqualTo: vsMode)
        .get();
    final all = [...asChallenger.docs, ...asOpponent.docs];
    return all.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      if (status != 'invited' && status != 'accepted' && status != 'pending') {
        return false;
      }
      final iAmChallenger = (data['challengerId'] as String?) == myId;
      final deletedByMe = iAmChallenger
          ? (data['deletedByChallenger'] as bool? ?? false)
          : (data['deletedByOpponent'] as bool? ?? false);
      return !deletedByMe;
    });
  }
}
