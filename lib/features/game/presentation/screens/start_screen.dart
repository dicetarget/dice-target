import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/daily/data/daily_local_storage.dart';
import 'package:dice/features/daily/data/daily_repository.dart';
import 'package:dice/features/daily/domain/daily_service.dart';
import 'package:dice/features/daily/presentation/controllers/daily_controller.dart';
import 'package:dice/features/daily/presentation/screens/daily_screen.dart';
import 'package:dice/features/game/presentation/screens/free_play_start_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_start_screen.dart';
import 'package:dice/features/game/presentation/screens/rules_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_home_screen.dart';
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

      if (mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DailyScreen(controllerOverride: controller)));
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningDaily = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (context, child) =>
                  Transform.translate(offset: Offset(0, _slide.value), child: child),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 3),
                          _buildTitle(),
                          const SizedBox(height: 40),
                          _buildButtons(),
                          const Spacer(flex: 4),
                          _buildRulesButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDailyButton(),
        const SizedBox(height: 14),
        _buildRushButton(),
        const SizedBox(height: 14),
        _buildFreePlayButton(),
        const SizedBox(height: 14),
        _buildVsButton(),
      ],
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE8C96A), // Gold hell
          Color(0xFFD4AF37), // Champagne Gold
          Color(0xFFA88A22), // Gold dunkel
          Color(0xFFD4AF37), // zurück zu Gold
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(bounds),
      child: const Text(
        'Dice Target',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFreePlayButton() {
    return TactileButton(
      variant: TactileButtonVariant.primary,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      borderRadius: BorderRadius.circular(16),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FreePlayStartScreen())),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Free Play',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Classic · Training',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRushButton() {
    return TactileButton(
      variant: TactileButtonVariant.primary,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      borderRadius: BorderRadius.circular(16),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RushStartScreen()),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Rush',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Solve as many as possible in 90 seconds',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyButton() {
    return TactileButton(
      variant: TactileButtonVariant.gold,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      borderRadius: BorderRadius.circular(16),
      onPressed: _isOpeningDaily ? null : _openDaily,
      child: _isOpeningDaily
          ? const SizedBox(
              height: 38,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dicePip),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Daily Challenge',
                  style: TextStyle(
                    color: AppColors.dicePip,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '5 puzzles · Fewest moves wins',
                  style: TextStyle(
                    color: AppColors.dicePip,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVsButton() {
    return TactileButton(
      variant: TactileButtonVariant.primary,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      borderRadius: BorderRadius.circular(16),
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VsHomeScreen())),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Duels',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Compete against a friend',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesButton() {
    return TextButton(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
      child: const Text(
        'How to Play',
        style: TextStyle(
          color: AppColors.inkMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
