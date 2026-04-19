import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dice/features/vs/domain/vs_player.dart';
import 'package:dice/features/vs/domain/vs_challenge.dart';
import 'package:dice/features/vs/domain/vs_challenge_model.dart';
import 'package:dice/features/vs/data/vs_player_storage.dart';
import 'package:dice/features/vs/data/vs_firestore_service.dart';
import 'package:dice/features/vs/presentation/screens/vs_friend_add_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_result_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_start_screen.dart';

class VsHomeScreen extends StatefulWidget {
  const VsHomeScreen({super.key});

  @override
  State<VsHomeScreen> createState() => _VsHomeScreenState();
}

class _VsHomeScreenState extends State<VsHomeScreen> {
  static const Color _orange = Color(0xFFFF6B00);
  static const Color _orangeLt = Color(0xFFFFE0CC);

  VsPlayer? _player;
  List<String> _friends = [];
  List<VsChallengeModel> _challenges = [];
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
    await _firestore.savePlayer(_player!);
    _friends = await _firestore.loadFriends(_player!.id);
    _challenges = await _firestore.loadChallenges(_player!.id);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white.withValues(alpha: 0.70),
          enableFeedback: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'VS Mode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
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
              ? const Center(child: CircularProgressIndicator(color: _orange))
              : RefreshIndicator(
                  color: _orange,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildPlayerCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          'Friends',
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add, size: 22, color: _orange),
                            enableFeedback: false,
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VsFriendAddScreen(myId: _player!.id),
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
                        _buildChallengesList(),
                        const SizedBox(height: 32),
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
        border: Border.all(color: _orange.withValues(alpha: 0.40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.12),
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
                  'Your ID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _player!.id,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _orangeLt,
                    letterSpacing: 1.0,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 22),
            color: _orange.withValues(alpha: 0.70),
            enableFeedback: false,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _player!.id));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID copied!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Text(
        'No friends yet. Add a friend to challenge them.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
          height: 1.5,
        ),
      );
    }
    return Column(
      children: _friends.map((friend) => _buildFriendChip(friend)).toList(),
    );
  }

  Widget _buildFriendChip(String friendId) {
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
            child: Text(
              friendId,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VsStartScreen(
                  mode: VsStartMode.challenger,
                  friendId: friendId,
                  myId: _player!.id,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _orange.withValues(alpha: 0.50), width: 1.0),
              ),
              child: const Text(
                'Challenge',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesList() {
    if (_challenges.isEmpty) {
      return Text(
        'No open challenges.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      );
    }
    return Column(
      children: _challenges.map((c) => _buildChallengeCard(c)).toList(),
    );
  }

  Widget _buildChallengeCard(VsChallengeModel c) {
    final iAmChallenger = c.challengerId == _player!.id;
    final opponentId = iAmChallenger ? c.opponentId : c.challengerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.isCompleted
              ? Colors.white.withValues(alpha: 0.12)
              : _orange.withValues(alpha: 0.30),
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
                  'vs $opponentId',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.isCompleted
                        ? Colors.white.withValues(alpha: 0.35)
                        : _orange.withValues(alpha: 0.70),
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

  Widget _buildChallengeAction(VsChallengeModel c, bool iAmChallenger) {
    if (c.isCompleted) {
      return GestureDetector(
        onTap: () => _openResult(c, iAmChallenger),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.5),
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
      );
    }

    if (!iAmChallenger) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VsStartScreen(
              mode: VsStartMode.opponent,
              friendId: c.challengerId,
              myId: _player!.id,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _orange.withValues(alpha: 0.50), width: 1.0),
          ),
          child: const Text(
            'Play',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _orange,
            ),
          ),
        ),
      );
    }

    return Text(
      'Waiting...',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.30),
      ),
    );
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
        ),
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
