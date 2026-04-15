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

class _RushStartScreenState extends State<RushStartScreen>
    with SingleTickerProviderStateMixin {
  static const Color _neon = Color(0xFF00FF88);
  static const Color _dark = Color(0xFF090B18);

  int? _globalBest;
  bool _loaded = false;
  bool _isStarting = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  final RushHighscoreStorage _storage = RushHighscoreStorage();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadBest();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
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
                Expanded(child: _buildCenter()),
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
            'Rush',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _neon,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenter() {
    final hasBest = _globalBest != null && _globalBest! > 0;
    final displayValue = (!_loaded || !hasBest) ? '--' : '$_globalBest';

    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radial glow behind the number
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _neon.withValues(alpha: 0.15),
                    _neon.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            // Content column on top of glow
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_loaded)
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _neon.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: hasBest ? _neon : _neon.withValues(alpha: 0.18),
                      letterSpacing: -4,
                      height: 0.9,
                      shadows: hasBest
                          ? [
                              Shadow(
                                color: _neon.withValues(alpha: 0.5),
                                blurRadius: 24,
                              ),
                            ]
                          : null,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'puzzles solved',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _neon.withValues(alpha: 0.6),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isStarting ? null : _startRun,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: _neon,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _neon.withValues(alpha: _pulseAnim.value),
                  blurRadius: 32,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: _neon.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Center(
        child: _isStarting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: _dark),
              )
            : const Text(
                'Start Rush',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                  letterSpacing: -0.3,
                ),
              ),
      ),
    );
  }
}
