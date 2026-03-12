import 'package:flutter/material.dart';

class DieFace extends StatelessWidget {
  final int value; // computation value
  final bool selected;
  final String? overlayText; // "?", "?2", etc.

  const DieFace({
    super.key,
    required this.value,
    required this.selected,
    this.overlayText,
  });

  bool get _showPips => overlayText == null && value >= 1 && value <= 6;
  bool get _showZero => overlayText == null && value == 0;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Colors.black
        : Colors.black.withValues(alpha: 0.35);
    final borderWidth = selected ? 3.2 : 1.6;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.18 : 0.10),
            blurRadius: selected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (overlayText == null)
            Positioned.fill(
              child: _showPips
                  ? _Pips(value: value)
                  : (_showZero
                        ? const _ZeroMark()
                        : _CenterText(text: value.toString())),
            ),
          if (selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withValues(alpha: 0.07),
                ),
              ),
            ),
          if (overlayText != null)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    overlayText!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Makes value=0 visually unambiguous (looks like a "zero die", not "empty").
class _ZeroMark extends StatelessWidget {
  const _ZeroMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          '0',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _CenterText extends StatelessWidget {
  final String text;
  const _CenterText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  final int value;
  const _Pips({required this.value});

  @override
  Widget build(BuildContext context) {
    Widget pip(bool on) => AnimatedOpacity(
      opacity: on ? 1 : 0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );

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
      padding: const EdgeInsets.all(12),
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
