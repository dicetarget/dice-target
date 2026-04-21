// lib/features/game/presentation/screens/free_play_start_screen.dart

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/game/presentation/screens/practice_screen.dart';
import 'package:flutter/material.dart';

enum _Tab { free, training }

class FreePlayStartScreen extends StatefulWidget {
  const FreePlayStartScreen({super.key});

  @override
  State<FreePlayStartScreen> createState() => _FreePlayStartScreenState();
}

class _FreePlayStartScreenState extends State<FreePlayStartScreen> {
  // White/silver — no color-meaning conflict with Daily (gold) or Rush (green)
  static const Color _neutral = Color(0xFFFFB300);

  _Tab _tab = _Tab.free;
  PracticeDifficulty _selectedDifficulty = PracticeDifficulty.easy;

  Future<void> _startFree() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PracticeScreen(initialTrainingMode: false)));
    if (mounted) setState(() {});
  }

  Future<void> _startTraining() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PracticeScreen(initialTrainingMode: true, initialDifficulty: _selectedDifficulty),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.bgTop,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const Expanded(
                    child: Text(
                      'Free Play',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                    enableFeedback: false,
                    onPressed: () async {
                      await sfx.toggle();
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Play without limits',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTabSwitcher(),
              const SizedBox(height: 20),
              Expanded(child: _tab == _Tab.free ? _buildFreeContent() : _buildTrainingContent()),
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
            label: 'Free',
            active: _tab == _Tab.free,
            neutral: _neutral,
            onTap: () => setState(() => _tab = _Tab.free),
          ),
          _TabBtn(
            label: 'Training',
            active: _tab == _Tab.training,
            neutral: _neutral,
            onTap: () => setState(() => _tab = _Tab.training),
          ),
        ],
      ),
    );
  }

  // ── Free ───────────────────────────────────────────────────────────────────

  Widget _buildFreeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroCard(
          title: 'Free',
          subtitle: 'Unlimited puzzles · No pressure · Your pace',
        ),
        const SizedBox(height: 12),
        _buildFormatCard([
          _FreeFormatRow(
            icon: Icons.all_inclusive_rounded,
            text: 'Unlimited puzzles',
            neutral: _neutral,
          ),
          const SizedBox(height: 10),
          _FreeFormatRow(icon: Icons.timer_off_outlined, text: 'No timer', neutral: _neutral),
          const SizedBox(height: 10),
          _FreeFormatRow(
            icon: Icons.lightbulb_outline_rounded,
            text: 'Show Solution available',
            neutral: _neutral,
          ),
        ]),
        const Spacer(),
        const SizedBox(height: 16),
        _ActionButton(label: 'Start Free Play', onTap: _startFree, neutral: _neutral),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Training ───────────────────────────────────────────────────────────────

  Widget _buildTrainingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroCard(
          title: 'Training',
          subtitle: 'Focus on a difficulty · Sharpen your skills',
        ),
        const SizedBox(height: 12),
        _buildDifficultyCard(),
        const SizedBox(height: 12),
        _buildFormatCard([
          _FreeFormatRow(
            icon: Icons.tune_rounded,
            text: 'Focused target range per difficulty',
            neutral: _neutral,
          ),
          const SizedBox(height: 10),
          _FreeFormatRow(icon: Icons.timer_off_outlined, text: 'No timer', neutral: _neutral),
          const SizedBox(height: 10),
          _FreeFormatRow(
            icon: Icons.lightbulb_outline_rounded,
            text: 'Show Solution available',
            neutral: _neutral,
          ),
        ]),
        const Spacer(),
        const SizedBox(height: 16),
        _ActionButton(label: 'Start Training', onTap: _startTraining, neutral: _neutral),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Shared cards ───────────────────────────────────────────────────────────

  Widget _buildHeroCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)), // neutral, no glow
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white, // white, not amber
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
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
    final difficulties = [
      (PracticeDifficulty.easy, 'Easy', '10–40'),
      (PracticeDifficulty.medium, 'Medium', '30–70'),
      (PracticeDifficulty.hard, 'Hard', '50–100'),
      (PracticeDifficulty.expert, 'Expert', '80–120'),
    ];

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
            children: difficulties.map((entry) {
              final (difficulty, label, range) = entry;
              final isSel = difficulty == _selectedDifficulty;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDifficulty = difficulty),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel
                          ? _neutral.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel
                            ? _neutral.withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.10),
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white : Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          range,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSel ? _neutral.withValues(alpha: 0.75) : Colors.white24,
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

  Widget _buildFormatCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color neutral;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.active,
    required this.neutral,
    required this.onTap,
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
            color: active ? neutral.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? neutral.withValues(alpha: 0.40) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color neutral;
  const _ActionButton({required this.label, required this.onTap, required this.neutral});

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
                ? [neutral.withValues(alpha: 0.18), neutral.withValues(alpha: 0.08)]
                : [const Color(0x0DFFFFFF), const Color(0x05FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: en ? neutral.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.10),
            width: 1.5,
          ),
          boxShadow: en
              ? [BoxShadow(color: neutral.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 1)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: en ? neutral : Colors.white30,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeFormatRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color neutral;

  const _FreeFormatRow({required this.icon, required this.text, required this.neutral});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: neutral.withValues(alpha: 0.80)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
