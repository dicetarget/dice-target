import 'package:dice/core/theme/app_durations.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:dice/core/ui_op.dart';
import 'package:flutter/material.dart';

class PracticeOpsRow extends StatelessWidget {
  final bool canInteractGameplay;
  final List<UiOp> allowedOps;
  final UiOp? pendingOp;
  final Color accentColor;
  final Color inkColor;
  final void Function(UiOp op) onApplyOp;

  const PracticeOpsRow({
    super.key,
    required this.canInteractGameplay,
    required this.allowedOps,
    required this.pendingOp,
    required this.accentColor,
    required this.inkColor,
    required this.onApplyOp,
  });

  @override
  Widget build(BuildContext context) {
    Widget opButton(UiOp op) {
      final enabled = canInteractGameplay && allowedOps.contains(op);
      final isSelected = pendingOp == op;
      final opStyle = _styleFor(op);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _PremiumOpButton(
            symbol: uiOpSymbol(op),
            enabled: enabled,
            isSelected: isSelected,
            style: opStyle,
            onPressed: enabled ? () => onApplyOp(op) : null,
          ),
        ),
      );
    }

    return Row(
      children: [opButton(UiOp.add), opButton(UiOp.sub), opButton(UiOp.mul), opButton(UiOp.div)],
    );
  }

  _OpVisualStyle _styleFor(UiOp op) {
    switch (op) {
      case UiOp.add:
        return const _OpVisualStyle(
          base: Color(0xFF26D98A),
          deep: Color(0xFF0FA86A),
          glow: Color(0xFF5FFFC0),
          activeSymbol: Color(0xFFDDFFF5),
        );
      case UiOp.sub:
        return const _OpVisualStyle(
          base: Color(0xFFE8604A),
          deep: Color(0xFFAA3828),
          glow: Color(0xFFFF8070),
          activeSymbol: Color(0xFFFFEAE6),
        );
      case UiOp.mul:
        return const _OpVisualStyle(
          base: Color(0xFFD4AC0D),
          deep: Color(0xFF9A7A00),
          glow: Color(0xFFFFD93D),
          activeSymbol: Color(0xFFFFF8DC),
        );
      case UiOp.div:
        return const _OpVisualStyle(
          base: Color(0xFF2980B9),
          deep: Color(0xFF1A5276),
          glow: Color(0xFF5DADE2),
          activeSymbol: Color(0xFFD6EAF8),
        );
    }
  }
}

class _PremiumOpButton extends StatefulWidget {
  final String symbol;
  final bool enabled;
  final bool isSelected;
  final _OpVisualStyle style;
  final VoidCallback? onPressed;

  const _PremiumOpButton({
    required this.symbol,
    required this.enabled,
    required this.isSelected,
    required this.style,
    required this.onPressed,
  });

  @override
  State<_PremiumOpButton> createState() => _PremiumOpButtonState();
}

class _PremiumOpButtonState extends State<_PremiumOpButton> {
  bool _isPressed = false;
  double _pulse = 0.0;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final isSelected = widget.isSelected;
    final isPressed = enabled && _isPressed;
    final style = widget.style;

    final Color symbolColor = enabled
        ? (isSelected ? style.activeSymbol : Colors.white.withValues(alpha: 0.96))
        : Colors.white.withValues(alpha: 0.40);

