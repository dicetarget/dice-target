// lib/features/rush/presentation/screens/rush_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
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
  static const Color _gold = Color(0xFFFFD700);

  // Highscore-Modus: fixer Range 20–80
  static const int _hsTargetMin = 20;
  static const int _hsTargetMax = 80;

  late final TabController _tabCtrl;

  // Highscore Tab
  int? _todayHighscore;
  bool _highscoreLoaded = false;
  bool _isStartingHighscore = false;

  // Standard Tab
  RushDifficulty _selectedDifficulty = RushDifficulty.easy;
  bool _isStartingStandard = false;

  final RushHighscoreStorage _storage = RushHighscoreStorage();

  @override
  void initState() {
    super.initState();
    // Tab 0 = Highscore, Tab 1 = Standard
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 0 && !_tabCtrl.indexIsChanging) {
        _loadHighscore();
      }
    });
    _loadHighscore();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHighscore() async {
    final score = await _storage.loadTodayHighscore();
    if (!mounted) return;
    setState(() {
      _todayHighscore = score;
      _highscoreLoaded = true;
    });
  }

  Future<void> _startHighscoreRun() async {
    if (_isStartingHighscore) return;
    setState(() => _isStartingHighscore = true);

    final pb = _todayHighscore ?? 0;

    if (!mounted) return;
    setState(() => _isStartingHighscore = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RushScreen(
          difficulty: RushDifficulty.easy, // Placeholder, wird durch forced override
          personalBest: pb,
          isHighscoreMode: true,
          forcedTargetMin: _hsTargetMin,
          forcedTargetMax: _hsTargetMax,
        ),
      ),
    );

    if (mounted) await _loadHighscore();
  }

  Future<void> _startStandardRun() async {
    if (_isStartingStandard) return;
    setState(() => _isStartingStandard = true);

    final pb = await _storage.loadTodayBest(_selectedDifficulty) ?? 0;

    if (!mounted) return;
    setState(() => _isStartingStandard = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RushScreen(difficulty: _selectedDifficulty, personalBest: pb),
      ),
    );
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
                    children: [_buildHighscoreTab(), _buildStandardTab()],
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
            Tab(text: 'Highscore'),
            Tab(text: 'Standard'),
          ],
        ),
      ),
    );
  }

  // ── Highscore Tab ─────────────────────────────────────────────────────────

  Widget _buildHighscoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero-Card: heutiger Best
          _buildHighscoreHeroCard(),
          const SizedBox(height: 20),
          // Info-Chips
          _buildHighscoreInfoChips(),
          const SizedBox(height: 28),
          // Start Button
          _buildHighscoreStartButton(),
          const SizedBox(height: 16),
          _buildHighscoreFooter(),
        ],
      ),
    );
  }

  Widget _buildHighscoreHeroCard() {
    final hasScore = _todayHighscore != null && _todayHighscore! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1018),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasScore ? _green.withValues(alpha: 0.60) : _green.withValues(alpha: 0.22),
          width: hasScore ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: hasScore ? 0.20 : 0.06),
            blurRadius: hasScore ? 40 : 16,
            spreadRadius: hasScore ? 4 : 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.35), width: 0.5),
                ),
                child: const Text(
                  'TARGET 20–80',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _green,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              const Text('🏆', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 20),
          if (!_highscoreLoaded)
            const SizedBox(
              height: 60,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _green),
                ),
              ),
            )
          else if (hasScore) ...[
            Text(
              'Today\'s Best',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.40),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_todayHighscore}',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -3,
                    height: 0.9,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'puzzles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _green.withValues(alpha: 0.80),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No score yet today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start your first run!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighscoreInfoChips() {
    const info = ['90 seconds', 'Target 20–80'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: info
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

  Widget _buildHighscoreStartButton() {
    return GestureDetector(
      onTap: _isStartingHighscore ? null : _startHighscoreRun,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_green.withValues(alpha: 0.28), _green.withValues(alpha: 0.12)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withValues(alpha: 0.80), width: 2.0),
          boxShadow: [
            BoxShadow(color: _green.withValues(alpha: 0.40), blurRadius: 32, spreadRadius: 3),
            BoxShadow(color: _green.withValues(alpha: 0.15), blurRadius: 8),
          ],
        ),
        child: Center(
          child: _isStartingHighscore
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _green),
                )
              : const Text(
                  'Start Highscore Run',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _green,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHighscoreFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withValues(alpha: 0.20)),
        const SizedBox(width: 6),
        Text(
          'Score resets daily at midnight',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.20),
          ),
        ),
      ],
    );
  }

  // ── Standard Tab ─────────────────────────────────────────────────────────────

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
            'DIFFICULTY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.30),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...RushDifficulty.values.map(_buildDifficultyRow),
          const SizedBox(height: 24),
          _buildRuleChips(),
          const SizedBox(height: 28),
          _buildStandardStartButton(),
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
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 14, color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleChips() {
    const rules = ['Undo (max 4)', 'Skip (1×)', 'Hint (1×)', 'Instant Switch'];
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

  Widget _buildStandardStartButton() {
    return GestureDetector(
      onTap: _isStartingStandard ? null : _startStandardRun,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_green.withValues(alpha: 0.18), _green.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _green.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.18), blurRadius: 20)],
        ),
        child: Center(
          child: _isStartingStandard
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _green),
                )
              : const Text(
                  'Start Speed Run',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _green),
                ),
        ),
      ),
    );
  }
}
