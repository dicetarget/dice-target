import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/vs_challenge_model.dart';
import '../domain/vs_player.dart';

class VsFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _players => _db.collection('players');
  CollectionReference get _friendships => _db.collection('friendships');
  CollectionReference get _challenges => _db.collection('challenges');

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
      final model =
          VsChallengeModel.fromMap(doc.data() as Map<String, dynamic>);
      if (!model.isExpired) results.add(model);
    }
    return results;
  }

  Future<void> updateChallengeWithChallengerResult({
    required String challengeId,
    required int puzzles,
    required int timeMs,
    required int moves,
  }) async {
    await _challenges.doc(challengeId).update({
      'challengerPuzzles': puzzles,
      'challengerTimeMs': timeMs,
      'challengerMoves': moves,
      'challengerPlayed': true,
      'status': 'pending',
    });
  }

  Future<void> updateChallengeWithOpponentResult({
    required String challengeId,
    required int puzzles,
    required int timeMs,
    required int moves,
  }) async {
    await _challenges.doc(challengeId).update({
      'opponentPuzzles': puzzles,
      'opponentTimeMs': timeMs,
      'opponentMoves': moves,
      'status': 'completed',
    });
  }

  Future<void> deleteChallenge(String challengeId) async {
    await _challenges.doc(challengeId).delete();
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
}
