import 'package:flutter/material.dart';

import 'practice_screen.dart';
import 'rules_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dice Target')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _NavButton(
              label: 'Practice',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PracticeScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // Coming soon - disabled
            _NavButton(
              label: 'Friends (Coming soon)',
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: 12),

            // Coming soon - disabled
            _NavButton(
              label: 'Ranked (Coming soon)',
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: 12),

            _NavButton(
              label: 'Rules',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RulesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _NavButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
