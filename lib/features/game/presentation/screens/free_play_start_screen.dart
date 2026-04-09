// lib/features/game/presentation/screens/free_play_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/game/presentation/screens/practice_screen.dart';
import 'package:flutter/material.dart';

enum _Tab { free, training }

class FreePlayStartScreen extends StatefulWidget {
  const FreePlayStartScreen({super.key});

  @override
  State<FreePlayStartScreen> createState() => _FreePlayStartScreenState();
}

class _FreePlayStartScreenState extends State<FreePlayStartScreen> {
  static const Color _amber = Color(0xFFD4AC0D);
  static const Color _amberLt = Color(0xFFFFF0A0);

  _Tab _tab = _Tab.free;

  Future<void> _start() async {
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Free Play',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildTabSwitcher(),
              const SizedBox(height: 20),
              Expanded(child: _tab == _Tab.free ? _buildFreeContent() : _buildTrainingContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _TabBtn(
            label: 'Free',
            active: _tab == _Tab.free,
            amber: _amber,
            onTap: () => setState(() => _tab = _Tab.free),
          ),
          _TabBtn(
            label: 'Training',
            active: _tab == _Tab.training,
            amber: _amber,
            onTap: () => setState(() => _tab = _Tab.training),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(
                  title: 'Free',
                  subtitle: 'Unlimited puzzles · No pressure · Your pace',
                ),
                const SizedBox(height: 12),
                _buildFormatCard([
                  _FreeFormatRow(icon: Icons.all_inclusive_rounded, text: 'Unlimited puzzles'),
                  SizedBox(height: 10),
                  _FreeFormatRow(icon: Icons.timer_off_outlined, text: 'No timer'),
                  SizedBox(height: 10),
                  _FreeFormatRow(
                    icon: Icons.lightbulb_outline_rounded,
                    text: 'Show Solution available',
                  ),
                  SizedBox(height: 10),
                  _FreeFormatRow(icon: Icons.undo_rounded, text: 'Unlimited undo'),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(label: 'Start Free Play', onTap: _start, amber: _amber),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTrainingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(
                  title: 'Training',
                  subtitle: 'Focus on a difficulty · Sharpen your skills',
                ),
                const SizedBox(height: 12),
                _buildDifficultyInfoCard(),
                const SizedBox(height: 12),
                _buildFormatCard([
                  _FreeFormatRow(
                    icon: Icons.tune_rounded,
                    text: 'Focused target range per difficulty',
                  ),
                  SizedBox(height: 10),
                  _FreeFormatRow(icon: Icons.timer_off_outlined, text: 'No timer'),
                  SizedBox(height: 10),
                  _FreeFormatRow(
                    icon: Icons.lightbulb_outline_rounded,
                    text: 'Show Solution available',
                  ),
                  SizedBox(height: 10),
                  _FreeFormatRow(icon: Icons.undo_rounded, text: 'Unlimited undo'),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(label: 'Start Training', onTap: _start, amber: _amber),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _amber,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _buildDifficultyInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIFFICULTY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              color: Colors.white.withValues(alpha: 0.30),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DifficultyChip(label: 'Easy', range: '10-40', amber: _amber, amberLt: _amberLt),
              const SizedBox(width: 8),
              _DifficultyChip(label: 'Medium', range: '30-70', amber: _amber, amberLt: _amberLt),
              const SizedBox(width: 8),
              _DifficultyChip(label: 'Hard', range: '50-100', amber: _amber, amberLt: _amberLt),
              const SizedBox(width: 8),
              _DifficultyChip(label: 'Expert', range: '80-120', amber: _amber, amberLt: _amberLt),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Select difficulty inside the game.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color amber;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.active,
    required this.amber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? amber.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? amber.withValues(alpha: 0.55) : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color amber;
  const _ActionButton({required this.label, required this.onTap, required this.amber});

  @override
  Widget build(BuildContext context) {
    final en = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: en
                ? [amber.withValues(alpha: 0.28), amber.withValues(alpha: 0.13)]
                : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: en ? amber.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.10),
            width: 1.5,
          ),
          boxShadow: en
              ? [BoxShadow(color: amber.withValues(alpha: 0.22), blurRadius: 20, spreadRadius: 1)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: en ? Colors.white : Colors.white30,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeFormatRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FreeFormatRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD4AC0D)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final String range;
  final Color amber;
  final Color amberLt;

  const _DifficultyChip({
    required this.label,
    required this.range,
    required this.amber,
    required this.amberLt,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.60),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
