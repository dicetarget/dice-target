import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:flutter/material.dart';

class PracticeBottomButtons extends StatelessWidget {
  final bool canPressBottom;
  final bool isPlaying;
  final bool resetEnabled;
  final VoidCallback? onNoSolution;
  final VoidCallback? onNewGame;
  final VoidCallback? onResetPuzzle;

  const PracticeBottomButtons({
    super.key,
    required this.canPressBottom,
    required this.isPlaying,
    required this.resetEnabled,
    required this.onNoSolution,
    required this.onNewGame,
    required this.onResetPuzzle,
  });

  @override
  Widget build(BuildContext context) {
    final canNoSolution = canPressBottom && isPlaying;

    return Column(
      children: [
        _ResetPuzzleButton(
          enabled: resetEnabled,
          onPressed: resetEnabled ? onResetPuzzle : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        TactileButton(
          variant: TactileButtonVariant.primary,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          enabled: canNoSolution,
          onPressed: canNoSolution ? onNoSolution : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.gold),
              SizedBox(width: 8),
              Text(
                'Show Solution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 0.2,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TactileButton(
          variant: TactileButtonVariant.gold,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          enabled: canPressBottom,
          onPressed: canPressBottom ? onNewGame : null,
          child: const Text(
            'New Game',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dicePip,
              letterSpacing: 0.3,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
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
              borderRadius: BorderRadius.circular(14),
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
