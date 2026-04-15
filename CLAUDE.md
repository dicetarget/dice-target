# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get       # Install dependencies
flutter run           # Run on connected device/simulator
flutter test          # Run tests (test/ directory is currently sparse)
flutter build apk     # Android release build
flutter build ios     # iOS release build
flutter analyze       # Dart static analysis / lint
```

## Architecture

**Dice Target** is a Flutter/Dart deterministic logic dice puzzle game. Players combine dice values with arithmetic operators to reach a target number.

### Layer structure

```
lib/
├── core/          # Shared kernel: theme tokens, audio, game rules, puzzle engine
└── features/
    ├── game/      # Free Play — logic/, models/, presentation/
    ├── daily/     # Daily Challenge — data/, domain/, presentation/
    └── rush/      # Speed Run (Rush) — data/, domain/, presentation/
```

Each feature is a vertical slice: `data/` (SharedPreferences persistence) → `domain/` (business rules) → `presentation/` (controllers + screens + widgets).

### State management

**ChangeNotifier** is the only state management pattern used. Controllers (`DailyController`, `RushController`) extend `ChangeNotifier` and are passed down via constructor or `Provider`-style instantiation in screen widgets. `RushController` also exposes an event `Stream` for one-shot UI reactions (shake, flash, finish).

Game state models (e.g. `PracticeGameState`) are immutable with `copyWith`.

### Puzzle engine (core/puzzle/)

- `PuzzleGenerator` — creates a `Puzzle` (dice + target) from a `GameMode`, `DifficultyConfig`, and integer seed. Same seed → same puzzle deterministically.
- `PuzzleSeed` — derives the integer seed from context (free play: random; daily: date-based; rush: sequential).
- `PuzzleCoordinator` — orchestrates puzzle lifecycle across difficulty changes and round transitions.
- `Solver` (features/game/logic/solver.dart) — DFS with memoization; verifies solvability before presenting a puzzle.

### Game modes

| Mode | Entry | Seed source | Key controller |
|---|---|---|---|
| Free Play | `StartScreen` → `FreePlayStartScreen` | Random | `PracticeRoundFlowCoordinator` |
| Daily Challenge | `StartScreen` → `DailyScreen` | `DailySeed` (date-based) | `DailyController` |
| Rush (Speed Run) | `StartScreen` → `RushStartScreen` | Sequential per session | `RushController` |

### Move pipeline

```
User selects two dice + operator
  → MoveEngine.combineValues()
  → MoveValidator (rejects invalid division/subtraction)
  → RoundEvaluator (checks if target reached)
  → Solver confirms remaining state still solvable
```

### Navigation

Plain imperative `Navigator.push` / `Navigator.pop` — no named routes, no GoRouter.

### Audio

`SfxSingleton` (core/audio/sfx_singleton.dart) is a global singleton managing 14 `AudioPlayer` channels via the `audioplayers` package. Call `SfxSingleton.instance.play(SfxEvent.xxx)` from anywhere.

### Theme / design tokens

All colours, spacing, radii, durations, and text styles live in `lib/core/theme/`. Dark neon palette; seed colour `#7B5FE0`, surface `#0D0F1F`. Always use these constants rather than inline values.
