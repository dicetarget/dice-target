// lib/features/rush/presentation/screens/rush_result_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:flutter/material.dart';

class RushResultScreen extends StatefulWidget {
  final RushDifficulty difficulty;
  final int score;
  final int previousPb;
  final int lastPuzzleTarget;
  final List<int> lastPuzzleDice;

  const RushResultScreen({
    super.key,
    required this.difficulty,
    required this.score,
    required this.previousPb,
    required this.lastPuzzleTarget,
    required this.lastPuzzleDice,
  });

  @override
  State<RushResultScreen> createState() => _RushResultScreenState();
}

class _RushResultScreenState extends State<RushResultScreen> {
  static const Color _green = Color(0xFF00E5A0);
  static const Color _greenLt = Color(0xFFD0FFF0);
  static const Color _cyan = Color(0xFF3FE8FF);

  bool _isNewPb = false;
  int _pb = 0;
  bool _saving = true;

  String? _lastPuzzleSolution;
  bool _solutionComputed = false;

  @override
  void initState() {
    super.initState();
    _saveAndLoad();
    _computeLastPuzzleSolution();
  }

  Future<void> _saveAndLoad() async {
    final storage = RushHighscoreStorage();
    final isNew = await storage.saveIfBetter(widget.difficulty, widget.score);
    final saved = await storage.load(widget.difficulty);
    await storage.incrementStats(widget.score);
    if (mounted) {
      setState(() {
        _isNewPb = isNew;
        _pb = saved;
        _saving = false;
      });
    }
  }

  void _computeLastPuzzleSolution() {
    if (widget.lastPuzzleDice.isEmpty) {
      setState(() => _solutionComputed = true);
      return;
    }
    final solver = SolverService();
    final result = solver.check(diceValues: widget.lastPuzzleDice, target: widget.lastPuzzleTarget);
    if (mounted) {
      setState(() {
        _lastPuzzleSolution = result.solvable ? result.fullExpression : null;
        _solutionComputed = true;
      });
    }
  }

  void _showSolutionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.cardBr),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          title: const Text(
            'Last Puzzle — Solution',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgBottom,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBr),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target: ${widget.lastPuzzleTarget}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD4AC0D),
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  _lastPuzzleSolution ?? 'No solution found.',
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Close',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _cyan),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // ── Score — zentral, dominant ─────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kleines Label
                    Text(
                      'Time\'s Up',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.3,
                        color: Colors.white.withValues(alpha: 0.35),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Score — größtes Element
                    Text(
                      '${widget.score}',
                      style: const TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -4,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.score == 1 ? 'puzzle solved' : 'puzzles solved',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // New PB Badge oder Best-Info
                    if (!_saving) ...[
                      if (_isNewPb)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _green.withValues(alpha: 0.45)),
                          ),
                          child: const Text(
                            '🏆  New Record!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _greenLt,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Best: $_pb',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // ── Last Puzzle Solution — optional, sehr sekundär ────────────
              if (_solutionComputed && widget.lastPuzzleDice.isNotEmpty) ...[
                GestureDetector(
                  onTap: _showSolutionDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Show last puzzle solution',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Play Again — primärer Button ──────────────────────────────
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_green.withValues(alpha: 0.45), _green.withValues(alpha: 0.22)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _green.withValues(alpha: 0.90), width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.22),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Play Again',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Main Menu — sekundär ──────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      'Main Menu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
