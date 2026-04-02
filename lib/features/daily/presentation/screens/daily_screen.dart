// lib/features/daily/presentation/screens/daily_screen.dart
import 'dart:async';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../game/logic/solver_service.dart';
import '../../../game/presentation/screens/practice_screen.dart';
import '../../data/daily_local_storage.dart';
import '../../data/daily_repository.dart';
import '../../domain/daily_progress.dart';
import '../../domain/daily_puzzle_play_result.dart';
import '../../domain/daily_puzzle_result.dart';
import '../../domain/daily_service.dart';
import '../controllers/daily_controller.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key, this.controllerOverride});

  final DailyController? controllerOverride;

  // ── Dark-Neon palette via AppColors ───────────────────────────────────────
  static const Color _bg = AppColors.bgTop;
  static const Color _ink = AppColors.ink;
  static const Color _accent = AppColors.accent;
  static const Color _card = AppColors.card;
  static const Color _border = AppColors.cardBr;
  static const Color _solved = AppColors.solved;
  static const Color _ended = AppColors.failed;
  static const Color _muted = AppColors.muted;
  static const Color _gold = AppColors.targetNumber;

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> with WidgetsBindingObserver {
  late final DailyController controller;
  final SolverService _solverService = SolverService();
  Timer? _countdownTimer;
  Duration _timeUntilNextDaily = Duration.zero;
  bool _isStartingDaily = false;
  bool _ownsController = false;

  static final DateTime _dailyNumberEpoch = DateTime(2026, 3, 17);
  static const String _dailyStateKey = 'daily_in_progress_state';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.controllerOverride != null) {
      controller = widget.controllerOverride!;
    } else {
      final generator = PuzzleGenerator();

      final coordinator = PuzzleCoordinator(
        generator: generator,
        mode: GameMode.daily,
        config: DifficultyConfig.easy,
        baseSeed: 0,
      );

      final repository = DailyRepository(
        service: DailyService(coordinator: coordinator),
        storage: DailyLocalStorage(),
      );

      controller = DailyController(repository: repository);
      _ownsController = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.loadToday();
      });
    }

    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_updateCountdown);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      controller.markRunInterrupted();
    } else if (state == AppLifecycleState.resumed) {
      controller.startRunTimer();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _dailyNumberForToday() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedEpoch = DateTime(
      _dailyNumberEpoch.year,
      _dailyNumberEpoch.month,
      _dailyNumberEpoch.day,
    );
    final diff = normalizedToday.difference(normalizedEpoch).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _timeUntilNextDaily = nextMidnight.difference(now);
  }

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _actionLabel(DailyProgress progress) {
    if (progress.isCompleted) return 'Completed';
    if (progress.gaveUp) return 'Daily Ended';
    if (progress.canContinue) return 'Continue Daily';
    return 'Start Daily';
  }

  String _statusText(DailyProgress progress) {
    if (progress.isCompleted) return 'All daily puzzles solved.';
    if (progress.gaveUp) return 'You ended today\'s run.';
    if (progress.canContinue) return 'Run interrupted. Continue with the next puzzle.';
    return '';
  }

  DailyPuzzleResult? _resultForPuzzle(DailyProgress progress, int puzzleIndex) {
    for (final result in progress.puzzleResults) {
      if (result.puzzleIndex == puzzleIndex) return result;
    }
    return null;
  }

  int _nextPuzzleNumber(DailyProgress progress, int totalPuzzles) {
    if (totalPuzzles <= 0) return 0;
    final nextIndex = progress.currentPuzzleIndex.clamp(0, totalPuzzles - 1);
    return nextIndex + 1;
  }

  void _savePuzzleResultToList({
    required List<DailyPuzzleResult> puzzleResults,
    required int puzzleIndex,
    required bool solved,
    required bool gaveUp,
    required int moves,
    required Duration elapsed,
    int? optimalMoves,
    String? fullExpression,
  }) {
    puzzleResults.removeWhere((e) => e.puzzleIndex == puzzleIndex);
    puzzleResults.add(
      DailyPuzzleResult(
        puzzleIndex: puzzleIndex,
        solved: solved,
        gaveUp: gaveUp,
        moves: moves,
        elapsed: elapsed,
        optimalMoves: optimalMoves,
        fullExpression: fullExpression,
      ),
    );
    puzzleResults.sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex));
  }

  // ── Decorations helper ────────────────────────────────────────────────────

  BoxDecoration _cardDecoration({double radius = 20, Color? borderColor}) {
    return BoxDecoration(
      color: DailyScreen._card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? DailyScreen._border),
    );
  }

  // ── Cards: pre-run screen ─────────────────────────────────────────────────

  Widget _buildStreakCard(int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Daily Streak: $streak',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DailyScreen._ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 22, color: DailyScreen._accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Next Daily in ${_formatCountdown(_timeUntilNextDaily)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DailyScreen._ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(DailyProgress progress, int totalPuzzles) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoItem(label: 'Progress', value: '${progress.solvedCount} / $totalPuzzles puzzles'),
          const SizedBox(height: 14),
          _ProgressSteps(solvedCount: progress.solvedCount, totalPuzzles: totalPuzzles),
        ],
      ),
    );
  }

  Widget _buildFormatCard(DailyProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormatRow(icon: Icons.extension_rounded, text: '5 puzzles'),
          SizedBox(height: 10),
          _FormatRow(icon: Icons.flag_rounded, text: 'One scored run only'),
          SizedBox(height: 10),
          _FormatRow(icon: Icons.lock_open_rounded, text: 'Practice unlocks after give up'),
          SizedBox(height: 10),
          _FormatRow(
            icon: Icons.lightbulb_outline_rounded,
            text: '1 Hint per run (before first move)',
          ),
          SizedBox(height: 10),
          _FormatRow(icon: Icons.block_rounded, text: 'Hint blocks 3★ run'),
          SizedBox(height: 10),
          _FormatRow(icon: Icons.star_rounded, text: 'Perfect run requires optimal moves'),
        ],
      ),
    );
  }

  // ── Cards: result screen ──────────────────────────────────────────────────

  Widget _buildResultHero(DailyProgress progress) {
    final isCompleted = progress.isCompleted;
    final runStars = controller.runStars();

    final title = isCompleted ? (runStars == 3 ? 'Perfect Run' : 'Daily Complete') : 'Daily Ended';

    final quality = switch (runStars) {
      3 => 'Perfect precision. You nailed every puzzle!',
      2 => 'Well done — completed without hints.',
      1 => 'Completed with a hint. Try without next time!',
      _ => 'Keep at it — the next run is yours.',
    };

    // Gold filled stars, muted empty stars
    final starRow = Row(
      children: List.generate(3, (i) {
        final filled = i < runStars;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            filled ? '★' : '☆',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: filled ? DailyScreen._gold : DailyScreen._muted,
            ),
          ),
        );
      }),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(
        borderColor: runStars == 3
            ? DailyScreen._gold.withValues(alpha: 0.45)
            : DailyScreen._border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: DailyScreen._ink,
            ),
          ),
          const SizedBox(height: 10),
          starRow,
          const SizedBox(height: 10),
          Text(
            quality,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DailyScreen._ink.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunSummaryCard(DailyProgress progress) {
    final totalDiff = controller.runTotalDiff();
    final totalTime = progress.totalTimeSeconds;
    final formattedTime = controller.formatTime(totalTime);

    final efficiencyLabel = totalDiff == 0 ? 'Optimal' : '+$totalDiff';
    final efficiencyColor = totalDiff == 0 ? DailyScreen._solved : DailyScreen._ink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: 'Efficiency',
              value: efficiencyLabel,
              valueColor: efficiencyColor,
            ),
          ),
          Expanded(
            child: _SummaryCell(label: 'Time', value: formattedTime),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(DailyProgress progress, int totalPuzzles) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Results',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: DailyScreen._ink),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < totalPuzzles; i++) ...[
            _buildPuzzleResultCard(progress, i, totalPuzzles),
            if (i != totalPuzzles - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildPuzzleResultCard(DailyProgress progress, int puzzleIndex, int totalPuzzles) {
    final result = _resultForPuzzle(progress, puzzleIndex);

    final bool isSolved = result?.solved ?? false;
    final bool isGaveUp = result?.gaveUp ?? false;
    final bool isPlayed = result != null;
    final bool isUnlocked = progress.gaveUp
        ? true
        : puzzleIndex <= progress.currentPuzzleIndex.clamp(0, totalPuzzles - 1);
    final bool canTap = progress.gaveUp || isPlayed || isUnlocked;

    String statusText = '';
    Color statusColor = DailyScreen._muted;

    if (isSolved) {
      final r = result!;
      if (r.optimalMoves != null) {
        final diff = r.moves - r.optimalMoves!;
        if (diff <= 0) {
          statusText = 'Optimal';
          statusColor = DailyScreen._solved;
        } else if (diff == 1) {
          statusText = '+1';
          statusColor = DailyScreen._ink.withValues(alpha: 0.8);
        } else if (diff == 2) {
          statusText = '+2';
          statusColor = DailyScreen._ink.withValues(alpha: 0.65);
        } else {
          statusText = '+3+';
          statusColor = DailyScreen._muted;
        }
      } else {
        statusText = 'Solved';
        statusColor = DailyScreen._solved;
      }
    } else if (isGaveUp) {
      statusText = 'Gave Up';
      statusColor = DailyScreen._ended;
    } else {
      statusText = 'Not played';
      statusColor = DailyScreen._muted;
    }

    final bool showButtons = result != null && (isSolved || isGaveUp);
    final bool showTrainingLabel = result != null && canTap;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgBottom,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DailyScreen._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Puzzle ${puzzleIndex + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DailyScreen._ink,
                  ),
                ),
              ),
              Text(
                statusText,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (result != null && (isSolved || isGaveUp))
            Row(
              children: [
                Expanded(
                  child: _MiniInfoItem(label: 'Moves', value: '${result.moves}'),
                ),
                Expanded(
                  child: _MiniInfoItem(label: 'Time', value: _formatDuration(result.elapsed)),
                ),
              ],
            )
          else
            Text('No result saved.', style: TextStyle(fontSize: 13, color: DailyScreen._muted)),
          if (showTrainingLabel) ...[
            const SizedBox(height: 10),
            Text(
              'Training only',
              style: TextStyle(
                fontSize: 12,
                color: DailyScreen._muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showButtons) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showBestSolutionDialog(result),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DailyScreen._accent,
                  side: BorderSide(color: DailyScreen._accent.withValues(alpha: 0.55)),
                  backgroundColor: DailyScreen._accent.withValues(alpha: 0.08),
                ),
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: const Text('Show Best Solution'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    _handleMainAction(progress, startPuzzleIndex: puzzleIndex, allowReplay: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DailyScreen._ink,
                  side: BorderSide(color: DailyScreen._border),
                  backgroundColor: DailyScreen._card,
                ),
                child: const Text('Train Again'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Dialog ────────────────────────────────────────────────────────────────

  void _showBestSolutionDialog(DailyPuzzleResult result) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final daily = controller.daily;
        final targetText =
            (daily != null && result.puzzleIndex >= 0 && result.puzzleIndex < daily.puzzles.length)
            ? daily.puzzles[result.puzzleIndex].target
            : null;
        final media = MediaQuery.of(context).size;
        final dialogWidth = media.width > 900
            ? 760.0
            : media.width > 700
            ? 680.0
            : double.maxFinite;

        final expr = result.fullExpression ?? 'No solution available.';
        final optimalText = result.optimalMoves != null
            ? '${result.optimalMoves} Moves'
            : '- Moves';

        return AlertDialog(
          backgroundColor: DailyScreen._card,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: DailyScreen._border),
          ),
          titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          contentPadding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          title: const Text(
            'Best Solution',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: DailyScreen._ink),
          ),
          content: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.height * 0.78, minHeight: 180),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.bgBottom,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DailyScreen._border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: DailyScreen._card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: DailyScreen._border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (targetText != null) ...[
                              Text(
                                'Target: $targetText',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: DailyScreen._gold,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            SelectableText(
                              expr,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.5,
                                color: DailyScreen._ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Optimal: $optimalText',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: DailyScreen._ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You: ${result.moves} Moves',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: DailyScreen._ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            SizedBox(
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DailyScreen._accent,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Main action ───────────────────────────────────────────────────────────

  Future<void> _handleMainAction(
    DailyProgress progress, {
    int? startPuzzleIndex,
    bool allowReplay = false,
  }) async {
    if (_isStartingDaily) return;
    if (!allowReplay && (progress.isCompleted || progress.gaveUp)) return;

    final daily = controller.daily;
    if (daily == null) return;

    _isStartingDaily = true;

    int currentPuzzleIndex = (startPuzzleIndex ?? progress.currentPuzzleIndex).clamp(
      0,
      daily.puzzles.length,
    );
    int solvedCount = progress.solvedCount;
    final puzzleResults = List<DailyPuzzleResult>.from(progress.puzzleResults)
      ..sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex));

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyStateKey);

    if (!allowReplay) sfx.startDaily();
    controller.startRunTimer();

    try {
      while (mounted && currentPuzzleIndex < daily.puzzles.length) {
        final puzzleIndex = currentPuzzleIndex;

        unawaited(
          controller.syncRunProgress(
            solvedCount: solvedCount,
            currentPuzzleIndex: currentPuzzleIndex,
          ),
        );

        final puzzle = daily.puzzles[puzzleIndex];
        final solverResult = _solverService.check(diceValues: puzzle.dice, target: puzzle.target);

        final fullExpression = solverResult.fullExpression;
        final optimalMoves = solverResult.solvable ? solverResult.moveCount : null;

        final result = await Navigator.of(context).push<DailyPuzzlePlayResult>(
          MaterialPageRoute(
            builder: (_) => PracticeScreen(
              initialPuzzle: puzzle,
              isDailyMode: true,
              isReplayMode: allowReplay,
              dailyPuzzleIndex: puzzleIndex,
              dailyPuzzleCount: daily.puzzles.length,
              dailyController: controller,
            ),
          ),
        );

        if (!mounted || result == null) return;
        if (allowReplay) return;

        if (result.gaveUp) {
          _savePuzzleResultToList(
            puzzleResults: puzzleResults,
            puzzleIndex: puzzleIndex,
            solved: false,
            gaveUp: true,
            moves: result.moves,
            elapsed: result.elapsed,
            optimalMoves: optimalMoves,
            fullExpression: fullExpression,
          );
          await controller.syncPuzzleResults(puzzleResults);
          await controller.syncRunProgress(
            solvedCount: solvedCount,
            currentPuzzleIndex: currentPuzzleIndex,
          );
          await controller.markGiveUp();
          return;
        }

        if (result.solved) {
          _savePuzzleResultToList(
            puzzleResults: puzzleResults,
            puzzleIndex: puzzleIndex,
            solved: true,
            gaveUp: false,
            moves: result.moves,
            elapsed: result.elapsed,
            optimalMoves: optimalMoves,
            fullExpression: fullExpression,
          );

          if (currentPuzzleIndex < daily.puzzles.length - 1) {
            sfx.win();
          }
          solvedCount += 1;
          currentPuzzleIndex += 1;

          unawaited(controller.syncPuzzleResults(puzzleResults));
          unawaited(
            controller.syncRunProgress(
              solvedCount: solvedCount,
              currentPuzzleIndex: currentPuzzleIndex,
            ),
          );

          if (currentPuzzleIndex >= daily.puzzles.length) {
            await controller.syncPuzzleResults(puzzleResults);
            await controller.syncRunProgress(
              solvedCount: solvedCount,
              currentPuzzleIndex: currentPuzzleIndex,
            );
            await controller.markRunCompleted();
            await controller.loadToday();
            return;
          }

          continue;
        }

        return;
      }
    } finally {
      _isStartingDaily = false;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dailyNumber = _dailyNumberForToday();

    return Scaffold(
      backgroundColor: DailyScreen._bg,
      appBar: AppBar(
        title: Text('Daily #$dailyNumber'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DailyScreen._ink,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading || _isStartingDaily) {
            return Container(color: AppColors.bgBottom);
          }

          final daily = controller.daily;
          final progress = controller.progress;

          if (daily == null || progress == null) {
            return const Center(
              child: Text(
                'Daily challenge could not be loaded.',
                style: TextStyle(fontSize: 16, color: DailyScreen._ink),
              ),
            );
          }

          final showResults = progress.isCompleted || progress.gaveUp;
          final disableButton = progress.isCompleted || progress.gaveUp || _isStartingDaily;
          final topStatus = _statusText(progress);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: showResults
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStreakCard(controller.dailyStreak),
                          const SizedBox(height: 12),
                          _buildCountdownCard(),
                          const SizedBox(height: 16),
                          _buildResultHero(progress),
                          const SizedBox(height: 12),
                          _buildRunSummaryCard(progress),
                          const SizedBox(height: 16),
                          _buildResultsCard(progress, daily.puzzles.length),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStreakCard(controller.dailyStreak),
                        const SizedBox(height: 12),
                        _buildCountdownCard(),
                        const SizedBox(height: 16),
                        if (topStatus.isNotEmpty) ...[
                          Text(
                            topStatus,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.35,
                              color: DailyScreen._ink.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        _buildProgressCard(progress, daily.puzzles.length),
                        const SizedBox(height: 16),
                        _buildFormatCard(progress),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: disableButton
                                ? null
                                : () async => _handleMainAction(progress),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                disableButton ? DailyScreen._muted : DailyScreen._accent,
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                disableButton ? DailyScreen._ink : AppColors.bgTop,
                              ),
                              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                              elevation: const WidgetStatePropertyAll(0),
                              splashFactory: NoSplash.splashFactory,
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                            child: Text(
                              _actionLabel(progress),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ── Widget helpers ────────────────────────────────────────────────────────────

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DailyScreen._muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor ?? DailyScreen._ink,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DailyScreen._muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DailyScreen._ink,
          ),
        ),
      ],
    );
  }
}

class _MiniInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DailyScreen._muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: DailyScreen._ink,
          ),
        ),
      ],
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  final int solvedCount;
  final int totalPuzzles;

  const _ProgressSteps({required this.solvedCount, required this.totalPuzzles});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalPuzzles, (index) {
        final isDone = index < solvedCount;
        final isCurrent = index == solvedCount && solvedCount < totalPuzzles;

        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index == totalPuzzles - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isDone
                  ? DailyScreen._accent
                  : isCurrent
                  ? DailyScreen._accent.withValues(alpha: 0.28)
                  : AppColors.bgBottom,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDone ? DailyScreen._accent.withValues(alpha: 0.5) : DailyScreen._border,
                width: 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FormatRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DailyScreen._accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DailyScreen._ink,
            ),
          ),
        ),
      ],
    );
  }
}
