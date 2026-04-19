import 'package:flutter/material.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/vs/domain/vs_challenge.dart';
import 'package:dice/features/vs/domain/vs_winner_logic.dart';

class VsResultScreen extends StatefulWidget {
  final VsChallenge challenger;
  final VsChallenge opponent;
  final bool isChallenger;

  const VsResultScreen({
    super.key,
    required this.challenger,
    required this.opponent,
    required this.isChallenger,
  });

  @override
  State<VsResultScreen> createState() => _VsResultScreenState();
}

class _VsResultScreenState extends State<VsResultScreen> {
  static const Color _orange = Color(0xFFFF6B00);

  late VsWinner _winner;
  late bool _iWon;
  late bool _isDraw;

  @override
  void initState() {
    super.initState();
    _winner = VsWinnerLogic.determine(
      challengerPuzzles: widget.challenger.puzzlesSolved,
      challengerTimeMs: widget.challenger.timeUsedMs,
      challengerMoves: widget.challenger.movesUsed,
      opponentPuzzles: widget.opponent.puzzlesSolved,
      opponentTimeMs: widget.opponent.timeUsedMs,
      opponentMoves: widget.opponent.movesUsed,
    );
    _iWon = (widget.isChallenger && _winner == VsWinner.challenger) ||
        (!widget.isChallenger && _winner == VsWinner.opponent);
    _isDraw = _winner == VsWinner.draw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildComparisonCard(),
                  const Spacer(),
                  _buildHomeButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = _isDraw ? 'Draw!' : (_iWon ? 'You won!' : 'They won!');
    return Column(
      children: [
        Text(
          'VS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _orange.withValues(alpha: 0.70),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    final myChallenge =
        widget.isChallenger ? widget.challenger : widget.opponent;
    final theirChallenge =
        widget.isChallenger ? widget.opponent : widget.challenger;
    final myIsWinner = _iWon;
    final theirIsWinner = !_iWon && !_isDraw;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _orange.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.10),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const SizedBox(height: 12),
          _buildTableRow(
            label: 'You',
            challenge: myChallenge,
            isWinner: myIsWinner,
          ),
          const SizedBox(height: 8),
          _buildTableRow(
            label: 'Opponent',
            challenge: theirChallenge,
            isWinner: theirIsWinner,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        const SizedBox(width: 90),
        _buildHeaderCell('Puzzles'),
        _buildHeaderCell('Time'),
        _buildHeaderCell('Moves'),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.35),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String label,
    required VsChallenge challenge,
    required bool isWinner,
  }) {
    final timeStr =
        '${(challenge.timeUsedMs / 1000).toStringAsFixed(1)}s';

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Row(
            children: [
              if (isWinner)
                const Text('👑', style: TextStyle(fontSize: 14)),
              if (isWinner) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isWinner
                        ? _orange
                        : Colors.white.withValues(alpha: 0.65),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _buildValueCell('${challenge.puzzlesSolved}', isWinner),
        _buildValueCell(timeStr, isWinner),
        _buildValueCell('${challenge.movesUsed}', isWinner),
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
          color: isWinner ? _orange : Colors.white.withValues(alpha: 0.80),
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            'Home',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
