import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/features/daily/data/daily_local_storage.dart';
import 'package:dice/features/daily/data/daily_repository.dart';
import 'package:dice/features/daily/domain/daily_service.dart';
import 'package:dice/features/daily/presentation/controllers/daily_controller.dart';
import 'package:dice/features/daily/presentation/screens/daily_screen.dart';
import 'package:dice/features/game/presentation/screens/practice_screen.dart';
import 'package:dice/features/game/presentation/screens/rules_screen.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  static const Color _cyan = Color(0xFF3FE8FF);
  static const Color _cyanLt = Color(0xFFE0FEFF);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _muted = Color(0xFF6B8CAE);
  static const Color _amber = Color(0xFFD4AC0D);
  static const Color _amberLt = Color(0xFFFFF0A0);

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
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (context, child) =>
                      Transform.translate(offset: Offset(0, _slide.value), child: child),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 56),
                        _buildFreePlayButton(),
                        const SizedBox(height: 16),
                        _buildDailyButton(),
                        const SizedBox(height: 16),
                        _buildRulesButton(),
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

  // Nur Text — kein Icon
  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFAD0), Color(0xFFFFD54A), Color(0xFFFF9F00)],
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
            Shadow(color: _gold.withValues(alpha: 0.40), blurRadius: 16),
            Shadow(color: _cyan.withValues(alpha: 0.10), blurRadius: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFreePlayButton() {
    return _NeonButton(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen())),
      label: 'START FREE PLAY',
      sublabel: 'Unlimited Puzzles · Infinite Practice',
      icon: Icons.play_arrow_rounded,
      glowColor: _cyan,
      borderColor: _cyan.withValues(alpha: 0.85),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_cyan.withValues(alpha: 0.22), const Color(0xFF00AACC).withValues(alpha: 0.12)],
      ),
      labelColor: _cyanLt,
      sublabelColor: _cyan.withValues(alpha: 0.60),
      isPrimary: true,
    );
  }

  Widget _buildDailyButton() {
    return _NeonButton(
      onPressed: _isOpeningDaily ? null : _openDaily,
      label: _isOpeningDaily ? 'Preparing...' : 'TODAY\'S CHALLENGE',
      sublabel: _isOpeningDaily ? '' : 'New Puzzles Every Day',
      icon: Icons.calendar_today_rounded,
      glowColor: _amber,
      borderColor: _amber.withValues(alpha: 0.70),
      bgGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_amber.withValues(alpha: 0.18), _amber.withValues(alpha: 0.08)],
      ),
      labelColor: _amberLt,
      sublabelColor: _amber.withValues(alpha: 0.65),
      isPrimary: false,
      isLoading: _isOpeningDaily,
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
                'GAME RULES',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _muted),
              ),
              const SizedBox(height: 2),
              Text(
                'How To Play',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color glowColor;
  final Color borderColor;
  final LinearGradient bgGradient;
  final Color labelColor;
  final Color sublabelColor;
  final bool isPrimary;
  final bool isLoading;

  const _NeonButton({
    required this.onPressed,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.glowColor,
    required this.borderColor,
    required this.bgGradient,
    required this.labelColor,
    required this.sublabelColor,
    required this.isPrimary,
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
                color: enabled ? widget.borderColor : Colors.white.withValues(alpha: 0.10),
                width: widget.isPrimary ? 1.5 : 1.0,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: widget.isPrimary ? 0.28 : 0.18),
                        blurRadius: widget.isPrimary ? 20 : 14,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, size: 20, color: widget.labelColor),
                          const SizedBox(width: 8),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: widget.labelColor,
                              letterSpacing: -0.2,
                              shadows: enabled
                                  ? [
                                      Shadow(
                                        color: widget.glowColor.withValues(alpha: 0.50),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
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
