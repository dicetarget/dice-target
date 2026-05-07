import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class PracticeBottomButtons extends StatelessWidget {
  final bool canPressBottom;
  final bool isPlaying;
  final bool resetEnabled;
  final Color accentColor;
  final Color inkColor;
  final VoidCallback? onNoSolution;
  final VoidCallback? onNewGame;
  final VoidCallback? onResetPuzzle;

  const PracticeBottomButtons({
    super.key,
    required this.canPressBottom,
    required this.isPlaying,
    required this.resetEnabled,
    required this.accentColor,
    required this.inkColor,
    required this.onNoSolution,
    required this.onNewGame,
    required this.onResetPuzzle,
  });

  @override
  Widget build(BuildContext context) {
    final canNoSolution = canPressBottom && isPlaying;

    return Column(
      children: [
        _ShowSolutionButton(enabled: canNoSolution, onPressed: canNoSolution ? onNoSolution : null),
        const SizedBox(height: AppSpacing.sm),
        _ResetPuzzleButton(enabled: resetEnabled, onPressed: onResetPuzzle),
        const SizedBox(height: AppSpacing.xl),
        _NewGameButton(
          enabled: canPressBottom,
          onPressed: canPressBottom ? onNewGame : null,
          accentColor: accentColor,
        ),
      ],
    );
  }
}

class _ShowSolutionButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _ShowSolutionButton({required this.enabled, required this.onPressed});

  @override
  State<_ShowSolutionButton> createState() => _ShowSolutionButtonState();
}

class _ShowSolutionButtonState extends State<_ShowSolutionButton> {
  bool _pressed = false;

  static const Color _amber = Color(0xFFD4AC0D);
  static const Color _amberGlow = Color(0xFFFFD93D);
  static const Color _amberLt = Color(0xFFFFF0A0);

  @override
  Widget build(BuildContext context) {
    final en = widget.enabled;
    final scale = _pressed ? 0.97 : 1.0;

    return GestureDetector(
      onTapDown: en ? (_) => setState(() => _pressed = true) : null,
      onTapUp: en ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: en ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: en ? _amber.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: en ? _amber.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.07),
                width: en ? 1.4 : 1.0,
              ),
              boxShadow: en
                  ? [
                      BoxShadow(
                        color: _amberGlow.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: Offset.zero,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: en ? _amberLt : Colors.white.withValues(alpha: 0.25),
                ),
                const SizedBox(width: 8),
                Text(
                  'Show Solution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: en ? _amberLt : Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 0.2,
                    height: 1,
                    shadows: en
                        ? [Shadow(color: _amberGlow.withValues(alpha: 0.40), blurRadius: 8)]
                        : null,
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

class _NewGameButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onPressed;
  final Color accentColor;

  const _NewGameButton({required this.enabled, required this.onPressed, required this.accentColor});

  @override
  State<_NewGameButton> createState() => _NewGameButtonState();
}

class _ResetPuzzleButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _ResetPuzzleButton({required this.enabled, required this.onPressed});

  @override
  State<_ResetPuzzleButton> createState() => _ResetPuzzleButtonState();
}

class _ResetPuzzleButtonState extends State<_ResetPuzzleButton> {
  bool _pressed = false;

  static const Color _resetColor = Color(0xFFB85C5C);
  static const Color _resetColorLt = Color(0xFFFFB3B3);

  @override
  Widget build(BuildContext context) {
    final en = widget.enabled;
    final scale = _pressed ? 0.97 : 1.0;

    return GestureDetector(
      onTapDown: en ? (_) => setState(() => _pressed = true) : null,
      onTapUp: en ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: en ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: en
                  ? _resetColor.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: en
                    ? _resetColor.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: en
                      ? _resetColorLt.withValues(alpha: 0.70)
                      : Colors.white.withValues(alpha: 0.18),
                ),
                const SizedBox(width: 7),
                Text(
                  'Reset Puzzle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: en
                        ? _resetColorLt.withValues(alpha: 0.70)
                        : Colors.white.withValues(alpha: 0.18),
                    letterSpacing: 0.1,
                    height: 1,
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

class _NewGameButtonState extends State<_NewGameButton> {
  bool _pressed = false;

  static const Color _cyan = Color(0xFF3FE8FF);
  static const Color _cyanGlow = Color(0xFF7FFFFF);
  static const Color _cyanLt = Color(0xFFE0FEFF);

  @override
  Widget build(BuildContext context) {
    final en = widget.enabled;
    final scale = _pressed ? 0.97 : 1.0;

    return GestureDetector(
      onTapDown: en ? (_) => setState(() => _pressed = true) : null,
      onTapUp: en ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: en ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: en ? _cyan.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: en ? _cyan.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.10),
                width: en ? 1.5 : 1.0,
              ),
              boxShadow: en
                  ? [
                      BoxShadow(
                        color: _cyan.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: Offset.zero,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                'New Game',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: en ? _cyanLt : Colors.white.withValues(alpha: 0.25),
                  letterSpacing: 0.5,
                  height: 1,
                  shadows: en
                      ? [
                          Shadow(color: _cyan.withValues(alpha: 0.55), blurRadius: 12),
                          Shadow(color: _cyanGlow.withValues(alpha: 0.25), blurRadius: 24),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
