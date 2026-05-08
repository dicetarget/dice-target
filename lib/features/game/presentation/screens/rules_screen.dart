import 'package:dice/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'How to Play',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.inkMuted,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const _NoStretchScrollBehavior(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE8C96A), Color(0xFFD4AF37), Color(0xFFA88A22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Dice Target',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _RulesSectionCard(icon: Icons.flag_rounded, heading: 'Goal', body:
                  'Reach the target number using the dice values.\n'
                  'At the end of the round:\n'
                  '• Exactly one die must remain\n'
                  '• All 5 dice must be used\n'
                  '• The final die value must exactly match the target number'),
                const SizedBox(height: 12),
                _RulesSectionCard(icon: Icons.casino_rounded, heading: 'Game Start', body:
                  'At the start of each round:\n'
                  '• A target number is generated\n'
                  '• Five dice are rolled, each showing 1–6\n\n'
                  'Modes:\n'
                  '• Free Play: target range 1–120\n'
                  '• Some puzzles may be impossible\n'
                  '• Training: choose difficulty with custom target ranges\n\n'
                  'Training ranges:\n'
                  '• Easy: 10–40  •  Medium: 30–70\n'
                  '• Hard: 50–100  •  Expert: 80–120'),
                const SizedBox(height: 12),
                _RulesSectionCard(icon: Icons.functions_rounded, heading: 'Core Gameplay', body:
                  'Select at least two dice, then choose an operation:\n'
                  '• Addition (+)  •  Subtraction (−)\n'
                  '• Multiplication (×)  •  Division (÷)\n\n'
                  'Selected dice merge into one new die.\n\n'
                  'Order rule:\n'
                  'Values are sorted descending, reduced left → right:\n'
                  '  ((v1 op v2) op v3) ...\n\n'
                  'Validity:\n'
                  '• + and × are always valid\n'
                  '• − and ÷: no negative results; division without remainder only\n'
                  '• Invalid moves are rejected'),
                const SizedBox(height: 12),
                _RulesSectionCard(icon: Icons.calendar_today_rounded, heading: 'Daily Mode', body:
                  '• 5 puzzles per day — one scored run only\n'
                  '• 1 Hint available before your first move\n'
                  '• Using a hint blocks a 3★ perfect run\n'
                  '• Practice unlocks after giving up\n'
                  '• Perfect run requires optimal move count\n'
                  '• New daily every midnight'),
                const SizedBox(height: 12),
                _RulesSectionCard(icon: Icons.bolt_rounded, heading: 'Rush', body:
                  '90 seconds to solve as many puzzles as possible.\n\n'
                  '• Difficulty increases automatically as you progress\n'
                  '• No hints — pure speed and skill\n'
                  '• Your best score is saved automatically'),
                const SizedBox(height: 12),
                _RulesSectionCard(icon: Icons.people_rounded, heading: 'VS Mode', body:
                  'Challenge a friend to a head-to-head match.\n'
                  'Both players use the same seed — fair and equal.\n\n'
                  '⚡ 90s Rush:\n'
                  '• Solve as many puzzles as possible in 90 seconds\n'
                  '• More puzzles solved wins\n'
                  '• Tie: fewest total moves wins\n\n'
                  '🏁 3 Puzzle Speedrun:\n'
                  '• Solve exactly 3 puzzles as fast as possible\n'
                  '• Fastest time wins\n'
                  '• Tie on time: fewest total moves wins\n\n'
                  '🏁 5 Puzzle Speedrun:\n'
                  '• Solve exactly 5 puzzles as fast as possible\n'
                  '• Difficulty increases with each puzzle\n'
                  '• Fastest time wins\n'
                  '• Tie on time: fewest total moves wins\n\n'
                  'Challenges are valid for 7 days.\n'
                  'Play in your own time — no need to be online together.'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoStretchScrollBehavior extends ScrollBehavior {
  const _NoStretchScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

class _RulesSectionCard extends StatelessWidget {
  const _RulesSectionCard({required this.icon, required this.heading, required this.body});

  final IconData icon;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.20), width: 0.5),
                ),
                child: Icon(icon, color: AppColors.goldLight, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w400,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
