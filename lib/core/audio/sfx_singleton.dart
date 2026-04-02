import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Sfx sfx = Sfx();

class Sfx {
  static const _prefsKey = 'sound_enabled';

  final AudioPlayer _roll = AudioPlayer();
  final AudioPlayer _valid = AudioPlayer();
  final AudioPlayer _invalid = AudioPlayer();
  final AudioPlayer _win = AudioPlayer();
  final AudioPlayer _lose = AudioPlayer();
  final AudioPlayer _click = AudioPlayer();
  final AudioPlayer _dailyComplete = AudioPlayer();
  final AudioPlayer _undo = AudioPlayer();
  final AudioPlayer _solution = AudioPlayer();
  final AudioPlayer _startDaily = AudioPlayer();
  final AudioPlayer _hint = AudioPlayer();
  final AudioPlayer _giveUp = AudioPlayer();

  bool enabled = true;

  bool _ready = false;
  bool _loading = false;

  Future<void> init() async {
    if (_ready || _loading) return;
    _loading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefsKey) ?? true;

      await _roll.setPlayerMode(PlayerMode.lowLatency);
      await _valid.setPlayerMode(PlayerMode.lowLatency);
      await _invalid.setPlayerMode(PlayerMode.lowLatency);
      await _win.setPlayerMode(PlayerMode.lowLatency);
      await _lose.setPlayerMode(PlayerMode.lowLatency);
      await _click.setPlayerMode(PlayerMode.lowLatency);
      await _dailyComplete.setPlayerMode(PlayerMode.lowLatency);
      await _undo.setPlayerMode(PlayerMode.lowLatency);
      await _solution.setPlayerMode(PlayerMode.lowLatency);
      await _startDaily.setPlayerMode(PlayerMode.lowLatency);
      await _hint.setPlayerMode(PlayerMode.lowLatency);
      await _giveUp.setPlayerMode(PlayerMode.lowLatency);

      await _roll.setReleaseMode(ReleaseMode.stop);
      await _valid.setReleaseMode(ReleaseMode.stop);
      await _invalid.setReleaseMode(ReleaseMode.stop);
      await _win.setReleaseMode(ReleaseMode.stop);
      await _lose.setReleaseMode(ReleaseMode.stop);
      await _click.setReleaseMode(ReleaseMode.stop);
      await _dailyComplete.setReleaseMode(ReleaseMode.stop);
      await _undo.setReleaseMode(ReleaseMode.stop);
      await _solution.setReleaseMode(ReleaseMode.stop);
      await _startDaily.setReleaseMode(ReleaseMode.stop);
      await _hint.setReleaseMode(ReleaseMode.stop);
      await _giveUp.setReleaseMode(ReleaseMode.stop);

      await _roll.setVolume(1.0);
      await _valid.setVolume(1.0);
      await _invalid.setVolume(1.0);
      await _win.setVolume(1.0);
      await _lose.setVolume(1.0);
      await _click.setVolume(1.0);
      await _dailyComplete.setVolume(1.0);
      await _undo.setVolume(1.0);
      await _solution.setVolume(1.0);
      await _startDaily.setVolume(1.0);
      await _hint.setVolume(1.0);
      await _giveUp.setVolume(1.0);

      await _roll.setSource(AssetSource('sfx/roll.wav'));
      await _valid.setSource(AssetSource('sfx/valid.wav'));
      await _invalid.setSource(AssetSource('sfx/invalid.wav'));
      await _win.setSource(AssetSource('sfx/win.wav'));
      await _lose.setSource(AssetSource('sfx/lose.wav'));
      await _click.setSource(AssetSource('sfx/click.wav'));
      await _dailyComplete.setSource(AssetSource('sfx/daily_complete.wav'));
      await _undo.setSource(AssetSource('sfx/undo.wav'));
      await _solution.setSource(AssetSource('sfx/solution.wav'));
      await _startDaily.setSource(AssetSource('sfx/start_daily.wav'));
      await _hint.setSource(AssetSource('sfx/hint.wav'));
      await _giveUp.setSource(AssetSource('sfx/give_up.wav'));

      _ready = true;
    } catch (_) {
      _ready = false;
    } finally {
      _loading = false;
    }
  }

  Future<void> toggle() async {
    enabled = !enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  Future<void> roll() async => _play(_roll, 'sfx/roll.wav');
  Future<void> valid() async => _play(_valid, 'sfx/valid.wav');
  Future<void> invalid() async => _play(_invalid, 'sfx/invalid.wav');
  Future<void> win() async => _play(_win, 'sfx/win.wav');
  Future<void> lose() async => _play(_lose, 'sfx/lose.wav');
  Future<void> click() async => _play(_click, 'sfx/click.wav');
  Future<void> dailyComplete() async => _play(_dailyComplete, 'sfx/daily_complete.wav');
  Future<void> undo() async => _play(_undo, 'sfx/undo.wav');
  Future<void> solution() async => _play(_solution, 'sfx/solution.wav');
  Future<void> startDaily() async => _play(_startDaily, 'sfx/start_daily.wav');
  Future<void> hint() async => _play(_hint, 'sfx/hint.wav');
  Future<void> giveUp() async => _play(_giveUp, 'sfx/give_up.wav');

  Future<void> _play(AudioPlayer p, String assetPath) async {
    if (!enabled) return;

    if (!_ready) {
      await init();
      if (!_ready) return;
    }

    try {
      await p.stop();
      await p.setSource(AssetSource(assetPath));
      await p.resume();
    } catch (_) {}
  }
}
