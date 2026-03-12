enum GameState { idle, playing, solved, notSolved, timeout }

enum FinishReason { solved, notSolved, timeout }

class GameResult {
  final FinishReason reason;
  final int target;
  final int moves;
  final Duration elapsed;

  const GameResult({
    required this.reason,
    required this.target,
    required this.moves,
    required this.elapsed,
  });
}

class GameRules {
  GameState state = GameState.idle;

  int target = 0;
  int moves = 0;

  Duration? elapsedTime; // bleibt für UI/Debug ok
  GameResult? lastResult; // ✅ Daily/Rank-ready

  // optional vorbereiten (DifficultyConfig.timeLimit)
  Duration? timeLimit;

  void start(int newTarget, {Duration? timeLimit}) {
    target = newTarget;
    moves = 0;
    elapsedTime = null;
    lastResult = null;

    this.timeLimit = timeLimit;

    state = GameState.playing;
  }

  void registerMove() {
    if (state == GameState.playing) {
      moves += 1;
    }
  }

  GameState checkResult(int finalValue) {
    if (state != GameState.playing) return state;

    if (finalValue == target) {
      state = GameState.solved;
    } else {
      state = GameState.notSolved;
    }
    return state;
  }

  // ✅ schreibt Ergebnis exakt einmal
  void finish(Duration time) {
    if (state == GameState.idle) return;
    if (lastResult != null) return; // Guard: nur einmal

    if (state == GameState.playing) {
      // falls finish() aus Versehen zu früh kommt -> als notSolved werten
      state = GameState.notSolved;
    }

    elapsedTime = time;

    final reason = (state == GameState.solved)
        ? FinishReason.solved
        : (state == GameState.timeout)
        ? FinishReason.timeout
        : FinishReason.notSolved;

    lastResult = GameResult(
      reason: reason,
      target: target,
      moves: moves,
      elapsed: time,
    );
  }

  void markTimeout() {
    if (state == GameState.playing) {
      state = GameState.timeout;
    }
  }

  void reset() {
    target = 0;
    moves = 0;
    elapsedTime = null;
    lastResult = null;
    timeLimit = null;
    state = GameState.idle;
  }
}
