// lib/features/rush/presentation/screens/rush_start_screen.dart

import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:dice/features/rush/presentation/screens/rush_screen.dart';
import 'package:flutter/material.dart';

class RushStartScreen extends StatefulWidget {
  const RushStartScreen({super.key});

  @override
  State<RushStartScreen> createState() => _RushStartScreenState();
}

class _RushStartScreenState extends State<RushStartScreen> {
  static const Color _green = Color(0xFF00E5A0);
  static const Color _greenLt = Color(0xFFD0FFF0);
  static const Color _bg = Color(0xFF0A0F1F);

  RushDifficulty _selected = RushDifficulty.easy;
  final Map<RushDifficulty, int> _highscores = {};
  final RushHighscoreStorage _storage = RushHighscoreStorage();
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _loadHighscores();
  }

  Future<void> _loadHighscores() async {
    for (final d in RushDifficulty.values) {
      final score = await _storage.load(d);
      if (mounted) setState(() => _highscores[d] = score);
    }
  }

  Future<void> _startRun() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              RushScreen(difficulty: _selected, personalBest: _highscores[_selected] ?? 0),
        ),
      );
      await _loadHighscores();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pb = _highscores[_selected] ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Speed Run',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              // Beschreibung
              Center(
                child: Text(
                  '90 Sekunden · Endlos-Puzzles · Auto-Weiter',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.40),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Label
              Text(
                'SCHWIERIGKEIT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.30),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              // Difficulty-Auswahl
              Row(
                children: RushDifficulty.values.map((d) {
                  final isSelected = d == _selected;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _green.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _green.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.10),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              d.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? _greenLt : Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${d.targetMin}–${d.targetMax}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? _green.withValues(alpha: 0.65) : Colors.white24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),
              // PB-Anzeige
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: pb > 0
                      ? Text(
                          'Persönlicher Rekord: $pb',
                          key: ValueKey('pb_$pb'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _green.withValues(alpha: 0.75),
                          ),
                        )
                      : Text(
                          'Noch kein Rekord',
                          key: const ValueKey('pb_none'),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.25),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const Spacer(),
              // Start-Button
              GestureDetector(
                onTap: _starting ? null : _startRun,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_green.withValues(alpha: 0.28), _green.withValues(alpha: 0.13)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _green.withValues(alpha: 0.65), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.22),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        _starting ? 'Starte...' : 'Speed Run starten',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
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
