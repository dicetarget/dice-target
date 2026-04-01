import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static const Color _bg = Color(0xFF090B18);
  static const Color _ink = Color(0xFFEEEAF6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Rules',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _ink.withAlpha(179),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1F), Color(0xFF05070D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: const _NoStretchScrollBehavior(),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF90D5F0), Color(0xFF3FE8FF)],
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
                  _RulesSectionCard(
                    icon: Icons.flag_rounded,
                    heading: 'Goal',
                    body:
                        'Reach the target number using the dice values.\n'
                        'At the end of the round:\n'
                        '• Exactly one die must remain\n'
                        '• All 5 dice must be used\n'
                        '• The final die value must exactly match the target number',
                  ),
                  const SizedBox(height: 12),
                  _RulesSectionCard(
                    icon: Icons.casino_rounded,
                    heading: 'Game Start',
                    body:
                        'At the start of each round:\n'
                        '• A target number is generated\n'
                        '• Five dice are rolled, each showing 1–6\n\n'
                        'Modes:\n'
                        '• Free Play: target range 1–120\n'
                        '• Some puzzles may be impossible\n'
                        '• Training: choose difficulty with custom target ranges\n\n'
                        'Training ranges:\n'
                        '• Easy: 10–40  •  Medium: 30–70\n'
                        '• Hard: 50–100  •  Expert: 80–120',
                  ),
                  const SizedBox(height: 12),
                  _RulesSectionCard(
                    icon: Icons.functions_rounded,
                    heading: 'Core Gameplay',
                    body:
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
                        '• Invalid moves are rejected',
                  ),
                  const SizedBox(height: 12),
                  _RulesSectionCard(
                    icon: Icons.calendar_today_rounded,
                    heading: 'Daily Mode',
                    body:
                        '• 5 puzzles per day — one scored run only\n'
                        '• 1 Hint available before your first move\n'
                        '• Using a hint blocks a 3★ perfect run\n'
                        '• Practice unlocks after giving up\n'
                        '• Perfect run requires optimal move count\n'
                        '• New daily every midnight',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
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
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

class _RulesSectionCard extends StatelessWidget {
  const _RulesSectionCard({required this.icon, required this.heading, required this.body});

  final IconData icon;
  final String heading;
  final String body;

  static const Color _cyan = Color(0xFF3FE8FF);
  static const Color _cyanLt = Color(0xFF90D5F0);
  static const Color _ink = Color(0xFFEEEAF6);
  static const Color _card = Color(0xFF0F1C2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.18), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 10,
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
                  color: _cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cyan.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Icon(icon, color: _cyanLt, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
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
              fontWeight: FontWeight.w500,
              color: _ink.withValues(alpha: 0.80),
            ),
          ),
        ],
      ),
    );
  }
}
