// lib/features/rush/presentation/screens/rush_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/presentation/screens/rush_screen.dart';
import 'package:flutter/material.dart';

class RushStartScreen extends StatefulWidget {
  const RushStartScreen({super.key});

  @override
  State<RushStartScreen> createState() => _RushStartScreenState();
}

class _RushStartScreenState extends State<RushStartScreen>
    with SingleTickerProviderStateMixin {
  int? _globalBest;
  int _todayBest = 0;
  bool _loaded = false;
  bool _isStarting = false;

  final RushHighscoreStorage _storage = RushHighscoreStorage();

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final best = await _storage.loadGlobalBest();
    final todayBest = await _storage.loadTodayBest();
    if (!mounted) return;
    setState(() {
      _globalBest = best;
      _todayBest = todayBest;
      _loaded = true;
    });
  }

  Future<void> _startRun() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    final pb = _globalBest ?? 0;
    if (!mounted) return;
    setState(() => _isStarting = false);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RushScreen(personalBest: pb)),
    );
    if (mounted) await _loadBest();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Spacer(),
            _buildStats(),
            const SizedBox(height: 32),
            _buildStages(),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
              child: _buildStartButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.inkMuted,
            onPressed: () => Navigator.of(context).maybePop(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rush',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5A9E6F),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '90 seconds · Solve as many as you can',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final allTimeDisplay = (_globalBest == null || _globalBest! <= 0) ? '--' : '$_globalBest';
    final todayDisplay = _todayBest == 0 ? '--' : '$_todayBest';

    return Center(
      child: !_loaded
          ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF5A9E6F)),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatColumn(allTimeDisplay, 'all-time best'),
                Container(
                  width: 1,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  color: AppColors.inkFaint,
                ),
                _buildStatColumn(todayDisplay, "today's best"),
              ],
            ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    final hasValue = value != '--';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: hasValue ? const Color(0xFF5A9E6F) : AppColors.inkFaint,
            letterSpacing: -2,
            height: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
        ),
      ],
    );
  }

  Widget _buildStages() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Difficulty increases automatically',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.inkMuted, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStartButton() {
    return TactileButton(
      variant: TactileButtonVariant.green,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      borderRadius: BorderRadius.circular(16),
      onPressed: _isStarting ? null : _startRun,
      child: _isStarting
          ? const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.dicePip),
                ),
              ),
            )
          : const Text(
              'Start Rush',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
    );
  }
}
