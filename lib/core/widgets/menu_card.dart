import 'package:flutter/material.dart';

class MenuCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? sublabel;
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Color glowColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  const MenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.sublabel,
    required this.icon,
    this.onTap,
    required this.gradientColors,
    required this.gradientStops,
    required this.glowColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      } : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        transform: _pressed
            ? (Matrix4.identity()
                ..translateByDouble(0.0, 2.0, 0.0, 1.0)
                ..scaleByDouble(0.97, 0.97, 1.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors,
            stops: widget.gradientStops,
          ),
          border: Border.all(
            color: widget.borderColor.withValues(
              alpha: _pressed ? 0.15 : 0.28,
            ),
            width: 0.8,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.75),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.07),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.47),
                    blurRadius: 21,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.18),
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              // Top edge highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: _pressed ? 0.04 : 0.13),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Bottom edge shadow
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.40),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Press overlay
              if (_pressed)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.14),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.iconBgColor.withValues(alpha: 0.95),
                            widget.iconBgColor,
                            widget.iconBgColor.withValues(alpha: 0.80),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        border: Border.all(
                          color: widget.borderColor.withValues(alpha: 0.32),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.04),
                            blurRadius: 0,
                            offset: const Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.sublabel != null) ...[
                            Text(
                              widget.sublabel!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                                color: widget.titleColor.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: widget.titleColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: widget.subtitleColor.withValues(alpha: 0.80),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.titleColor.withValues(alpha: 0.35),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
