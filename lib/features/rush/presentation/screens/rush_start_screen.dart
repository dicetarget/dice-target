// lib/features/rush/presentation/screens/rush_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/rush/data/rush_daily_storage.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:dice/features/rush/presentation/screens/rush_daily_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_screen.dart';
import 'package:flutter/material.dart';

class RushStartScreen extends StatefulWidget {
  const RushStartScreen({super.key});

  @override
  State<RushStartScreen> createState() => _RushStartScreenState();
}

class _RushStartScreenState extends State<RushStartScreen> with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF4CAF82);
  static const Color _muted = Color(0xFF4A5568);

  late final TabController _tabCtrl;
  RushDifficulty _selectedDifficulty = RushDifficulty.easy;

  final RushDailyStorage _dailyStorage = RushDailyStorage();
  RushDailyState? _dailyState;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadDailyState();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDailyState() async {
    final s = await _dailyStorage.load();
    if (mounted) setState(() => _dailyState = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [_buildStandardTab(), _buildDailyTab()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.white.withValues(alpha: 0.60),
            onPressed: () => Navigator.of(context).maybePop(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          const Text(
            'Speed Run',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _green,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: _green.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withValues(alpha: 0.40), width: 0.5),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          labelColor: _green,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.35),
          tabs: const [
            Tab(text: 'Standard'),
            Tab(text: 'Daily'),
          ],
        ),
      ),
    );
  }

  // ── Standard Tab ─────────────────────────────────────────────────────────

  Widget _buildStandardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '90 seconds · as many puzzles as possible',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...RushDifficulty.values.map((d) => _buildDifficultyRow(d)),
          const SizedBox(height: 28),
          _buildRuleChips(),
          const SizedBox(height: 28),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildDifficultyRow(RushDifficulty d) {
    final isSelected = d == _selectedDifficulty;
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _green.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _green.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? _green : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target ${d.targetMin}–${d.targetMax}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: _green, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 14, color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleChips() {
    const rules = ['Undo (max 4)', 'No Hint', 'No Skip', 'Instant Switch'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rules
          .map(
            (r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
              ),
              child: Text(
                r,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RushScreen(difficulty: _selectedDifficulty)));
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_green.withValues(alpha: 0.22), _green.withValues(alpha: 0.10)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _green.withValues(alpha: 0.75), width: 2.0),
          boxShadow: [
            BoxShadow(color: _green.withValues(alpha: 0.32), blurRadius: 28, spreadRadius: 2),
          ],
        ),
        child: const Center(
          child: Text(
            'Start Speed Run',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _green),
          ),
        ),
      ),
    );
  }

  // ── Daily Tab ─────────────────────────────────────────────────────────────

  Widget _buildDailyTab() {
    if (_dailyState == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: _green),
        ),
      );
    }

    final state = _dailyState!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2 min per run · Same puzzles for everyone · Best run counts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          _buildDailyRunCard(runLabel: 'Run 1', score: state.run1, played: state.run1Played),
          const SizedBox(height: 10),
          _buildDailyRunCard(
            runLabel: 'Run 2',
            score: state.run2,
            played: state.run2Played,
            locked: !state.run1Played,
          ),
          const SizedBox(height: 24),
          if (state.bestRunScore >= 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Best',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  Text(
                    '${state.bestRunScore}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (!state.isCompleted) _buildDailyStartButton(state),
        ],
      ),
    );
  }

  Widget _buildDailyRunCard({
    required String runLabel,
    required int score,
    required bool played,
    bool locked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: played ? _green.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              runLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          if (locked)
            Icon(Icons.lock_outline_rounded, size: 18, color: _muted)
          else if (played)
            Text(
              '$score puzzles',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _green),
            )
          else
            Text(
              'Not played',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyStartButton(RushDailyState state) {
    final label = state.canStartRun2 ? 'Start Run 2' : 'Start Run 1';
    final runNumber = state.canStartRun2 ? 2 : 1;
    final run1Score = state.canStartRun2 ? state.run1 : -1;

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RushDailyScreen(runNumber: runNumber, run1Score: run1Score),
          ),
        );
        if (mounted) await _loadDailyState();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_green.withValues(alpha: 0.18), _green.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.12), blurRadius: 16)],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _green),
          ),
        ),
      ),
    );
  }
}
