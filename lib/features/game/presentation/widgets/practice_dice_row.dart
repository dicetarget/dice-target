import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/presentation/widgets/die_face.dart';
import 'package:flutter/material.dart';

enum FinalDiceState { none, success, fail }

class PracticeDieData {
  final int value;
  final String? maskLabel;

  const PracticeDieData({required this.value, required this.maskLabel});
}

class PracticeDiceRow extends StatelessWidget {
  final bool isRolling;
  final bool isPlaying;
  final bool busy;
  final bool showMergedResults;
  final bool rollingTargetLocked;
  final int mergePopKey;
  final List<int> rollingDice;
  final List<PracticeDieData> dice;
  final Set<int> selectedIndices;
  final Color accentColor;
  final UiOp? pendingOp;
  final FinalDiceState finalDiceState;
  final void Function(int index) onToggleSelect;

  const PracticeDiceRow({
    super.key,
    required this.isRolling,
    required this.isPlaying,
    required this.busy,
    required this.showMergedResults,
    required this.rollingTargetLocked,
    required this.mergePopKey,
    required this.rollingDice,
    required this.dice,
    required this.selectedIndices,
    required this.accentColor,
    this.pendingOp,
    required this.finalDiceState,
    required this.onToggleSelect,
  });

  static const double _dieSize = 80.0;
  static const double _itemSpacing = 16.0;
  static const double _rowHeight = 172.0;
  static const Color _selectionNeon = Color(0xFF5AB6FF);

