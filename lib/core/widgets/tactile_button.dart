import 'package:flutter/material.dart';
import 'package:dice/core/theme/app_colors.dart';

enum TactileButtonVariant { primary, gold, danger, muted }

class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final TactileButtonVariant variant;
  final Color? customColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool selected;
  final bool enabled;
  final double? width;
  final double? height;

  const TactileButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = TactileButtonVariant.primary,
    this.customColor,
    this.borderRadius,
    this.padding,
    this.selected = false,
    this.enabled = true,
    this.width,
    this.height,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _pressed = false;

  bool get _canPress => widget.enabled && widget.onPressed != null;

  Color get _baseColor {
    if (widget.customColor != null) return widget.customColor!;
    switch (widget.variant) {
      case TactileButtonVariant.gold:     return AppColors.gold;
      case TactileButtonVariant.danger:   return AppColors.opSubtract;
      case TactileButtonVariant.muted:    return AppColors.surfaceHigh;
      case TactileButtonVariant.primary:  return AppColors.surface;
    }
  }

  bool get _isGoldVariant => widget.variant == TactileButtonVariant.gold;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final isPressed = _canPress && _pressed;
    final isSelected = widget.selected && widget.enabled;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: widget.enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTapDown: _canPress ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _canPress ? (_) {
          setState(() => _pressed = false);
          widget.onPressed?.call();
        } : null,
        onTapCancel: _canPress ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          transform: isPressed
              ? Matrix4.translationValues(0.0, 1.5, 0.0)
              : Matrix4.identity(),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: _isGoldVariant ? _baseColor : _baseColor,
            border: Border.all(
              color: isSelected
                  ? AppColors.gold.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 0.8,
            ),
            boxShadow: isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ]
                : [
                    // Top-left highlight (Lichtquelle)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: _isGoldVariant ? 0.18 : 0.07),
                      blurRadius: 0,
                      spreadRadius: 0,
                      offset: const Offset(-1.5, -1.5),
                    ),
                    // Bottom-right shadow (Tiefe)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                    // Ambient depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                  ],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: _isGoldVariant ? AppColors.dicePip : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
