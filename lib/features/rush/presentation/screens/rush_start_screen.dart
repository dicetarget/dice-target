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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBestCard(),
                        const SizedBox(height: 20),
                        _buildStagesCard(),
                        const SizedBox(height: 20),
                        _buildInfoChips(),
                        const SizedBox(height: 28),
                        _buildStartButton(),
                      ],
                    ),
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

  Widget _buildBestCard() {
    final hasBest = _globalBest != null && _globalBest! > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1018),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasBest ? _green.withValues(alpha: 0.60) : _green.withValues(alpha: 0.22),
          width: hasBest ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: hasBest ? 0.20 : 0.06),
            blurRadius: hasBest ? 40 : 16,
            spreadRadius: hasBest ? 4 : 1,
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
                  'ALL-TIME BEST',
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
          if (!_loaded)
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
          else if (hasBest) ...[
            Text(
              'Best',
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
                  '$_globalBest',
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
              'No score yet',
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

  Widget _buildStagesCard() {
    const stages = [
      (label: 'Stage 1', range: '20–40', detail: 'puzzles 1–5'),
      (label: 'Stage 2', range: '30–60', detail: 'puzzles 6–12'),
      (label: 'Stage 3', range: '50–90', detail: 'puzzle 13+'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUTO DIFFICULTY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.30),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...stages.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _green.withValues(alpha: 0.25), width: 0.5),
                    ),
                    child: Text(
                      s.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Target ${s.range}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${s.detail}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips() {
    const info = ['90 seconds', 'Undo (max 4)', 'Auto difficulty'];
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

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _isStarting ? null : _startRun,
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
          child: _isStarting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _green),
                )
              : const Text(
                  'Start Speed Run',
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
}
