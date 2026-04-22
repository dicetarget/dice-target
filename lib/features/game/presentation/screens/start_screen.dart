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
import 'package:dice/features/vs/presentation/screens/vs_home_screen.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _muted = Color(0xFF6B8CAE);

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
      if (!mounted) return;
      setState(() => _isOpeningDaily = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1F), Color(0xFF05070D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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

                        // ── Speed Run — stärkstes Element ──────────────
                        _buildSpeedRunButton(),
                        const SizedBox(height: 14),

                        // ── Daily Challenge — mittlere Stärke ──────────
                        _buildDailyButton(),
                        const SizedBox(height: 14),

                        // ── VS Mode ────────────────────────────────────
                        _buildVsButton(),
                        const SizedBox(height: 14),

                        // ── Free Play — schwächstes Element ───────────
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
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF8DC), Color(0xFFFFD700), Color(0xFFB8860B)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(bounds),
      child: Text(
        'Dice Target',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: Colors.white,
          shadows: [
            Shadow(color: _gold.withValues(alpha: 0.55), blurRadius: 20),
            Shadow(color: _amber.withValues(alpha: 0.20), blurRadius: 36),
          ],
        ),
      ),
    );
  }

  // ── Speed Run — stärkster Glow, stärkster Border, größte Schrift ──────────
  Widget _buildSpeedRunButton() {
    return _NeonButton(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RushStartScreen())),
      label: 'Rush',
      sublabel: '90 seconds · Solve as many as you can',
      glowColor: _cyan,
      borderColor: _cyan.withValues(alpha: 1.0),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_cyan.withValues(alpha: 0.12), _cyan.withValues(alpha: 0.05)],
      ),
      labelColor: Colors.white,
      sublabelColor: _cyan.withValues(alpha: 0.90),
      glowAlpha: 0.45,
      glowBlur: 30,
      borderWidth: 2.0,
      labelSize: 28,
    );
  }

  // ── Daily — calmer, secondary to Speed Run ────────────────────────────────
  Widget _buildDailyButton() {
    return _NeonButton(
      onPressed: _isOpeningDaily ? null : _openDaily,
      label: _isOpeningDaily ? 'Preparing...' : 'Daily Challenge',
      sublabel: _isOpeningDaily ? '' : '5 puzzles · Fewest moves wins',
      glowColor: _amber,
      borderColor: _amber.withValues(alpha: 0.75),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_amber.withValues(alpha: 0.04), _amber.withValues(alpha: 0.01)],
      ),
      labelColor: Colors.white,
      sublabelColor: _amber.withValues(alpha: 0.85),
      glowAlpha: 0.25,
      glowBlur: 18,
      borderWidth: 1.5,
      labelSize: 22,
      isLoading: _isOpeningDaily,
    );
  }

  Widget _buildVsButton() {
    return _NeonButton(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VsHomeScreen())),
      label: 'VS',
      sublabel: 'Play against a friend',
      glowColor: _cyan,
      borderColor: _cyan.withValues(alpha: 0.60),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_cyan.withValues(alpha: 0.04), _cyan.withValues(alpha: 0.01)],
      ),
      labelColor: Colors.white,
      sublabelColor: _cyan.withValues(alpha: 0.70),
      glowAlpha: 0.18,
      glowBlur: 16,
      borderWidth: 1.5,
      labelSize: 24,
    );
  }

  // ── Free Play — schwächstes Element ──────────────────────────────────────
  Widget _buildFreePlayButton() {
    return _NeonButton(
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FreePlayStartScreen())),
      label: 'Free Play',
      sublabel: 'Play without limits',
      glowColor: _amber,
      borderColor: _amber.withValues(alpha: 0.30),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_amber.withValues(alpha: 0.03), _amber.withValues(alpha: 0.01)],
      ),
      labelColor: Colors.white,
      sublabelColor: Colors.white.withValues(alpha: 0.45),
      glowAlpha: 0.08,
      glowBlur: 10,
      borderWidth: 0.5,
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
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'How to Play',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _NeonButton ───────────────────────────────────────────────────────────────

class _NeonButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final String sublabel;
  final Color glowColor;
  final Color borderColor;
  final LinearGradient bgGradient;
  final Color labelColor;
  final Color sublabelColor;
  final double glowAlpha;
  final double glowBlur;
  final double borderWidth;
  final double labelSize;
  final bool isLoading;

  const _NeonButton({
    required this.onPressed,
    required this.label,
    required this.sublabel,
    required this.glowColor,
    required this.borderColor,
    required this.bgGradient,
    required this.labelColor,
    required this.sublabelColor,
    required this.glowAlpha,
    required this.glowBlur,
    required this.borderWidth,
    required this.labelSize,
    this.isLoading = false,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> {
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: enabled
                  ? widget.bgGradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled ? widget.borderColor : Colors.white.withValues(alpha: 0.08),
                width: widget.borderWidth,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: widget.glowAlpha),
                        blurRadius: widget.glowBlur,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: widget.labelColor),
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
                          shadows: enabled
                              ? [
                                  Shadow(
                                    color: widget.glowColor.withValues(
                                      alpha: widget.glowAlpha * 1.2,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
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
    );
  }
}
