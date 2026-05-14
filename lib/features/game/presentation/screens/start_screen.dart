import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/daily/data/daily_local_storage.dart';
import 'package:dice/features/daily/data/daily_repository.dart';
import 'package:dice/features/daily/domain/daily_service.dart';
import 'package:dice/features/daily/presentation/controllers/daily_controller.dart';
import 'package:dice/features/daily/presentation/screens/daily_screen.dart';
import 'package:dice/features/game/presentation/screens/free_play_start_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_start_screen.dart';
import 'package:dice/features/game/presentation/screens/rules_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_home_screen.dart';
import 'package:dice/core/widgets/menu_card.dart';
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
        _buildDailyCard(),
        const SizedBox(height: 12),
        _buildRushCard(),
        const SizedBox(height: 12),
        _buildFreePlayCard(),
        const SizedBox(height: 12),
        _buildDuelsCard(),
      ],
    );
  }

  Widget _buildDailyCard() {
    return MenuCard(
      title: 'Daily Challenge',
      subtitle: '5 puzzles · Fewest moves wins',
      icon: Icons.emoji_events_rounded,
      onTap: _isOpeningDaily ? null : _openDaily,
      gradientColors: const [
        Color(0xFF211A08),
        Color(0xFF130F03),
        Color(0xFF0E0B02),
        Color(0xFF191408),
      ],
      gradientStops: const [0.0, 0.35, 0.65, 1.0],
      glowColor: const Color(0xFFB8960C),
      borderColor: const Color(0xFFB8960C),
      iconBgColor: const Color(0xFF252010),
      iconColor: const Color(0xFFD4AF37),
      titleColor: const Color(0xFFE8C96A),
      subtitleColor: const Color(0xFF8A6E1A),
    );
  }

  Widget _buildRushCard() {
    return MenuCard(
      title: 'Rush',
      subtitle: '90 sec · Solve as many as possible',
      icon: Icons.timer_rounded,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RushStartScreen()),
      ),
      gradientColors: const [
        Color(0xFF0C150E),
        Color(0xFF081008),
        Color(0xFF060D06),
        Color(0xFF0A1209),
      ],
      gradientStops: const [0.0, 0.35, 0.65, 1.0],
      glowColor: const Color(0xFF1B5E20),
      borderColor: const Color(0xFF2E7D32),
      iconBgColor: const Color(0xFF0F2010),
      iconColor: const Color(0xFF4CAF50),
      titleColor: const Color(0xFF66BB6A),
      subtitleColor: const Color(0xFF254A28),
    );
  }

  Widget _buildFreePlayCard() {
    return MenuCard(
      title: 'Free Play',
      subtitle: 'Classic · Training',
      icon: Icons.casino_rounded,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FreePlayStartScreen()),
      ),
      gradientColors: const [
        Color(0xFF0E1420),
        Color(0xFF080D18),
        Color(0xFF050810),
        Color(0xFF0A0F1A),
      ],
      gradientStops: const [0.0, 0.35, 0.65, 1.0],
      glowColor: const Color(0xFF0D47A1),
      borderColor: const Color(0xFF1565C0),
      iconBgColor: const Color(0xFF0A1525),
      iconColor: const Color(0xFF2979C4),
      titleColor: const Color(0xFF90CAF9),
      subtitleColor: const Color(0xFF1A3A5A),
    );
  }

  Widget _buildDuelsCard() {
    return MenuCard(
      title: 'Duels',
      subtitle: 'Compete against a friend',
      icon: Icons.people_rounded,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VsHomeScreen()),
      ),
      gradientColors: const [
        Color(0xFF120A18),
        Color(0xFF0A0610),
        Color(0xFF07040C),
        Color(0xFF0E0A14),
      ],
      gradientStops: const [0.0, 0.35, 0.65, 1.0],
      glowColor: const Color(0xFF4A148C),
      borderColor: const Color(0xFF6A1B9A),
      iconBgColor: const Color(0xFF180A25),
      iconColor: const Color(0xFFAB47BC),
      titleColor: const Color(0xFFCE93D8),
      subtitleColor: const Color(0xFF3A1455),
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
