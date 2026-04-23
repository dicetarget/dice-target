import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/vs_head_to_head_model.dart';

class VsHeadToHeadService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('head_to_head');

  Future<VsHeadToHeadModel> load(String myId, String friendId) async {
    try {
      final docId = VsHeadToHeadModel.docId(myId, friendId);
      final snap = await _col.doc(docId).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('H2H load timeout'),
      );
      if (!snap.exists) return VsHeadToHeadModel.empty();
      return VsHeadToHeadModel.fromMap(snap.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('H2H load error: $e');
      return VsHeadToHeadModel.empty();
    }
  }

  Future<void> update({
    required String userAId,
    required String userBId,
    required String winnerId,
    required int userAMoves,
    required int userBMoves,
  }) async {
    final docId = VsHeadToHeadModel.docId(userAId, userBId);
    final isAFirst = VsHeadToHeadModel.isUserA(userAId, userBId);

    final String docUserAId = isAFirst ? userAId : userBId;
    final String docUserBId = isAFirst ? userBId : userAId;
    final int docUserAMoves = isAFirst ? userAMoves : userBMoves;
    final int docUserBMoves = isAFirst ? userBMoves : userAMoves;

    final ref = _col.doc(docId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      VsHeadToHeadModel current;
      if (snap.exists) {
        current = VsHeadToHeadModel.fromMap(snap.data() as Map<String, dynamic>);
      } else {
        current = VsHeadToHeadModel.empty();
      }

      final newTotal = current.totalMatches + 1;
      final newAWins = current.userAWins + (winnerId == docUserAId ? 1 : 0);
      final newBWins = current.userBWins + (winnerId == docUserBId ? 1 : 0);

      final newAAvg = current.totalMatches == 0
          ? docUserAMoves.toDouble()
          : ((current.userAAvgMoves * current.totalMatches) + docUserAMoves) / newTotal;
      final newBAvg = current.totalMatches == 0
          ? docUserBMoves.toDouble()
          : ((current.userBAvgMoves * current.totalMatches) + docUserBMoves) / newTotal;

      final updated = VsHeadToHeadModel(
        totalMatches: newTotal,
        userAWins: newAWins,
        userBWins: newBWins,
        userAAvgMoves: double.parse(newAAvg.toStringAsFixed(1)),
        userBAvgMoves: double.parse(newBAvg.toStringAsFixed(1)),
        lastWinnerId: winnerId,
        lastPlayedAt: DateTime.now(),
      );

      tx.set(ref, {
        ...updated.toMap(),
        'lastPlayedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
