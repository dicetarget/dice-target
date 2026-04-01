import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:flutter/material.dart';

import '../../../game/presentation/screens/practice_screen.dart';
import '../../domain/daily_progress.dart';
import '../../domain/daily_puzzle_play_result.dart';
import '../../domain/daily_puzzle_result.dart';
import '../../domain/daily_puzzle_set.dart';

class DailyRunScreen extends StatefulWidget {
  final DailyPuzzleSet daily;
  final DailyProgress progress;

  const DailyRunScreen({super.key, required this.daily, required this.progress});

  @override
  State<DailyRunScreen> createState() => _DailyRunScreenState();
}

class _DailyRunScreenState extends State<DailyRunScreen> with WidgetsBindingObserver {
  static const Color _bg = Color(0xFFF7F1F6);
  static const Color _ink = Color(0xFF1D1B20);
  static const Color _accent = Color(0xFF6E5AAE);
  static const Color _card = Colors.white;

  late int _currentIndex;
  late int _solvedCount;
  late List<DailyPuzzleResult> _puzzleResults;

  bool _isStartingPuzzle = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _solvedCount = widget.progress.solvedCount;
    _currentIndex = widget.progress.currentPuzzleIndex.clamp(0, widget.daily.puzzles.length);
    _puzzleResults = List<DailyPuzzleResult>.from(widget.progress.puzzleResults)
      ..sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex));

    if (widget.progress.gaveUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closeWithResult(
          solved: false,
          gaveUp: true,
          moves: 0,
          elapsed: Duration.zero,
          puzzleIndex: (_currentIndex - 1).clamp(0, widget.daily.puzzles.length - 1),
        );
      });
      return;
    }

    if (widget.progress.isCompleted || _currentIndex >= widget.daily.puzzles.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closeWithResult(
          solved: true,
          gaveUp: false,
          moves: 0,
          elapsed: Duration.zero,
          puzzleIndex: (_currentIndex - 1).clamp(0, widget.daily.puzzles.length - 1),
        );
      });
      return;
    }

    Future.microtask(_openCurrentPuzzle);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistDailyRunState();
    }
  }

  void _persistDailyRunState() {
    // Lifecycle hook intentionally prepared here.
    // Real persistence must be connected to the existing Daily repository/storage flow
    // so the current run state can be written on pause/background without changing
    // the current navigation behavior in this file.
  }

  DailyPuzzlePlayResult _buildFinalResult({
    required bool solved,
    required bool gaveUp,
    required int moves,
    required Duration elapsed,
    required int puzzleIndex,
  }) {
    final safePuzzleIndex = widget.daily.puzzles.isEmpty
        ? 0
        : puzzleIndex.clamp(0, widget.daily.puzzles.length - 1);

    return DailyPuzzlePlayResult(
      solved: solved,
      gaveUp: gaveUp,
      moves: moves,
      elapsed: elapsed,
      solvedCount: _solvedCount,
      currentPuzzleIndex: _currentIndex,
      puzzleIndex: safePuzzleIndex,
      puzzleResults: List<DailyPuzzleResult>.from(_puzzleResults),
    );
  }

  void _savePuzzleResult({
    required int puzzleIndex,
    required bool solved,
    required bool gaveUp,
    required int moves,
    required Duration elapsed,
  }) {
    _puzzleResults.removeWhere((e) => e.puzzleIndex == puzzleIndex);
    _puzzleResults.add(
      DailyPuzzleResult(
        puzzleIndex: puzzleIndex,
        solved: solved,
        gaveUp: gaveUp,
        moves: moves,
        elapsed: elapsed,
      ),
    );
    _puzzleResults.sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex));
  }

  void _closeWithResult({
    required bool solved,
    required bool gaveUp,
    required int moves,
    required Duration elapsed,
    required int puzzleIndex,
  }) {
    if (!mounted || _isClosing) return;
    _isClosing = true;

    Navigator.of(context).pop(
      _buildFinalResult(
        solved: solved,
        gaveUp: gaveUp,
        moves: moves,
        elapsed: elapsed,
        puzzleIndex: puzzleIndex,
      ),
    );
  }

  Future<void> _openCurrentPuzzle() async {
    if (!mounted || _isClosing || _isStartingPuzzle) return;

    if (_currentIndex >= widget.daily.puzzles.length) {
      _closeWithResult(
        solved: true,
        gaveUp: false,
        moves: 0,
        elapsed: Duration.zero,
        puzzleIndex: (_currentIndex - 1).clamp(0, widget.daily.puzzles.length - 1),
      );
      return;
    }

    _isStartingPuzzle = true;

    final puzzleIndex = _currentIndex;
    final puzzle = widget.daily.puzzles[puzzleIndex];

    final result = await Navigator.of(context).push<DailyPuzzlePlayResult>(
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          initialPuzzle: puzzle,
          isDailyMode: true,
          dailyPuzzleIndex: puzzleIndex,
          dailyPuzzleCount: widget.daily.puzzles.length,
        ),
      ),
    );

    _isStartingPuzzle = false;

    if (!mounted || result == null || _isClosing) return;

    if (result.gaveUp) {
      _savePuzzleResult(
        puzzleIndex: puzzleIndex,
        solved: false,
        gaveUp: true,
        moves: result.moves,
        elapsed: result.elapsed,
      );

      _closeWithResult(
        solved: false,
        gaveUp: true,
        moves: result.moves,
        elapsed: result.elapsed,
        puzzleIndex: puzzleIndex,
      );
      return;
    }

    if (result.solved) {
      _savePuzzleResult(
        puzzleIndex: puzzleIndex,
        solved: true,
        gaveUp: false,
        moves: result.moves,
        elapsed: result.elapsed,
      );

      sfx.win();

      _solvedCount += 1;
      _currentIndex += 1;

      if (_currentIndex >= widget.daily.puzzles.length) {
        sfx.dailyComplete();
        _closeWithResult(
          solved: true,
          gaveUp: false,
          moves: result.moves,
          elapsed: result.elapsed,
          puzzleIndex: puzzleIndex,
        );
        return;
      }

      await _openCurrentPuzzle();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCurrentPuzzle();
    });
  }

  int get _totalPuzzles => widget.daily.puzzles.length;

  int get _displayPuzzleNumber {
    if (_totalPuzzles == 0) return 0;
    final number = _currentIndex + 1;
    if (number < 1) return 1;
    if (number > _totalPuzzles) return _totalPuzzles;
    return number;
  }

  double get _progressValue {
    if (_totalPuzzles == 0) return 0;
    return _solvedCount / _totalPuzzles;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          centerTitle: true,
          title: const Text(
            'Daily',
            style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: _buildLoadingView(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgressCard(),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(color: _accent, strokeWidth: 3.2),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Opening puzzle...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Preparing your next Daily challenge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.35, color: _ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily in Progress',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 8),
          Text(
            '$_displayPuzzleNumber / $_totalPuzzles',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Solved: $_solvedCount / $_totalPuzzles',
            style: TextStyle(
              fontSize: 14,
              color: _ink.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progressValue.clamp(0, 1),
              minHeight: 10,
              backgroundColor: _accent.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
        ],
      ),
    );
  }
}
