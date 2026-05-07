import 'package:dice/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DieFace extends StatelessWidget {
  final int value;
  final bool selected;
  final String? overlayText;

  const DieFace({super.key, required this.value, required this.selected, this.overlayText});

  bool get _showPips => overlayText == null && value >= 1 && value <= 6;
  bool get _showZero => overlayText == null && value == 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0EDE4), Color(0xFFC8C4B8)],
          ),
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.90)
                : Colors.black.withValues(alpha: 0.15),
            width: selected ? 1.8 : 0.8,
          ),
          boxShadow: [
            // Top-left highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.60),
              blurRadius: 0,
              offset: const Offset(-1.5, -1.5),
            ),
            // Bottom-right shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 6,
              offset: const Offset(2.5, 4),
            ),
            // Ambient
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            // Gold selection glow
            if (selected)
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              if (overlayText == null)
                Positioned.fill(
                  child: _showPips
                      ? _Pips(value: value)
                      : (_showZero ? const _ZeroMark() : _CenterText(text: value.toString())),
                ),
              if (overlayText != null)
                Positioned.fill(child: _MergedOverlay(text: overlayText!)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Merged Result Overlay ─────────────────────────────────────────────────────

class _MergedOverlay extends StatelessWidget {
  final String text;
  const _MergedOverlay({required this.text});

  @override
  Widget build(BuildContext context) {
    final digits = text.length;
    final fontSize = digits <= 2
        ? 28.0
        : digits == 3
            ? 22.0
            : 18.0;

    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
            ),
          ),
        ),
        // Gold top border line
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: AppColors.gold.withValues(alpha: 0.25),
          ),
        ),
        // Number
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Zero Mark ────────────────────────────────────────────────────────────────

class _ZeroMark extends StatelessWidget {
  const _ZeroMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.inkFaint.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: const Text(
          '0',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1,
            color: AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

// ── Center Text (numbers > 6, not merged) ────────────────────────────────────

class _CenterText extends StatelessWidget {
  final String text;
  const _CenterText({required this.text});

  @override
  Widget build(BuildContext context) {
    final digits = text.length;
    final fontSize = digits <= 2
        ? 28.0
        : digits == 3
            ? 22.0
            : 18.0;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.dicePip,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ── Pips ─────────────────────────────────────────────────────────────────────

class _Pips extends StatelessWidget {
  final int value;
  const _Pips({required this.value});

  @override
  Widget build(BuildContext context) {
    Widget pip(bool on) => on
        ? Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dicePip,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.40),
                width: 0.5,
              ),
            ),
            child: Align(
              alignment: const Alignment(-0.5, -0.5),
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          )
        : const SizedBox(width: 10, height: 10);

    final on = List<bool>.filled(9, false);
    void setOn(List<int> idx) {
      for (final i in idx) {
        on[i] = true;
      }
    }

    switch (value) {
      case 1:
        setOn([4]);
        break;
      case 2:
        setOn([0, 8]);
        break;
      case 3:
        setOn([0, 4, 8]);
        break;
      case 4:
        setOn([0, 2, 6, 8]);
        break;
      case 5:
        setOn([0, 2, 4, 6, 8]);
        break;
      case 6:
        setOn([0, 2, 3, 5, 6, 8]);
        break;
      default:
        setOn([4]);
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        primary: false,
        children: List.generate(9, (i) => Center(child: pip(on[i]))),
      ),
    );
  }
}
