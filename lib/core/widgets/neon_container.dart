import 'package:flutter/material.dart';

enum NeonIntensity { soft, medium, strong }

class NeonContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  final Color glowColor;
  final Color? borderColor;
  final Color? backgroundColor;

  final NeonIntensity intensity;
  final bool selected;
  final bool enabled;

  final double borderWidth;
  final double? width;
  final double? height;

  final Gradient? backgroundGradient;
  final Gradient? innerHighlightGradient;
  final List<BoxShadow>? customShadows;

  const NeonContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.intensity = NeonIntensity.medium,
    this.selected = false,
    this.enabled = true,
    this.borderWidth = 1.0,
    this.width,
    this.height,
    this.backgroundGradient,
    this.innerHighlightGradient,
    this.customShadows,
  });

  const NeonContainer.soft({
    super.key,
    required this.child,
    required this.glowColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.selected = false,
    this.enabled = true,
    this.borderWidth = 1.0,
    this.width,
    this.height,
    this.backgroundGradient,
    this.innerHighlightGradient,
    this.customShadows,
  }) : intensity = NeonIntensity.soft;

  const NeonContainer.medium({
    super.key,
    required this.child,
    required this.glowColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.selected = false,
    this.enabled = true,
    this.borderWidth = 1.0,
    this.width,
    this.height,
    this.backgroundGradient,
    this.innerHighlightGradient,
    this.customShadows,
  }) : intensity = NeonIntensity.medium;

  const NeonContainer.strong({
    super.key,
    required this.child,
    required this.glowColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.selected = false,
    this.enabled = true,
    this.borderWidth = 1.0,
    this.width,
    this.height,
    this.backgroundGradient,
    this.innerHighlightGradient,
    this.customShadows,
  }) : intensity = NeonIntensity.strong;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final resolvedBorderColor = borderColor ?? glowColor;
    final resolvedBackgroundGradient =
        backgroundGradient ?? _defaultBackgroundGradient(glowColor: glowColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        gradient: resolvedBackgroundGradient,
        border: Border.all(
          color: _resolvedBorderColor(base: resolvedBorderColor),
          width: _resolvedBorderWidth(),
        ),
        boxShadow: customShadows ?? _buildOuterShadows(),
      ),
      child: ClipRRect(
        borderRadius: _innerRadius(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient:
                        innerHighlightGradient ??
                        _defaultInnerHighlightGradient(selected: selected, enabled: enabled),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: _innerRadius(radius),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: enabled ? 0.32 : 0.12),
                        width: 0.9,
                      ),
                    ),
                  ),
                ),
              ),
            if (enabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.08,
                        colors: [
                          glowColor.withValues(alpha: _radialGlowAlpha()),
                          Colors.transparent,
                        ],
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

  BorderRadius _innerRadius(BorderRadius outer) {
    return BorderRadius.only(
      topLeft: Radius.circular((outer.topLeft.x - 4).clamp(0, 999)),
      topRight: Radius.circular((outer.topRight.x - 4).clamp(0, 999)),
      bottomLeft: Radius.circular((outer.bottomLeft.x - 4).clamp(0, 999)),
      bottomRight: Radius.circular((outer.bottomRight.x - 4).clamp(0, 999)),
    );
  }

  Gradient _defaultBackgroundGradient({required Color glowColor}) {
    if (!enabled) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.04)],
      );
    }

    if (selected) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withValues(alpha: 0.28), glowColor.withValues(alpha: 0.20)],
      );
    }

    switch (intensity) {
      case NeonIntensity.soft:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.04)],
        );
      case NeonIntensity.medium:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.16), glowColor.withValues(alpha: 0.10)],
        );
      case NeonIntensity.strong:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.20), glowColor.withValues(alpha: 0.16)],
        );
    }
  }

  Gradient _defaultInnerHighlightGradient({required bool selected, required bool enabled}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: enabled ? (selected ? 0.14 : 0.07) : 0.04),
        Colors.transparent,
      ],
    );
  }

  Color _resolvedBorderColor({required Color base}) {
    if (!enabled) return Colors.white.withValues(alpha: 0.10);
    if (selected) return base.withValues(alpha: 0.82);

    switch (intensity) {
      case NeonIntensity.soft:
        return base.withValues(alpha: 0.18);
      case NeonIntensity.medium:
        return base.withValues(alpha: 0.34);
      case NeonIntensity.strong:
        return base.withValues(alpha: 0.54);
    }
  }

  double _resolvedBorderWidth() {
    if (selected) return borderWidth + 1.2;
    if (!enabled) return borderWidth;

    switch (intensity) {
      case NeonIntensity.soft:
        return borderWidth;
      case NeonIntensity.medium:
        return borderWidth + 0.2;
      case NeonIntensity.strong:
        return borderWidth + 0.5;
    }
  }

  double _radialGlowAlpha() {
    if (!enabled) return 0.0;
    if (selected) return 0.14;

    switch (intensity) {
      case NeonIntensity.soft:
        return 0.04;
      case NeonIntensity.medium:
        return 0.08;
      case NeonIntensity.strong:
        return 0.12;
    }
  }

  List<BoxShadow> _buildOuterShadows() {
    if (!enabled) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    }

    if (selected) {
      return [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.55),
          blurRadius: 14,
          spreadRadius: 1.6,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: glowColor.withValues(alpha: 0.25),
          blurRadius: 22,
          spreadRadius: 2.2,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: glowColor.withValues(alpha: 0.24),
          blurRadius: 26,
          spreadRadius: 0.6,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.34),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.18),
          blurRadius: 0,
          spreadRadius: -2,
          offset: const Offset(0, -2),
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
            color: glowColor.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 0.2,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 0,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ];
      case NeonIntensity.strong:
        return [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.24),
            blurRadius: 14,
            spreadRadius: 0.8,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: 1.2,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.10),
            blurRadius: 0,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ];
    }
  }
}
