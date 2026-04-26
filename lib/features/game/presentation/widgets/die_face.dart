import 'package:flutter/material.dart';

class DieFace extends StatelessWidget {
  final int value;
  final bool selected;
  final String? overlayText;

  const DieFace({super.key, required this.value, required this.selected, this.overlayText});

  bool get _showPips => overlayText == null && value >= 1 && value <= 6;
  bool get _showZero => overlayText == null && value == 0;

  static const Color _neon = Color(0xFF3FE8FF);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.07 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: 74,
        height: 74,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Neon outer glow ring wenn selektiert
            if (selected)
              Positioned(
                left: -5,
                top: -5,
                right: -5,
                bottom: -5,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _neon.withValues(alpha: 0.95), width: 2.8),
                      boxShadow: [
                        BoxShadow(
                          color: _neon.withValues(alpha: 0.80),
                          blurRadius: 14,
                          spreadRadius: 1.5,
                        ),
                        BoxShadow(
                          color: _neon.withValues(alpha: 0.38),
                          blurRadius: 28,
                          spreadRadius: 3.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Würfel-Body: dunkler 3D-Gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? const [Color(0xFF1E3A56), Color(0xFF152C44), Color(0xFF0D1E30)]
                      : const [Color(0xFF172840), Color(0xFF102035), Color(0xFF091828)],
                  stops: const [0.0, 0.52, 1.0],
                ),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF3FE8FF).withValues(alpha: 0.85)
                      : const Color(0xFF3FE8FF).withValues(alpha: 0.28),
                  width: selected ? 1.8 : 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3FE8FF).withValues(alpha: selected ? 0.35 : 0.12),
                    blurRadius: selected ? 22 : 10,
                    spreadRadius: selected ? 1.0 : 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: selected ? 0.65 : 0.50),
                    blurRadius: selected ? 22 : 14,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: selected ? 0.12 : 0.07),
                    blurRadius: 0,
                    spreadRadius: -1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  children: [
                    // Top-Left Shine
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-0.55, -0.60),
                              radius: 1.0,
                              colors: [
                                Colors.white.withValues(alpha: selected ? 0.12 : 0.07),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Neon-Tint wenn selektiert
                    if (selected)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topCenter,
                                radius: 1.1,
                                colors: [
                                  const Color(0xFF9B6DFF).withValues(alpha: 0.14),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Pip / Zero / CenterText
                    if (overlayText == null)
                      Positioned.fill(
                        child: _showPips
                            ? _Pips(value: value, selected: selected)
                            : (_showZero ? const _ZeroMark() : _CenterText(text: value.toString())),
                      ),
                    // Merged Result Overlay
                    if (overlayText != null)
                      Positioned.fill(child: _MergedOverlay(text: overlayText!)),
                  ],
                ),
              ),
            ),

            // Weisser Inner-Border-Ring wenn selektiert
            if (selected)
              Positioned(
                left: -1,
                top: -1,
                right: -1,
                bottom: -1,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 0.8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Merged Result Overlay ─────────────────────────────────────────────────────

class _MergedOverlay extends StatelessWidget {
  final String text;
  const _MergedOverlay({required this.text});

  static const _cyan = Color(0xFF3FE8FF);
  static const _gold = Color(0xFFFFD93D);

  @override
  Widget build(BuildContext context) {
    // Kurze Zahlen (≤2 Ziffern) gross, längere kleiner
    final digits = text.length;
    final fontSize = digits <= 2
        ? 28.0
        : digits == 3
        ? 22.0
        : 18.0;

    return Stack(
      children: [
        // Hintergrund: radialer Glow von Mitte
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    _cyan.withValues(alpha: 0.14),
                    _gold.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Horizontale Trennlinie oben (dezent)
        Positioned(
          top: 0,
          left: 8,
          right: 8,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _cyan.withValues(alpha: 0.30), Colors.transparent],
              ),
            ),
          ),
        ),
        // Zahl
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
                letterSpacing: -0.5,
                shadows: const [
                  // Cyan-Glow
                  Shadow(color: _cyan, blurRadius: 14),
                  // Goldener Schimmer für Tiefe
                  Shadow(color: _gold, blurRadius: 22),
                  // Schwarzer Drop-Shadow für Lesbarkeit
                  Shadow(color: Color(0xFF000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
        // Subtiler Glanz-Strich unten rechts
        Positioned(
          bottom: 8,
          right: 10,
          child: IgnorePointer(
            child: Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: Colors.white.withValues(alpha: 0.12),
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
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1),
        ),
        child: const Text(
          '0',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1,
            color: Color(0xFFCECBFF),
          ),
        ),
      ),
    );
  }
}

// ── Center Text (Zahlen > 6, nicht merged) ───────────────────────────────────

class _CenterText extends StatelessWidget {
  final String text;
  const _CenterText({required this.text});

  static const _cyan = Color(0xFF3FE8FF);
  static const _gold = Color(0xFFFFD93D);

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
        // Radialer Glow von Mitte
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    _cyan.withValues(alpha: 0.14),
                    _gold.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Dezente Trennlinie oben
        Positioned(
          top: 0,
          left: 8,
          right: 8,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _cyan.withValues(alpha: 0.30), Colors.transparent],
              ),
            ),
          ),
        ),
        // Zahl mit Glow
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
                letterSpacing: -0.5,
                shadows: const [
                  Shadow(color: _cyan, blurRadius: 14),
                  Shadow(color: _gold, blurRadius: 22),
                  Shadow(color: Color(0xFF000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
        // Glanz-Strich unten rechts
        Positioned(
          bottom: 8,
          right: 10,
          child: IgnorePointer(
            child: Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pips ─────────────────────────────────────────────────────────────────────

class _Pips extends StatelessWidget {
  final int value;
  final bool selected;
  const _Pips({required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    Widget pip(bool on) => AnimatedOpacity(
      opacity: on ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on
              ? (selected ? const Color(0xFFFFFFFF) : const Color(0xFFB8E4F5))
              : Colors.transparent,
          boxShadow: on
              ? [
                  BoxShadow(
                    color: const Color(0xFF3FE8FF).withValues(alpha: selected ? 0.85 : 0.50),
                    blurRadius: selected ? 8 : 5,
                    spreadRadius: selected ? 1.2 : 0.6,
                  ),
                ]
              : null,
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
      padding: const EdgeInsets.all(11),
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