    final double scale = isPressed ? 0.84 : (isSelected ? 1.12 : 1.0);
    final double yOffset = isPressed ? 10 : 0;

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.80,
      duration: AppDurations.medium,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: Offset(0, yOffset / 100),
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button + 2),
              boxShadow: _buildOuterShadow(
                enabled: enabled,
                isSelected: isSelected,
                isPressed: isPressed,
                style: style,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: enabled
                    ? (_) {
                        _setPressed(true);
                        setState(() => _pulse = 1.0);
                        Future.delayed(const Duration(milliseconds: 120), () {
                          if (mounted) setState(() => _pulse = 0.0);
                        });
                      }
                    : null,
                onTapUp: enabled ? (_) => _setPressed(false) : null,
                onTapCancel: enabled ? () => _setPressed(false) : null,
                borderRadius: BorderRadius.circular(AppRadius.button),
                splashColor: style.glow.withValues(alpha: 0.16),
                highlightColor: style.glow.withValues(alpha: 0.08),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: enabled
                          ? (isSelected
                                ? style.glow.withValues(alpha: 0.65)
                                : (isPressed
                                      ? style.glow.withValues(alpha: 0.48)
                                      : Colors.white.withValues(alpha: 0.16)))
                          : Colors.white.withValues(alpha: 0.10),
                      width: isSelected ? 1.8 : (isPressed ? 1.4 : 1.0),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: enabled
                          ? [
                              _mix(
                                style.glow,
                                Colors.white,
                                isSelected ? 0.18 : 0.10,
                              ).withValues(alpha: isPressed ? 0.92 : 0.98),
                              style.base.withValues(alpha: isPressed ? 0.75 : 0.92),
                              style.deep.withValues(alpha: isPressed ? 0.92 : 0.98),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.14),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.85),
                                radius: 1.15,
                                colors: enabled
                                    ? [
                                        Colors.white.withValues(
                                          alpha: isSelected ? 0.30 : (isPressed ? 0.14 : 0.22),
                                        ),
                                        Colors.white.withValues(
                                          alpha: isSelected ? 0.08 : (isPressed ? 0.03 : 0.06),
                                        ),
                                        Colors.transparent,
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.05),
                                        Colors.transparent,
                                        Colors.transparent,
                                      ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              gradient: RadialGradient(
                                center: const Alignment(0, 0),
                                radius: 1.05,
                                colors: enabled
                                    ? [
                                        style.glow.withValues(
                                          alpha:
                                              (isSelected
                                                  ? (isPressed ? 0.22 : 0.55)
                                                  : (isPressed ? 0.14 : 0.09)) +
                                              (_pulse * 0.35),
                                        ),
                                        style.base.withValues(
                                          alpha: isSelected
                                              ? (isPressed ? 0.10 : 0.15)
                                              : (isPressed ? 0.06 : 0.04),
                                        ),
                                        Colors.transparent,
                                      ]
                                    : [Colors.transparent, Colors.transparent, Colors.transparent],
                                stops: const [0.0, 0.58, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 76,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppDurations.fast,
                            curve: Curves.easeOutCubic,
                            style: AppTextStyles.button.copyWith(
                              fontSize: isPressed ? 27 : 31,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                              color: symbolColor,
                              height: 1,
                              shadows: enabled
                                  ? [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: isSelected ? 0.26 : 0.22,
                                        ),
                                        offset: const Offset(0, 1.5),
                                        blurRadius: 2,
                                      ),
                                      Shadow(
                                        color: style.glow.withValues(
                                          alpha: isSelected
                                              ? (isPressed ? 0.34 : 0.65)
                                              : (isPressed ? 0.18 : 0.28),
                                        ),
                                        blurRadius: isSelected ? 20 : 8,
                                      ),
                                    ]
                                  : [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 2,
                                      ),
                                    ],
                            ),
                            child: Text(widget.symbol),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _buildOuterShadow({
    required bool enabled,
    required bool isSelected,
    required bool isPressed,
    required _OpVisualStyle style,
  }) {
    if (!enabled) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    }

    if (isPressed) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 0.5,
          offset: const Offset(0, 0.5),
        ),
      ];
    }

    if (isSelected) {
      return [
        BoxShadow(
          color: style.glow.withValues(alpha: 0.50 + (_pulse * 0.08)),
          blurRadius: 0,
          spreadRadius: 1.5,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: style.glow.withValues(alpha: 0.30 + (_pulse * 0.12)),
          blurRadius: 18,
          spreadRadius: 2,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ];
    }

    return [
      BoxShadow(
        color: style.glow.withValues(alpha: 0.14),
        blurRadius: 10,
        spreadRadius: 0.2,
        offset: const Offset(0, 0),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ];
  }

  Color _mix(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }
}

class _OpVisualStyle {
  final Color base;
  final Color deep;
  final Color glow;
  final Color activeSymbol;

  const _OpVisualStyle({
    required this.base,
    required this.deep,
    required this.glow,
    required this.activeSymbol,
  });
}
