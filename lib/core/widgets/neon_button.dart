import 'package:dice/core/theme/app_durations.dart';
import 'package:dice/core/widgets/neon_container.dart';
import 'package:flutter/material.dart';

class NeonButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  final Color glowColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  final NeonIntensity intensity;
  final bool selected;
  final bool enabled;

  final double pressedScale;
  final double selectedScale;
  final double pressedYOffset;

  final Gradient? backgroundGradient;
  final Gradient? innerHighlightGradient;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderWidth;
  final List<BoxShadow>? customShadows;

  const NeonButton({
    super.key,
    required this.child,
    required this.glowColor,
    this.onPressed,
    this.borderRadius,
    this.padding,
    this.intensity = NeonIntensity.medium,
    this.selected = false,
    this.enabled = true,
    this.pressedScale = 0.965,
    this.selectedScale = 1.02,
    this.pressedYOffset = 1.5,
    this.backgroundGradient,
    this.innerHighlightGradient,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth = 1.0,
    this.customShadows,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isPressed = false;
  double _pulse = 0.0;

  bool get _canPress => widget.enabled && widget.onPressed != null;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _triggerPulse() {
    setState(() => _pulse = 1.0);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _pulse = 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = _canPress && _isPressed;
    final isSelected = widget.selected && widget.enabled;
    final scale = isPressed ? widget.pressedScale : (isSelected ? widget.selectedScale : 1.0);
    final yOffset = isPressed ? widget.pressedYOffset : 0.0;
    final radius = widget.borderRadius ?? BorderRadius.circular(18);

    return AnimatedOpacity(
      duration: AppDurations.medium,
      opacity: widget.enabled ? 1.0 : 0.72,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 55),
        curve: Curves.easeOutCubic,
        scale: scale,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 55),
          curve: Curves.easeOutCubic,
          offset: Offset(0, yOffset / 100),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: _buildWrapperShadows(
                glowColor: widget.glowColor,
                enabled: widget.enabled,
                selected: isSelected,
                pressed: isPressed,
                intensity: widget.intensity,
                pulse: _pulse,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: _canPress
                    ? (_) {
                        _setPressed(true);
                        _triggerPulse();
                      }
                    : null,
                onTapUp: _canPress ? (_) => _setPressed(false) : null,
                onTapCancel: _canPress ? () => _setPressed(false) : null,
                borderRadius: radius,
                splashColor: widget.glowColor.withValues(alpha: 0.14),
                highlightColor: widget.glowColor.withValues(alpha: 0.06),
                child: NeonContainer(
                  glowColor: widget.glowColor,
                  borderRadius: radius,
                  padding: widget.padding,
                  intensity: widget.intensity,
                  selected: isSelected,
                  enabled: widget.enabled,
                  borderColor: widget.borderColor,
                  backgroundColor: widget.backgroundColor,
                  borderWidth: widget.borderWidth,
                  backgroundGradient: widget.backgroundGradient,
                  innerHighlightGradient:
                      widget.innerHighlightGradient ?? _buildInnerPulseGradient(),
                  customShadows: widget.customShadows,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Gradient _buildInnerPulseGradient() {
    return RadialGradient(
      center: const Alignment(0, -0.1),
      radius: 1.05,
      colors: widget.enabled
          ? [
              Colors.white.withValues(alpha: widget.selected ? 0.16 : 0.10),
              widget.glowColor.withValues(alpha: (widget.selected ? 0.12 : 0.06) + (_pulse * 0.16)),
              Colors.transparent,
            ]
          : [Colors.white.withValues(alpha: 0.03), Colors.transparent, Colors.transparent],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  List<BoxShadow> _buildWrapperShadows({
    required Color glowColor,
    required bool enabled,
    required bool selected,
    required bool pressed,
    required NeonIntensity intensity,
    required double pulse,
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

    if (pressed) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 1.2,
          offset: const Offset(0, 1),
        ),
      ];
    }

    if (selected) {
      return [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.34 + (pulse * 0.18)),
          blurRadius: 20,
          spreadRadius: 0.8,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.32),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ];
    }

    switch (intensity) {
      case NeonIntensity.soft:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
      case NeonIntensity.medium:
        return [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.10 + (pulse * 0.08)),
            blurRadius: 10,
            spreadRadius: 0.1,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];
      case NeonIntensity.strong:
        return [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.18 + (pulse * 0.12)),
            blurRadius: 14,
            spreadRadius: 0.35,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ];
    }
  }
}
