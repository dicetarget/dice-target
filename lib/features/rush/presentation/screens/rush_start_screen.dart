// lib/features/rush/presentation/screens/rush_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/rush/data/rush_daily_storage.dart';
import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:dice/features/rush/presentation/screens/rush_daily_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_screen.dart';
import 'package:flutter/material.dart';

enum _Tab { standard, daily }

class RushStartScreen extends StatefulWidget {
  const RushStartScreen({super.key});

  @override
  State<RushStartScreen> createState() => _RushStartScreenState();
}

class _RushStartScreenState extends State<RushStartScreen> {
  // Speed Run green — nicht in AppColors, bleibt lokal
  static const Color _green = Color(0xFF00E5A0);
  static const Color _greenLt = Color(0xFFD0FFF0);

  _Tab _tab = _Tab.standard;

  // Standard
  RushDifficulty _selected = RushDifficulty.easy;
  final Map<RushDifficulty, int> _highscores = {};
  final RushHighscoreStorage _storage = RushHighscoreStorage();
  bool _starting = false;

  // Daily
  final RushDailyStorage _dailyStorage = RushDailyStorage();
  RushDailyState? _dailyState;
  bool _loadingDaily = false;
  bool _startingDaily = false;

  @override
  void initState() {
    super.initState();
    _loadHighscores();
    _loadDailyState();
  }

  Future<void> _loadHighscores() async {
    for (final d in RushDifficulty.values) {
      final score = await _storage.load(d);
      if (mounted) setState(() => _highscores[d] = score);
    }
  }

