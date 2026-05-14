import 'package:flutter/material.dart';

class MenuCard extends StatefulWidget {
  final String title;
  final String subtitle;
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
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        transform: _pressed
            ? (Matrix4.identity()..scaleByDouble(0.96, 0.96, 1.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors,
            stops: widget.gradientStops,
          ),
          border: Border.all(
            color: widget.borderColor.withValues(alpha: 0.45),
            width: 1.0,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.borderColor.withValues(alpha: 0.50),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.titleColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: widget.subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: widget.borderColor.withValues(alpha: 0.70),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
