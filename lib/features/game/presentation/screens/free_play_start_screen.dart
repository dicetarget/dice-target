// lib/features/game/presentation/screens/free_play_start_screen.dart

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/features/game/presentation/screens/practice_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_start_screen.dart';
import 'package:flutter/material.dart';

class FreePlayStartScreen extends StatefulWidget {
  const FreePlayStartScreen({super.key});

  @override
  State<FreePlayStartScreen> createState() => _FreePlayStartScreenState();
}

class _FreePlayStartScreenState extends State<FreePlayStartScreen> {
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _amber = Color(0xFFFFB300);

  void _openClassic() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PracticeScreen(initialTrainingMode: false),
      ),
    );
  }

  void _openRush() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RushStartScreen()),
    );
  }

  Future<void> _openTraining() async {
    final difficulty = await _showDifficultySheet();
    if (!mounted || difficulty == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          initialTrainingMode: true,
          initialDifficulty: difficulty,
        ),
      ),
    );
  }

  Future<PracticeDifficulty?> _showDifficultySheet() {
    return showModalBottomSheet<PracticeDifficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        const items = [
          (PracticeDifficulty.easy, 'Easy', '10 – 40'),
          (PracticeDifficulty.medium, 'Medium', '30 – 70'),
          (PracticeDifficulty.hard, 'Hard', '50 – 100'),
          (PracticeDifficulty.expert, 'Expert', '80 – 120'),
        ];

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A1628),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x33FFB300), width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Difficulty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 18),
              for (final entry in items) ...[
                _DifficultyRow(
                  label: entry.$2,
                  range: entry.$3,
                  accent: _amber,
                  onTap: () => Navigator.of(ctx).pop(entry.$1),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1F), Color(0xFF05070D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildClassicCard(),
                          const SizedBox(height: 14),
                          _buildRushCard(),
                          const SizedBox(height: 14),
                          _buildTrainingCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white.withValues(alpha: 0.70),
          enableFeedback: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Free Play',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
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
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }

  // ── Classic — Cyan PRIMARY (stärkster Glow) ─────────────────────────────
  Widget _buildClassicCard() {
    return _ModeCard(
      onPressed: _openClassic,
      label: 'Classic',
      sublabel: 'Open-ended dice play',
      glowColor: _cyan,
      borderColor: _cyan.withValues(alpha: 1.0),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_cyan.withValues(alpha: 0.16), _cyan.withValues(alpha: 0.06)],
      ),
      sublabelColor: _cyan.withValues(alpha: 0.95),
      glowAlpha: 0.45,
      glowBlur: 28,
      borderWidth: 2.0,
      labelSize: 26,
    );
  }

  // ── Rush — Cyan MID ─────────────────────────────────────────────────────
  Widget _buildRushCard() {
    return _ModeCard(
      onPressed: _openRush,
      label: 'Rush',
      sublabel: 'Solve as many as possible in 90 seconds',
      glowColor: _cyan,
      borderColor: _cyan.withValues(alpha: 0.70),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_cyan.withValues(alpha: 0.09), _cyan.withValues(alpha: 0.03)],
      ),
      sublabelColor: _cyan.withValues(alpha: 0.75),
      glowAlpha: 0.22,
      glowBlur: 18,
      borderWidth: 1.5,
      labelSize: 24,
    );
  }

  // ── Training — Cyan SUBTLE ──────────────────────────────────────────────
  Widget _buildTrainingCard() {
    return _ModeCard(
      onPressed: _openTraining,
      label: 'Training',
      sublabel: 'Solvable puzzles by difficulty',
      glowColor: _cyan,
      borderColor: _cyan.withValues(alpha: 0.40),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_cyan.withValues(alpha: 0.05), _cyan.withValues(alpha: 0.02)],
      ),
      sublabelColor: _cyan.withValues(alpha: 0.55),
      glowAlpha: 0.12,
      glowBlur: 12,
      borderWidth: 1.0,
      labelSize: 22,
    );
  }
}

// ── _ModeCard ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final String sublabel;
  final Color glowColor;
  final Color borderColor;
  final LinearGradient bgGradient;
  final Color sublabelColor;
  final double glowAlpha;
  final double glowBlur;
  final double borderWidth;
  final double labelSize;

  const _ModeCard({
    required this.onPressed,
    required this.label,
    required this.sublabel,
    required this.glowColor,
    required this.borderColor,
    required this.bgGradient,
    required this.sublabelColor,
    required this.glowAlpha,
    required this.glowBlur,
    required this.borderWidth,
    required this.labelSize,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: widget.bgGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.borderColor, width: widget.borderWidth),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: widget.glowAlpha),
                  blurRadius: widget.glowBlur,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.labelSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(
                        color: widget.glowColor.withValues(alpha: widget.glowAlpha * 1.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.sublabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.sublabelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _DifficultyRow ────────────────────────────────────────────────────────────

class _DifficultyRow extends StatelessWidget {
  final String label;
  final String range;
  final Color accent;
  final VoidCallback onTap;

  const _DifficultyRow({
    required this.label,
    required this.range,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.30), width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              range,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