  @override
  Widget build(BuildContext context) {
    if (isRolling) {
      return SizedBox(
        height: _rowHeight,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: _itemSpacing,
            runSpacing: 12.0,
            children: List.generate(rollingDice.length, (i) {
              final idle = !rollingTargetLocked;
              return SizedBox(
                width: _dieSize,
                height: _dieSize,
                child: AnimatedOpacity(
                  opacity: idle ? 0.38 : 1,
                  duration: const Duration(milliseconds: 140),
                  child: _buildDieShell(child: DieFace(value: rollingDice[i], selected: false)),
                ),
              );
            }),
          ),
        ),
      );
    }

    final opActive = pendingOp != null && isPlaying && !busy;

    final diceWidgets = <Widget>[];
    for (int i = 0; i < dice.length; i++) {
      final selected = selectedIndices.contains(i) && isPlaying && !busy;
      final overlay = dice[i].maskLabel;
      final isLast = i == dice.length - 1;
      final isFinalDie = isLast && dice.length == 1;
      final showSuccess = isFinalDie && finalDiceState == FinalDiceState.success;
      final showFail = isFinalDie && finalDiceState == FinalDiceState.fail;

      // Nicht-selektierte Würfel zurückdimmen wenn Op aktiv
      final double dieOpacity = (opActive && !selected) ? 0.52 : 1.0;

      Widget dieContent({double mergeFlash = 0.0}) {
        Widget shell = SizedBox(
          width: _dieSize,
          height: _dieSize,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            offset: selected ? const Offset(0, -0.055) : Offset.zero,
            child: AnimatedScale(
              scale: selected ? 1.085 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: _buildDieShell(
                  selected: selected,
                  mergeFlash: mergeFlash,
                  showSuccess: showSuccess,
                  showFail: showFail,
                  child: DieFace(value: dice[i].value, selected: selected, overlayText: overlay),
                ),
              ),
            ),
          ),
        );

        if (showSuccess) {
          return TweenAnimationBuilder<double>(
            key: const ValueKey('success_pop'),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, t, child) {
              final popScale = 1.0 + (0.18 * (1.0 - (t - 1.0).abs().clamp(0.0, 1.0)));
              return Transform.scale(scale: popScale, child: child);
            },
            child: shell,
          );
        }

        return shell;
      }

      final dieWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onToggleSelect(i),
        child: AnimatedOpacity(
          opacity: dieOpacity,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: isLast && showMergedResults && mergePopKey > 0
              ? TweenAnimationBuilder<double>(
                  key: ValueKey(mergePopKey),
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) {
                    final popScale = 1.0 + (0.16 * t);
                    final liftY = -6.0 * t;
                    return Transform.translate(
                      offset: Offset(0, liftY),
                      child: Transform.scale(
                        scale: popScale,
                        child: dieContent(mergeFlash: t),
                      ),
                    );
                  },
                )
              : dieContent(),
        ),
      );

      diceWidgets.add(dieWidget);
    }

    return SizedBox(
      height: _rowHeight,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: _itemSpacing,
          runSpacing: 12.0,
          children: diceWidgets,
        ),
      ),
    );
  }

  Widget _buildDieShell({required Widget child, bool selected = false, double mergeFlash = 0.0, bool showSuccess = false, bool showFail = false}) {
    final flashGlow = mergeFlash.clamp(0.0, 1.0);
    final isMergeAnimating = flashGlow > 0.001;
    const selectionColor = _selectionNeon;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: showSuccess
              ? [const Color(0xFFD4AC0D).withValues(alpha: 0.28), const Color(0xFFFFD93D).withValues(alpha: 0.14)]
              : showFail
                  ? [const Color(0xFFE57373).withValues(alpha: 0.22), const Color(0xFFE57373).withValues(alpha: 0.08)]
                  : isMergeAnimating
                      ? [Colors.white.withValues(alpha: 0.34), accentColor.withValues(alpha: 0.24)]
                      : selected
                          ? [Colors.white.withValues(alpha: 0.30), selectionColor.withValues(alpha: 0.22)]
                          : [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.04)],
        ),
        border: Border.all(
          color: showSuccess
              ? const Color(0xFFD4AC0D).withValues(alpha: 0.95)
              : showFail
                  ? const Color(0xFFE57373).withValues(alpha: 0.90)
                  : isMergeAnimating
                      ? accentColor.withValues(alpha: 0.84)
                      : selected
                          ? selectionColor.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.18),
          width: (showSuccess || showFail)
              ? 2.2
              : isMergeAnimating
                  ? 2.3
                  : selected
                      ? 2.4
                      : 1.2,
        ),
        boxShadow: showSuccess
            ? [
                BoxShadow(
                  color: const Color(0xFFD4AC0D).withValues(alpha: 0.70),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFFD93D).withValues(alpha: 0.35),
                  blurRadius: 38,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : showFail
                ? [
                    BoxShadow(
                      color: const Color(0xFFE57373).withValues(alpha: 0.60),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFFE57373).withValues(alpha: 0.28),
                      blurRadius: 30,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : isMergeAnimating
                    ? [
                        BoxShadow(color: accentColor.withValues(alpha: 0.34 * flashGlow), blurRadius: 20, spreadRadius: 1.6),
                        BoxShadow(color: accentColor.withValues(alpha: 0.24 * flashGlow), blurRadius: 28, spreadRadius: 1.0, offset: const Offset(0, 10)),
                        BoxShadow(color: Colors.black.withValues(alpha: 0.34), blurRadius: 14, offset: const Offset(0, 8)),
                        BoxShadow(color: Colors.white.withValues(alpha: 0.14), blurRadius: 0, spreadRadius: -2, offset: const Offset(0, -2)),
                      ]
                    : selected
                        ? [
                            BoxShadow(color: selectionColor.withValues(alpha: 0.60), blurRadius: 10, spreadRadius: 1.2),
                            BoxShadow(color: selectionColor.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: 2.0),
                            BoxShadow(color: selectionColor.withValues(alpha: 0.24), blurRadius: 20, spreadRadius: 0.6, offset: const Offset(0, 10)),
                            BoxShadow(color: Colors.black.withValues(alpha: 0.34), blurRadius: 14, offset: const Offset(0, 10)),
                            BoxShadow(color: Colors.white.withValues(alpha: 0.18), blurRadius: 0, spreadRadius: -2, offset: const Offset(0, -2)),
                          ]
                        : [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 6)),
                            BoxShadow(color: Colors.white.withValues(alpha: 0.08), blurRadius: 0, spreadRadius: -2, offset: const Offset(0, -2)),
                          ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: selected ? 0.15 : 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.12,
                        colors: [selectionColor.withValues(alpha: 0.18), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            if (isMergeAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.05,
                        colors: [
                          Colors.white.withValues(alpha: 0.24 * flashGlow),
                          accentColor.withValues(alpha: 0.18 * flashGlow),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.38, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
