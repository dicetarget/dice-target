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

  bool enabled = true;

  bool _ready = false;
  bool _loading = false;

  /// Call once on app start
  Future<void> init() async {
    if (_ready || _loading) return;
    _loading = true;

    try {
      // 🔹 load persisted toggle FIRST
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefsKey) ?? true;

      // Low-latency SFX
      await _roll.setPlayerMode(PlayerMode.lowLatency);
      await _valid.setPlayerMode(PlayerMode.lowLatency);
      await _invalid.setPlayerMode(PlayerMode.lowLatency);
      await _win.setPlayerMode(PlayerMode.lowLatency);
      await _lose.setPlayerMode(PlayerMode.lowLatency);
      await _click.setPlayerMode(PlayerMode.lowLatency);

      await _roll.setReleaseMode(ReleaseMode.stop);
      await _valid.setReleaseMode(ReleaseMode.stop);
      await _invalid.setReleaseMode(ReleaseMode.stop);
      await _win.setReleaseMode(ReleaseMode.stop);
      await _lose.setReleaseMode(ReleaseMode.stop);
      await _click.setReleaseMode(ReleaseMode.stop);

      await _roll.setVolume(1.0);
      await _valid.setVolume(1.0);
      await _invalid.setVolume(1.0);
      await _win.setVolume(1.0);
      await _lose.setVolume(1.0);
      await _click.setVolume(1.0);

      // iOS-safe asset preloading
      await _roll.setSource(AssetSource('sfx/roll.wav'));
      await _valid.setSource(AssetSource('sfx/valid.wav'));
      await _invalid.setSource(AssetSource('sfx/invalid.wav'));
      await _win.setSource(AssetSource('sfx/win.wav'));
      await _lose.setSource(AssetSource('sfx/lose.wav'));
      await _click.setSource(AssetSource('sfx/click.wav'));

      _ready = true;
    } catch (_) {
      _ready = false;
    } finally {
      _loading = false;
    }
  }

  /// Toggle + persist
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