  Future<void> _startStandardRun() async {
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

  Future<void> _loadDailyState() async {
    setState(() => _loadingDaily = true);
    final state = await _dailyStorage.load();
    if (mounted) {
      setState(() {
        _dailyState = state;
        _loadingDaily = false;
      });
    }
  }

  Future<void> _startDailyRun() async {
    if (_startingDaily) return;
    final state = _dailyState;
    if (state == null || state.isCompleted) return;

    setState(() => _startingDaily = true);
    try {
      if (!mounted) return;
      if (state.canStartRun1) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RushDailyScreen(runNumber: 1)));
      } else if (state.canStartRun2) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RushDailyScreen(runNumber: 2, run1Score: state.run1)),
        );
      }
      await _loadDailyState();
    } finally {
      if (mounted) setState(() => _startingDaily = false);
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
              _buildTabSwitcher(),
              const SizedBox(height: 20),
              Expanded(
                child: _tab == _Tab.standard ? _buildStandardContent() : _buildDailyContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _TabBtn(
            label: 'Standard',
            active: _tab == _Tab.standard,
            green: _green,
            onTap: () => setState(() => _tab = _Tab.standard),
          ),
          _TabBtn(
            label: 'Daily',
            active: _tab == _Tab.daily,
            green: _green,
            showDot: _dailyState != null && !_dailyState!.isCompleted,
            onTap: () {
              setState(() => _tab = _Tab.daily);
              _loadDailyState();
            },
          ),
        ],
      ),
    );
  }

  // ── Standard ───────────────────────────────────────────────────────────────

  Widget _buildStandardContent() {
    final pb = _highscores[_selected] ?? 0;
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
                _buildPbCard(pb),
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
            'Standard',
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
            '90s · Endless puzzles · Auto-advance',
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
                          ? _green.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel
                            ? _green.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.10),
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSel ? _greenLt : Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${d.targetMin}–${d.targetMax}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSel ? _green.withValues(alpha: 0.65) : Colors.white24,
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

  Widget _buildPbCard(int pb) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pb > 0 ? _green.withValues(alpha: 0.30) : AppColors.cardBr),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 20,
            color: pb > 0 ? _green.withValues(alpha: 0.80) : Colors.white24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.centerLeft,
                child: pb > 0
                    ? Text(
                        'Personal Best: $pb',
                        key: ValueKey('pb_$pb'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _green.withValues(alpha: 0.85),
                        ),
                      )
                    : Text(
                        'No record yet',
                        key: const ValueKey('pb_none'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardFormatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBr),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RushFormatRow(icon: Icons.skip_next_rounded, text: 'Skip anytime · no penalty'),
          SizedBox(height: 10),
          _RushFormatRow(icon: Icons.lightbulb_outline_rounded, text: 'No hints', dimmed: true),
          SizedBox(height: 10),
          _RushFormatRow(icon: Icons.flag_outlined, text: 'No give up', dimmed: true),
        ],
      ),
    );
  }

  // ── Daily ──────────────────────────────────────────────────────────────────

  Widget _buildDailyContent() {
    if (_loadingDaily) {
      return const Center(child: CircularProgressIndicator(color: Colors.white30, strokeWidth: 2));
    }
    final state = _dailyState;
    if (state == null) {
      return Center(
        child: Text(
          'Could not load daily.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDailyHeroCard(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DailyRunCard(label: 'Run 1', score: state.run1, green: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyRunCard(
                label: 'Run 2',
                score: state.run2,
                locked: !state.run1Played,
                green: _green,
              ),
            ),
          ],
        ),
        if (state.allTimeBest > 0) ...[
          const SizedBox(height: 12),
          _buildAllTimeBestCard(state.allTimeBest),
        ],
        const SizedBox(height: 12),
        _buildDailyFormatCard(),
        const Spacer(),
        if (state.isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.cardBr),
            ),
            child: Center(
              child: Text(
                'Completed today ✓',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          )
        else
          _ActionButton(
            label: _startingDaily
                ? 'Starting...'
                : (state.canStartRun1 ? 'Start Run 1' : 'Start Run 2'),
            onTap: _startingDaily ? null : _startDailyRun,
            green: _green,
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDailyHeroCard() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dateText =
        '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily',
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
            dateText,
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

  Widget _buildDailyFormatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBr),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RushFormatRow(icon: Icons.repeat_rounded, text: '2 runs per day'),
          SizedBox(height: 10),
          _RushFormatRow(icon: Icons.timer_outlined, text: '2 minutes per run'),
          SizedBox(height: 10),
          _RushFormatRow(icon: Icons.sync_rounded, text: 'Same puzzles both runs'),
          SizedBox(height: 10),
          _RushFormatRow(icon: Icons.skip_next_rounded, text: 'No skip', dimmed: true),
        ],
      ),
    );
  }

  Widget _buildAllTimeBestCard(int best) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, size: 20, color: _green.withValues(alpha: 0.80)),
          const SizedBox(width: 10),
          Text(
            'All-time best: $best',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _green.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color green;
  final VoidCallback onTap;
  final bool showDot;
  const _TabBtn({
    required this.label,
    required this.active,
    required this.green,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? green.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? green.withValues(alpha: 0.55)
                  : showDot
                  ? green.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : Colors.white38,
                  ),
                ),
              ),
              if (showDot)
                Positioned(
                  top: -3,
                  right: 12,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: green.withValues(alpha: 0.70), blurRadius: 6)],
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: en
                ? [green.withValues(alpha: 0.28), green.withValues(alpha: 0.13)]
                : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: en ? green.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.10),
            width: 1.5,
          ),
          boxShadow: en
              ? [BoxShadow(color: green.withValues(alpha: 0.22), blurRadius: 20, spreadRadius: 1)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: en ? Colors.white : Colors.white30,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyRunCard extends StatelessWidget {
  final String label;
  final int score;
  final bool locked;
  final Color green;
  const _DailyRunCard({
    required this.label,
    required this.score,
    this.locked = false,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    final played = score >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: played ? green.withValues(alpha: 0.40) : AppColors.cardBr),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.40),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (locked)
            Icon(Icons.lock_outline_rounded, color: Colors.white.withValues(alpha: 0.20), size: 22)
          else if (played)
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
                height: 1.0,
              ),
            )
          else
            Text(
              '—',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.25),
                height: 1.0,
              ),
            ),
        ],
      ),
    );
  }
}

class _RushFormatRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dimmed;

  const _RushFormatRow({required this.icon, required this.text, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: dimmed ? AppColors.muted : const Color(0xFF00E5A0)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dimmed ? AppColors.muted : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
