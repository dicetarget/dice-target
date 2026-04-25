import 'package:flutter/material.dart';
import 'package:dice/features/vs/domain/vs_player.dart';
import 'package:dice/features/vs/domain/vs_challenge.dart';
import 'package:dice/features/vs/domain/vs_challenge_model.dart';
import 'package:dice/features/vs/data/vs_player_storage.dart';
import 'package:dice/features/vs/data/vs_firestore_service.dart';
import 'package:dice/features/vs/presentation/screens/vs_friend_add_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_result_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_onboarding_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_start_screen.dart';
import 'package:dice/features/vs/presentation/widgets/vs_head_to_head_card.dart';

class VsHomeScreen extends StatefulWidget {
  const VsHomeScreen({super.key});

  @override
  State<VsHomeScreen> createState() => _VsHomeScreenState();
}

class _VsHomeScreenState extends State<VsHomeScreen> {
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _cyanLt = Color(0xFFE0FEFF);

  VsPlayer? _player;
  Map<String, String> _friends = {};
  List<VsChallengeModel> _challenges = [];
  Map<String, String> _pendingRequests = {};
  bool _loading = true;

  final _storage = VsPlayerStorage();
  final _firestore = VsFirestoreService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _player = await _storage.loadOrCreate();
    if (_player!.displayName.isEmpty) {
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VsOnboardingScreen()),
      );
      return;
    }
    await _firestore.savePlayer(_player!);
    _friends = await _firestore.loadFriends(_player!.id);
    _pendingRequests = await _firestore.loadPendingRequests(_player!.id);
    _challenges = await _firestore.loadChallenges(_player!.id);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF020408),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _cyan))
              : RefreshIndicator(
                  color: _cyan,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                              color: Colors.white.withValues(alpha: 0.60),
                              enableFeedback: false,
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'VS',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.0,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(
                            'Play against a friend',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildPlayerCard(),
                        const SizedBox(height: 24),
                        if (_pendingRequests.isNotEmpty) ...[
                          _buildSectionHeader('Friend Requests'),
                          const SizedBox(height: 12),
                          _buildPendingRequestsList(),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionHeader(
                          'Friends',
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add, size: 22, color: _cyan),
                            enableFeedback: false,
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VsFriendAddScreen(
                                myId: _player!.id,
                                myDisplayName: _player!.displayName,
                              ),
                                ),
                              );
                              _refresh();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFriendsList(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Open Challenges'),
                        const SizedBox(height: 12),
                        _buildOpenChallengesList(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('History'),
                        const SizedBox(height: 12),
                        _buildCompletedChallengesList(),
                        const SizedBox(height: 32),
                        if (_friends.isEmpty) ...[
                          GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VsFriendAddScreen(
                                    myId: _player!.id,
                                    myDisplayName: _player!.displayName,
                                  ),
                                ),
                              );
                              _refresh();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _cyan.withValues(alpha: 0.18),
                                    _cyan.withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _cyan.withValues(alpha: 0.90),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _cyan.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Add Friend',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: _cyan,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Name',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _player!.displayName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _cyanLt,
                    letterSpacing: 1.0,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No friends yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add friends to start playing',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.30),
            ),
          ),
        ],
      );
    }
    return Column(
      children: _friends.entries.map((e) => _buildFriendChip(e.key, e.value)).toList(),
    );
  }

  void _showFriendProfile(String friendId, String friendName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              friendName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            VsHeadToHeadCard(
              myId: _player!.id,
              friendId: friendId,
              myName: _player!.displayName,
              friendName: friendName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeButton({
    required String label,
    required String friendId,
    required String friendName,
    required String vsMode,
  }) {
    return GestureDetector(
      onTap: () async {
        final alreadyOpen = await _firestore.hasOpenChallenge(
          _player!.id,
          friendId,
          vsMode,
        );
        if (!mounted) return;
        if (alreadyOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already have an open challenge with this friend.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        final seed = DateTime.now().millisecondsSinceEpoch;
        final challenge = VsChallengeModel.create(
          challengerId: _player!.id,
          opponentId: friendId,
          challengerName: _player!.displayName,
          opponentName: friendName,
          seed: seed,
          vsMode: vsMode,
        );
        await _firestore.createChallenge(challenge);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vsMode == 'rush' ? 'Rush' : 'Speed Run'} challenge sent to $friendName!'),
            duration: const Duration(seconds: 2),
          ),
        );
        _refresh();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cyan.withValues(alpha: 0.50), width: 1.0),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _cyan,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendChip(String friendId, String friendName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showFriendProfile(friendId, friendName),
              child: Text(
                friendName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          _buildChallengeButton(
            label: '⚡ 90s',
            friendId: friendId,
            friendName: friendName,
            vsMode: 'rush',
          ),
          const SizedBox(width: 8),
          _buildChallengeButton(
            label: '🏁 3 Puzzles',
            friendId: friendId,
            friendName: friendName,
            vsMode: 'speedrun',
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeFriend(friendId, friendName),
            child: Icon(
              Icons.person_remove_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenChallengesList() {
    final open = _challenges
        .where((c) => !c.isCompleted)
        .toList();
    if (open.isEmpty) {
      return Text(
        'No open challenges.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      );
    }
    return Column(
      children: open.map((c) => _buildChallengeCard(c)).toList(),
    );
  }

  Widget _buildCompletedChallengesList() {
    final completed = _challenges
        .where((c) => c.isCompleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (completed.isEmpty) {
      return Text(
        'No completed challenges yet.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      );
    }
    return Column(
      children: completed.map((c) => _buildChallengeCard(c)).toList(),
    );
  }

  Widget _buildChallengeCard(VsChallengeModel c) {
    final iAmChallenger = c.challengerId == _player!.id;
    final opponentName = iAmChallenger ? c.opponentName : c.challengerName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.isCompleted
              ? Colors.white.withValues(alpha: 0.12)
              : _cyan.withValues(alpha: 0.30),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${opponentName.isNotEmpty ? opponentName : (iAmChallenger ? c.opponentId : c.challengerId)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildChallengeSubtitle(c, iAmChallenger),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.isCompleted
                        ? Colors.white.withValues(alpha: 0.35)
                        : _cyan.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
          _buildChallengeAction(c, iAmChallenger),
        ],
      ),
    );
  }

  String _buildChallengeSubtitle(VsChallengeModel c, bool iAmChallenger) {
    final day = c.createdAt.day.toString().padLeft(2, '0');
    final month = c.createdAt.month.toString().padLeft(2, '0');
    final hour = c.createdAt.hour.toString().padLeft(2, '0');
    final minute = c.createdAt.minute.toString().padLeft(2, '0');
    final dateStr = '$day.$month  $hour:$minute';
    final modeStr = c.vsMode == 'speedrun' ? '🏁 3 Puzzles' : '⚡ 90s Rush';
    if (c.isCompleted) {
      final myPuzzles = iAmChallenger ? c.challengerPuzzles : (c.opponentPuzzles ?? 0);
      final theirPuzzles = iAmChallenger ? (c.opponentPuzzles ?? 0) : c.challengerPuzzles;
      return '$modeStr  ·  $myPuzzles : $theirPuzzles  ·  $dateStr';
    }
    return '$modeStr  ·  $dateStr';
  }

  Widget _buildChallengeAction(VsChallengeModel c, bool iAmChallenger) {
    // Completed → View Result
    if (c.isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _openResult(c, iAmChallenger),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: Text(
                'View Result',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteChallenge(c),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.30),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      );
    }

    // Invited → Challenger wartet, Opponent kann Accept/Decline
    if (c.isInvited) {
      if (iAmChallenger) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waiting...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _deleteChallenge(c),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.30),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ),
          ],
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                await _firestore.declineChallenge(c.id);
                if (!mounted) return;
                setState(() => _challenges.removeWhere((ch) => ch.id == c.id));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Decline',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await _firestore.acceptChallenge(c.id);
                if (!mounted) return;
                _refresh();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _cyan.withValues(alpha: 0.50),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _cyan,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    // Accepted → beide können spielen wenn noch nicht gespielt
    if (c.isAccepted || c.isPending) {
      final iHavePlayed = iAmChallenger ? c.challengerPlayed : c.opponentPlayed;
      if (!iHavePlayed) {
        return GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VsStartScreen(
                  mode: iAmChallenger
                      ? VsStartMode.challenger
                      : VsStartMode.opponent,
                  friendId: iAmChallenger ? c.opponentId : c.challengerId,
                  myId: _player!.id,
                  myDisplayName: _player!.displayName,
                  friendName: iAmChallenger ? c.opponentName : c.challengerName,
                  incomingChallenge: c,
                  vsMode: c.vsMode,
                ),
              ),
            );
            _refresh();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _cyan.withValues(alpha: 0.50),
                width: 1.0,
              ),
            ),
            child: const Text(
              'Play',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _cyan,
              ),
            ),
          ),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Waiting...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.30),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteChallenge(c),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.30),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _acceptRequest(String friendId) async {
    await _firestore.acceptFriend(_player!.id, friendId);
    await _load();
  }

  Future<void> _declineRequest(String friendId) async {
    await _firestore.declineFriend(_player!.id, friendId);
    if (!mounted) return;
    setState(() => _pendingRequests.remove(friendId));
  }

  Future<void> _removeFriend(String friendId, String friendName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Friend?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Remove $friendName from your friends list?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.60),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _firestore.removeFriend(_player!.id, friendId);
    if (!mounted) return;
    setState(() => _friends.remove(friendId));
  }


  Future<void> _deleteChallenge(VsChallengeModel c) async {
    await _firestore.deleteChallenge(c.id, _player!.id);
    if (!mounted) return;
    setState(() => _challenges.removeWhere((ch) => ch.id == c.id));
  }

  void _openResult(VsChallengeModel c, bool iAmChallenger) {
    final challenger = VsChallenge(
      seed: c.seed,
      puzzlesSolved: c.challengerPuzzles,
      timeUsedMs: c.challengerTimeMs,
      movesUsed: c.challengerMoves,
      createdAt: c.createdAt,
    );
    final opponent = VsChallenge(
      seed: c.seed,
      puzzlesSolved: c.opponentPuzzles!,
      timeUsedMs: c.opponentTimeMs!,
      movesUsed: c.opponentMoves!,
      createdAt: c.createdAt,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VsResultScreen(
          challenger: challenger,
          opponent: opponent,
          isChallenger: iAmChallenger,
          vsMode: c.vsMode,
          friendName: iAmChallenger ? c.opponentName : c.challengerName,
        ),
      ),
    );
  }

  Widget _buildPendingRequestsList() {
    return Column(
      children: _pendingRequests.entries
          .map((e) => _buildPendingRequestChip(e.key, e.value))
          .toList(),
    );
  }

  Widget _buildPendingRequestChip(String friendId, String friendName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _cyan.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'wants to be friends',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _declineRequest(friendId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Text(
                'Decline',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _acceptRequest(friendId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _cyan.withValues(alpha: 0.50),
                  width: 1.0,
                ),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _cyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }
}
