// lib/features/rush/presentation/screens/rush_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/presentation/screens/rush_screen.dart';
import 'package:flutter/material.dart';

class RushStartScreen extends StatefulWidget {
  const RushStartScreen({super.key});

  @override
  State<RushStartScreen> createState() => _RushStartScreenState();
}

class _RushStartScreenState extends State<RushStartScreen> {
  static const Color _green = Color(0xFF4CAF82);
  static const Color _cyan = Color(0xFF3FE8FF);
  static const Color _dark = Color(0xFF090B18);

  int? _globalBest;
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
    if (!mounted) return;
    setState(() {
      _globalBest = best;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildBestCard(),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
                  child: _buildStartButton(),
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

  Widget _buildBestCard() {
    final hasBest = _globalBest != null && _globalBest! > 0;
    final displayValue = (!_loaded || !hasBest) ? '--' : '$_globalBest';

    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1018),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hasBest ? _cyan.withValues(alpha: 0.55) : _cyan.withValues(alpha: 0.15),
          width: hasBest ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: hasBest ? 0.18 : 0.04),
            blurRadius: hasBest ? 52 : 16,
            spreadRadius: hasBest ? 6 : 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cyan.withValues(alpha: 0.25), width: 0.5),
            ),
            child: const Text(
              'ALL-TIME BEST',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _cyan,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_loaded)
            const SizedBox(
              height: 96,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.5, color: _cyan),
              ),
            )
          else
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.w900,
                color: hasBest ? _cyan : _cyan.withValues(alpha: 0.18),
                letterSpacing: -4,
                height: 0.9,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'puzzles solved',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: hasBest ? _cyan.withValues(alpha: 0.60) : _cyan.withValues(alpha: 0.18),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _isStarting ? null : _startRun,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: _cyan,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _cyan.withValues(alpha: 0.35), blurRadius: 32, spreadRadius: 3),
            BoxShadow(color: _cyan.withValues(alpha: 0.15), blurRadius: 8),
          ],
        ),
        child: Center(
          child: _isStarting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _dark),
                )
              : const Text(
                  'Start Speed Run',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
