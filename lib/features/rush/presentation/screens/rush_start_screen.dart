// lib/features/rush/presentation/screens/rush_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
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

  RushDifficulty _selected = RushDifficulty.easy;
  final Map<RushDifficulty, int> _highscores = {};
  final RushHighscoreStorage _storage = RushHighscoreStorage();
  bool _starting = false;
  int _totalRuns = 0;
  int _totalPuzzles = 0;

  @override
  void initState() {
    super.initState();
    _loadHighscores();
    _loadStats();
  }

  Future<void> _loadHighscores() async {
    for (final d in RushDifficulty.values) {
      final score = await _storage.load(d);
      if (mounted) setState(() => _highscores[d] = score);
    }
  }

  Future<void> _loadStats() async {
    final stats = await _storage.loadStats();
    if (mounted) {
      setState(() {
        _totalRuns = stats.totalRuns;
        _totalPuzzles = stats.totalPuzzles;
      });
    }
  }

  Future<void> _startStandardRun() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await navigator.push(
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
    return Scaffold(
      backgroundColor: AppColors.bgTop,
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
              const SizedBox(height: 16),
              Expanded(child: _buildStandardContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStandardHeroCard(),
                const SizedBox(height: 12),
                _buildDifficultyCard(),
                const SizedBox(height: 12),
                _buildStatsCard(),
                const SizedBox(height: 12),
                _buildStandardFormatCard(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          label: _starting ? 'Starting...' : 'Start Speed Run',
          onTap: _starting ? null : _startStandardRun,
          green: _green,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStandardHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Speed Run',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _green,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '90s • Endless • No limits',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIFFICULTY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              color: Colors.white.withValues(alpha: 0.30),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: RushDifficulty.values.map((d) {
              final isSel = d == _selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel
                          ? _green.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel
                            ? _green.withValues(alpha: 0.40)
                            : Colors.white.withValues(alpha: 0.07),
                        width: isSel ? 1.0 : 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? Colors.white.withValues(alpha: 0.90)
                                : Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${d.targetMin}–${d.targetMax}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSel
                                ? _green.withValues(alpha: 0.50)
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          (_highscores[d] ?? 0) > 0 ? 'PB ${_highscores[d]}' : '—',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSel
                                ? _green.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatsCell(label: 'Total Runs', value: '$_totalRuns', green: _green),
          ),
          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.06)),
          Expanded(
            child: _StatsCell(label: 'Puzzles Solved', value: '$_totalPuzzles', green: _green),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardFormatCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RushFormatRow(icon: Icons.skip_next_rounded, text: '1 Skip per run', small: true),
          SizedBox(height: 8),
          _RushFormatRow(
            icon: Icons.lightbulb_outline_rounded,
            text: '1 Hint per run',
            small: true,
          ),
          SizedBox(height: 8),
          _RushFormatRow(icon: Icons.all_inclusive_rounded, text: 'No limits', small: true),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color green;
  const _ActionButton({required this.label, required this.onTap, required this.green});

  @override
  Widget build(BuildContext context) {
    final en = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: en
                ? [green.withValues(alpha: 0.45), green.withValues(alpha: 0.22)]
                : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: en ? green.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.10),
            width: 2.0,
          ),
          boxShadow: en
              ? [BoxShadow(color: green.withValues(alpha: 0.22), blurRadius: 12, spreadRadius: 0)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: en ? Colors.white : Colors.white30,
              letterSpacing: -0.3,
              shadows: en ? [Shadow(color: green.withValues(alpha: 0.35), blurRadius: 8)] : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _RushFormatRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool small;

  const _RushFormatRow({required this.icon, required this.text, this.small = false});

  @override
  Widget build(BuildContext context) {
    final iconColor = small ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF00E5A0);
    final textColor = small ? Colors.white.withValues(alpha: 0.28) : Colors.white;

    return Row(
      children: [
        Icon(icon, size: small ? 14 : 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: small ? 12 : 14,
              fontWeight: small ? FontWeight.w500 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsCell extends StatelessWidget {
  final String label;
  final String value;
  final Color green;

  const _StatsCell({required this.label, required this.value, required this.green});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.20),
          ),
        ),
      ],
    );
  }
}
