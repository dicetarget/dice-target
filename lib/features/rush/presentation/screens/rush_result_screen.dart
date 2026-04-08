// lib/features/rush/presentation/screens/rush_result_screen.dart

import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:dice/features/rush/presentation/screens/rush_screen.dart';
import 'package:flutter/material.dart';

class RushResultScreen extends StatefulWidget {
  final RushDifficulty difficulty;
  final int score;
  final int previousPb;

  const RushResultScreen({
    super.key,
    required this.difficulty,
    required this.score,
    required this.previousPb,
  });

  @override
  State<RushResultScreen> createState() => _RushResultScreenState();
}

class _RushResultScreenState extends State<RushResultScreen> {
  static const Color _green = Color(0xFF00E5A0);
  static const Color _greenLt = Color(0xFFD0FFF0);
  static const Color _bg = Color(0xFF0A0F1F);
  static const Color _card = Color(0xFF141A2E);

  bool _isNewPb = false;
  int _pb = 0;
  bool _saving = true;

  @override
  void initState() {
    super.initState();
    _saveAndLoad();
  }

  Future<void> _saveAndLoad() async {
    final storage = RushHighscoreStorage();
    final isNew = await storage.saveIfBetter(widget.difficulty, widget.score);
    final saved = await storage.load(widget.difficulty);
    if (mounted) {
      setState(() {
        _isNewPb = isNew;
        _pb = saved;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Header
              Center(
                child: Text(
                  "Time's Up",
                  style: TextStyle(
                    fontSize: 15,
                    letterSpacing: 0.4,
                    color: Colors.white.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // (F) Difficulty badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    '${widget.difficulty.label.toUpperCase()} · 90s',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Score card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isNewPb
                        ? _green.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.07),
                    width: _isNewPb ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.score}',
                      style: const TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -3,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.score == 1 ? 'puzzle solved' : 'puzzles solved',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isNewPb && !_saving) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _green.withValues(alpha: 0.45)),
                        ),
                        child: const Text(
                          '🏆  New Record!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _greenLt,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_saving)
                Center(
                  child: Text(
                    'Best (${widget.difficulty.label}): $_pb',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.30),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const Spacer(),
              // Play Again
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => RushScreen(difficulty: widget.difficulty, personalBest: _pb),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 19),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_green.withValues(alpha: 0.28), _green.withValues(alpha: 0.13)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: _green.withValues(alpha: 0.60), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.18),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Main Menu
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 19),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: const Center(
                    child: Text(
                      'Main Menu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white38,
                      ),
                    ),
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
}
