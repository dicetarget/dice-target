import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/vs/domain/vs_challenge.dart';
import 'package:dice/features/vs/domain/vs_winner_logic.dart';
import 'package:dice/features/vs/presentation/screens/vs_home_screen.dart';
import 'package:flutter/material.dart';

class VsResultScreen extends StatefulWidget {
  final VsChallenge challenger;
  final VsChallenge opponent;
  final bool isChallenger;
  final bool pendingOpponent;
  final String vsMode;
  final String? friendName;

  const VsResultScreen({
    super.key,
    required this.challenger,
    required this.opponent,
    required this.isChallenger,
    this.pendingOpponent = false,
    this.vsMode = 'rush',
    this.friendName,
  });

  @override
  State<VsResultScreen> createState() => _VsResultScreenState();
}

class _VsResultScreenState extends State<VsResultScreen> {
  late VsWinner _winner;
  late bool _iWon;
  late bool _isDraw;

  @override
  void initState() {
    super.initState();
    if (widget.pendingOpponent) {
      _winner = VsWinner.draw;
      _iWon = false;
      _isDraw = false;
    } else {
      try {
        _winner = VsWinnerLogic.determine(
          challengerPuzzles: widget.challenger.puzzlesSolved,
          challengerTimeMs: widget.challenger.timeUsedMs,
          challengerMoves: widget.challenger.movesUsed,
          opponentPuzzles: widget.opponent.puzzlesSolved,
          opponentTimeMs: widget.opponent.timeUsedMs,
          opponentMoves: widget.opponent.movesUsed,
          vsMode: widget.vsMode,
          totalPuzzles: widget.vsMode == 'speedrun_advanced' ? 5 : 3,
        );
        _iWon =
            (widget.isChallenger && _winner == VsWinner.challenger) ||
            (!widget.isChallenger && _winner == VsWinner.opponent);
        _isDraw = _winner == VsWinner.draw;
      } catch (e) {
        debugPrint('VsWinnerLogic error: $e');
        _winner = VsWinner.draw;
        _iWon = false;
        _isDraw = true;
      }
    }
  }

  String get _opponentLabel => widget.friendName ?? 'Opponent';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildComparisonCard(),
              const SizedBox(height: 24),
              if (widget.pendingOpponent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: const Text(
                    'Waiting for opponent to play...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              const Spacer(),
              TactileButton(
                variant: TactileButtonVariant.primary,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                borderRadius: BorderRadius.circular(16),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const VsHomeScreen()),
                  (route) => route.isFirst,
                ),
                child: const Text(
                  'Back to VS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = widget.pendingOpponent
        ? 'Waiting...'
        : _isDraw
        ? 'Draw!'
        : (_iWon ? 'You won!' : 'You lost!');
    return Column(
      children: [
        const Text(
          'VS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: _iWon ? AppColors.gold : AppColors.ink,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    final myChallenge = widget.isChallenger ? widget.challenger : widget.opponent;
    final theirChallenge = widget.isChallenger ? widget.opponent : widget.challenger;
    final myIsWinner = _iWon;
    final theirIsWinner = !_iWon && !_isDraw;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const SizedBox(height: 12),
          _buildTableRow(label: 'You', challenge: myChallenge, isWinner: myIsWinner),
          const SizedBox(height: 8),
          if (widget.pendingOpponent)
            _buildPendingRow()
          else
            _buildTableRow(
              label: _opponentLabel,
              challenge: theirChallenge,
              isWinner: theirIsWinner,
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    if ((widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced')) {
      return Row(
        children: [const SizedBox(width: 80), _buildHeaderCell('Time'), _buildHeaderCell('Moves')],
      );
    }
    return Row(
      children: [const SizedBox(width: 80), _buildHeaderCell('Puzzles'), _buildHeaderCell('Moves')],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.inkMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatTime(int ms) {
    final totalSeconds = ms / 1000;
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    if (minutes == 0) return '${totalSeconds.toStringAsFixed(1)}s';
    return '${minutes}m ${seconds.toStringAsFixed(0).padLeft(2, '0')}s';
  }

  Widget _buildTableRow({
    required String label,
    required VsChallenge challenge,
    required bool isWinner,
  }) {
    final timeStr = _formatTime(challenge.timeUsedMs);

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Row(
            children: [
              if (isWinner) const Text('👑', style: TextStyle(fontSize: 14)),
              if (isWinner) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isWinner ? AppColors.gold : AppColors.inkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if ((widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced')) ...[
          _buildValueCell(timeStr, isWinner),
          _buildValueCell('${challenge.movesUsed}', isWinner),
        ] else ...[
          _buildValueCell('${challenge.puzzlesSolved}', isWinner),
          _buildValueCell('${challenge.movesUsed}', isWinner),
        ],
      ],
    );
  }

  Widget _buildPendingRow() {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            _opponentLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Waiting...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueCell(String text, bool isWinner) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isWinner ? AppColors.gold : AppColors.ink,
        ),
      ),
    );
  }
}
