import 'package:flutter/material.dart';
import 'package:dice/core/theme/app_colors.dart';

enum TactileButtonVariant { primary, gold, danger, muted, ghost }

class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final TactileButtonVariant variant;
  final Color? customColor;
  final Color? customBorderColor;
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
    this.customBorderColor,
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
      case TactileButtonVariant.ghost:   return Colors.transparent;
      case TactileButtonVariant.primary: return AppColors.buttonPrimary;
    }
  }

  bool get _isGoldVariant => widget.variant == TactileButtonVariant.gold;
  bool get _isGhostVariant => widget.variant == TactileButtonVariant.ghost;

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
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          transform: isPressed
              ? (Matrix4.identity()..scaleByDouble(0.93, 0.93, 1.0, 1.0)..translateByDouble(0.0, 1.5, 0.0, 1.0))
              : Matrix4.identity(),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: _isGoldVariant ? null : _baseColor,
            gradient: _isGoldVariant
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE8C96A), // goldLight
                      Color(0xFFD4AF37), // gold
                      Color(0xFFA88A22), // goldDark
                    ],
                    stops: [0.0, 0.50, 1.0],
                  )
                : null,
            border: Border.all(
              color: isSelected
                  ? AppColors.gold.withValues(alpha: 0.85)
                  : widget.customBorderColor != null
                  ? widget.customBorderColor!.withValues(alpha: 0.80)
                  : _isGhostVariant
                      ? AppColors.gold.withValues(alpha: 0.45)
                      : _isGoldVariant
                          ? AppColors.goldDark.withValues(alpha: 0.60)
                          : AppColors.buttonPrimaryBorder.withValues(alpha: 0.80),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: _isGhostVariant
                ? []
                : isPressed
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.40),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: _isGoldVariant ? 0.22 : 0.09),
                          blurRadius: 0,
                          spreadRadius: 0,
                          offset: const Offset(-2, -2),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 8,
                          offset: const Offset(3, 5),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.30),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                      ],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: _isGhostVariant
                  ? AppColors.gold
                  : _isGoldVariant
                      ? AppColors.dicePip
                      : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
