import 'dart:ui';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/features/daily/data/daily_local_storage.dart';
import 'package:dice/features/daily/data/daily_repository.dart';
import 'package:dice/features/daily/domain/daily_service.dart';
import 'package:dice/features/daily/presentation/controllers/daily_controller.dart';
import 'package:dice/features/daily/presentation/screens/daily_screen.dart';
import 'package:dice/features/game/presentation/screens/free_play_start_screen.dart';
import 'package:dice/features/game/presentation/screens/rules_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_start_screen.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  DailyController? _dailyController;
  bool _isOpeningDaily = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<double>(
      begin: 24,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  DailyController _createDailyController() {
    final coordinator = PuzzleCoordinator(
      generator: PuzzleGenerator(),
      mode: GameMode.daily,
      config: DifficultyConfig.easy,
      baseSeed: 0,
    );
    final repository = DailyRepository(
      service: DailyService(coordinator: coordinator),
      storage: DailyLocalStorage(),
    );
    return DailyController(repository: repository);
  }

  @override
  void dispose() {
    _dailyController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDaily() async {
    if (_isOpeningDaily) return;
    setState(() => _isOpeningDaily = true);
    try {
      final controller = _dailyController ??= _createDailyController();
      if (controller.daily == null || controller.progress == null) {
        await controller.loadToday();
      }
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DailyScreen(controllerOverride: controller)));
    } finally {
      if (mounted) setState(() => _isOpeningDaily = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060818), Color(0xFF030510)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fade,
                  child: AnimatedBuilder(
                    animation: _slide,
                    builder: (context, child) =>
                        Transform.translate(offset: Offset(0, _slide.value), child: child),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            const Spacer(),
                            _buildTitle(),
                            const SizedBox(height: 52),

                            // ── Rush — strongest element ────────────────────
                            _buildSpeedRunButton(),
                            const SizedBox(height: 14),

                            // ── Daily Challenge ─────────────────────────────
                            _buildDailyButton(),
                            const SizedBox(height: 14),

                            // ── Free Play ───────────────────────────────────
                            _buildFreePlayButton(),

                            const Spacer(),
                            _buildRulesButton(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Dice Target',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 54,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: const Color(0xFFFFB300),
        shadows: [
          Shadow(color: const Color(0xFFFFB300).withValues(alpha: 0.40), blurRadius: 40),
          Shadow(color: const Color(0xFFFFB300).withValues(alpha: 0.20), blurRadius: 60),
        ],
      ),
    );
  }

  Widget _buildSpeedRunButton() {
    return _GlassButton(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RushStartScreen())),
      label: 'Rush',
      sublabel: '90 seconds · Endless puzzles',
      glowColor: const Color(0xFF00FF88),
      labelColor: const Color(0xFF00FF88),
      sublabelColor: const Color(0xFF00FF88).withValues(alpha: 0.60),
      labelSize: 28,
    );
  }

  Widget _buildDailyButton() {
    return _GlassButton(
      onPressed: _isOpeningDaily ? null : _openDaily,
      label: _isOpeningDaily ? 'Preparing...' : 'Daily Challenge',
      sublabel: _isOpeningDaily ? '' : 'Solve with the fewest moves',
      glowColor: const Color(0xFF00CFFF),
      labelColor: const Color(0xFF00CFFF),
      sublabelColor: const Color(0xFF00CFFF).withValues(alpha: 0.60),
      labelSize: 22,
      isLoading: _isOpeningDaily,
    );
  }

  Widget _buildFreePlayButton() {
    return _GlassButton(
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FreePlayStartScreen())),
      label: 'Free Play',
      sublabel: 'Unlimited puzzles',
      glowColor: const Color(0xFFFFAA00),
      labelColor: const Color(0xFFFFAA00),
      sublabelColor: const Color(0xFFFFAA00).withValues(alpha: 0.60),
      labelSize: 20,
    );
  }

  Widget _buildRulesButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
            boxShadow: [
              BoxShadow(color: Colors.white.withValues(alpha: 0.10), blurRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              'How to Play',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.50),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dot Pattern Painter ───────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter oldDelegate) => false;
}

// ── _GlassButton ──────────────────────────────────────────────────────────────

class _GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final String sublabel;
  final Color glowColor;
  final Color labelColor;
  final Color sublabelColor;
  final double labelSize;
  final bool isLoading;

  const _GlassButton({
    required this.onPressed,
    required this.label,
    required this.sublabel,
    required this.glowColor,
    required this.labelColor,
    required this.sublabelColor,
    required this.labelSize,
    this.isLoading = false,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = _pressed ? 0.97 : 1.0;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: widget.glowColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: widget.isLoading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.labelColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: widget.labelColor,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: widget.labelSize,
                              fontWeight: FontWeight.w900,
                              color: widget.labelColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (widget.sublabel.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.sublabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.sublabelColor,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
