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

  Future<VsPlayer?> findPlayer(String id) async {
    final snap = await _players.where('id', isEqualTo: id).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return VsPlayer.fromMap(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> addFriend(String myId, String friendId) async {
    final ids = [myId, friendId]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';
    await _friendships.doc(friendshipId).set({
      'playerA': myId,
      'playerB': friendId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> loadFriends(String myId) async {
    final asA = await _friendships.where('playerA', isEqualTo: myId).get();
    final asB = await _friendships.where('playerB', isEqualTo: myId).get();

    final friends = <String>[];
    for (final doc in asA.docs) {
      final data = doc.data() as Map<String, dynamic>;
      friends.add(data['playerB'] as String);
    }
    for (final doc in asB.docs) {
      final data = doc.data() as Map<String, dynamic>;
      friends.add(data['playerA'] as String);
    }
    return friends;
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
}
