import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Einheitlicher Header für alle Mode-Screens.
/// Back-Button links, optionaler Sound-Button rechts,
/// Titel + optionale Subtitle darunter (links, eingerückt).
class ModeScreenHeader extends StatelessWidget {
  final String title;
  final Color titleColor;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showSound;
  final VoidCallback? onSoundToggle;
  final Widget? trailing;

  const ModeScreenHeader({
    super.key,
    required this.title,
    required this.titleColor,
    this.subtitle,
    this.onBack,
    this.showSound = false,
    this.onSoundToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.inkMuted,
              enableFeedback: false,
              padding: EdgeInsets.zero,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
            ),
            if (showSound)
              StatefulBuilder(
                builder: (context, setState) => IconButton(
                  icon: Icon(
                    sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 22,
                  ),
                  color: AppColors.inkMuted,
                  enableFeedback: false,
                  onPressed: () async {
                    await sfx.toggle();
                    if (onSoundToggle != null) onSoundToggle!();
                    setState(() {});
                  },
                ),
              )
            else if (trailing != null)
              trailing!,
          ],
        ),
        if (subtitle != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
