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
import 'package:shared_preferences/shared_preferences.dart';

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
  int _streak = 0;
  int _rushHighscore = 0;

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
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _streak = prefs.getInt('daily_streak') ?? 0;
        _rushHighscore = prefs.getInt('rush_highscore') ?? 0;
      });
    }
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
      subtitle: '5 puzzles · Best score',
      sublabel: "TODAY'S PUZZLE",
      icon: Icons.emoji_events_rounded,
      onTap: _isOpeningDaily ? null : _openDaily,
      gradientColors: const [
        Color(0xFF1E1608),
        Color(0xFF130E04),
        Color(0xFF0E0A02),
      ],
      gradientStops: const [0.0, 0.5, 1.0],
      glowColor: const Color(0xFFCFA84E),
      borderColor: const Color(0xFFB8960C),
      iconBgColor: const Color(0xFF252010),
      iconColor: const Color(0xFFD4AF37),
      titleColor: const Color(0xFFE8C96A),
      subtitleColor: const Color(0xFF9A7C28),
    );
  }

  Widget _buildRushCard() {
    const accentColor = Color(0xFF66BB6A);
    final hasBadge = _rushHighscore > 0;
    return Stack(
      children: [
        MenuCard(
          title: 'Rush',
          subtitle: 'Solve as many as possible',
          sublabel: '90 SECONDS',
          icon: Icons.timer_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RushStartScreen()),
          ),
          gradientColors: const [
            Color(0xFF0A150A),
            Color(0xFF060E05),
            Color(0xFF040A03),
          ],
          gradientStops: const [0.0, 0.5, 1.0],
          glowColor: const Color(0xFF4AAA58),
          borderColor: const Color(0xFF2E7D32),
          iconBgColor: const Color(0xFF0F2010),
          iconColor: const Color(0xFF4CAF50),
          titleColor: accentColor,
          subtitleColor: const Color(0xFF3D7045),
        ),
        if (hasBadge)
          Positioned(
            top: 12, right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.28), width: 1),
              ),
              child: Text(
                'BEST: $_rushHighscore',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: accentColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFreePlayCard() {
    return MenuCard(
      title: 'Free Play',
      subtitle: 'Classic · Training',
      sublabel: 'NO PRESSURE',
      icon: Icons.casino_rounded,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FreePlayStartScreen()),
      ),
      gradientColors: const [
        Color(0xFF0A0F1C),
        Color(0xFF070B15),
        Color(0xFF050810),
      ],
      gradientStops: const [0.0, 0.5, 1.0],
      glowColor: const Color(0xFF5F91EB),
      borderColor: const Color(0xFF1565C0),
      iconBgColor: const Color(0xFF0A1525),
      iconColor: const Color(0xFF2979C4),
      titleColor: const Color(0xFF90CAF9),
      subtitleColor: const Color(0xFF2E5A8A),
    );
  }

  Widget _buildDuelsCard() {
    return MenuCard(
      title: 'Duels',
      subtitle: 'Compete against a friend',
      sublabel: 'CHALLENGE FRIENDS',
      icon: Icons.people_rounded,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VsHomeScreen()),
      ),
      gradientColors: const [
        Color(0xFF100A1C),
        Color(0xFF0A0714),
        Color(0xFF07050F),
      ],
      gradientStops: const [0.0, 0.5, 1.0],
      glowColor: const Color(0xFF9B5FEB),
      borderColor: const Color(0xFF6A1B9A),
      iconBgColor: const Color(0xFF180A25),
      iconColor: const Color(0xFFAB47BC),
      titleColor: const Color(0xFFCE93D8),
      subtitleColor: const Color(0xFF5A2E8A),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MATH PUZZLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.champagneGold.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2E5B8),
              Color(0xFFCFA84E),
              Color(0xFF7A5518),
            ],
            stops: [0.0, 0.48, 1.0],
          ).createShader(bounds),
          child: const Text(
            'Dice Target',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StreakIndicator(currentStreak: _streak),
      ],
    );
  }

  Widget _buildRulesButton() {
    return OutlinedButton(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: AppColors.inkMuted.withValues(alpha: 0.13),
          width: 1,
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.025),
        foregroundColor: AppColors.inkMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusButton),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        'How to Play',
        style: TextStyle(
          color: AppColors.inkMuted.withValues(alpha: 0.40),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _StreakIndicator extends StatelessWidget {
  final int currentStreak;
  const _StreakIndicator({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    const maxDots = 7;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(maxDots, (i) {
          final active = i < currentStreak.clamp(0, maxDots);
          return Container(
            width: 5, height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.champagneGold.withValues(alpha: 0.80)
                  : AppColors.champagneGold.withValues(alpha: 0.10),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          currentStreak > 0 ? '$currentStreak-Day Streak' : 'Start your streak',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: AppColors.champagneGold.withValues(alpha: 0.52),
          ),
        ),
      ],
    );
  }
}
