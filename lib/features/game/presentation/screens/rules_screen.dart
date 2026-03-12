import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  // Match your app look (Start/Practice)
  static const Color _ink = Color(0xFF1D1B20);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          foregroundColor: _ink,
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: IconThemeData(color: _ink),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Rules'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F3F9), Color(0xFFF2EAF4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ScrollConfiguration(
              behavior: const _NoStretchScrollBehavior(),
              child: const SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 10, 16, 18),
                child: _RulesContent(),
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
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _RulesContent extends StatelessWidget {
  const _RulesContent();

  static const Color _ink = Color(0xFF1D1B20);

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w900,
      color: _ink,
      letterSpacing: 0.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(height: 6),
        Text('Dice Target', style: titleStyle),
        SizedBox(height: 14),
        _RulesSectionCard(
          icon: Icons.flag_rounded,
          heading: 'Goal',
          body:
              'Reach the target number using the dice values.\n'
              'At the end of the game:\n'
              '• Exactly one die must remain\n'
              '• Its value must be exactly equal to the target number',
        ),
        SizedBox(height: 14),
        _RulesSectionCard(
          icon: Icons.casino_rounded,
          heading: 'Game Start',
          body:
              'At the start of each round:\n'
              '• Five dice are rolled, each showing a value from 1 to 6\n'
              '• A target number is generated based on the selected difficulty\n\n'
              'Target ranges:\n'
              '• Easy: 1–50\n'
              '• Medium: 1–100\n'
              '• Hard: 1–150',
        ),
        SizedBox(height: 14),
        _RulesSectionCard(
          icon: Icons.functions_rounded,
          heading: 'Core Gameplay',
          body:
              'Select at least two dice (2 to n).\n'
              'Choose one operation:\n'
              '• Addition (+)\n'
              '• Subtraction (−)\n'
              '• Multiplication (×)\n'
              '• Division (÷)\n\n'
              'The selected dice are merged into a single new die:\n'
              '• All selected dice are removed\n'
              '• The resulting value becomes one new die\n'
              '• This new die remains visible and can be used again\n\n'
              'Order rule:\n'
              '• Selected values are sorted descending and reduced left → right:\n'
              '  ((v1 op v2) op v3) ...\n\n'
              'Validity:\n'
              '• + and × are always valid\n'
              '• − and ÷: per step, direction is chosen automatically\n'
              '  (no negative intermediate results; division only without remainder)\n'
              '• Invalid moves are not executed',
        ),
        SizedBox(height: 8),
      ],
    );
  }
}

class _RulesSectionCard extends StatelessWidget {
  const _RulesSectionCard({
    required this.icon,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final String heading;
  final String body;

  static const Color _accent = Color(0xFF6E5AAE);
  static const Color _ink = Color(0xFF1D1B20);
  static const Color _card = Color(0xFFF1E9F0);

  @override
  Widget build(BuildContext context) {
    const hStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      color: _ink,
    );

    const bStyle = TextStyle(
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: _ink,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
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
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(heading, style: hStyle),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: bStyle),
        ],
      ),
    );
  }
}
