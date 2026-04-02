import 'package:audioplayers/audioplayers.dart';

class Sfx {
  final AudioPlayer _roll = AudioPlayer();
  final AudioPlayer _valid = AudioPlayer();
  final AudioPlayer _invalid = AudioPlayer();
  final AudioPlayer _win = AudioPlayer();
  final AudioPlayer _startDaily = AudioPlayer();

  bool _ready = false;
  bool _loading = false;

  Future<void> init() async {
    if (_ready || _loading) return;
    _loading = true;

    try {
      // Für kurze SFX:
      await _roll.setPlayerMode(PlayerMode.lowLatency);
      await _valid.setPlayerMode(PlayerMode.lowLatency);
      await _invalid.setPlayerMode(PlayerMode.lowLatency);
      await _win.setPlayerMode(PlayerMode.lowLatency);
      await _startDaily.setPlayerMode(PlayerMode.lowLatency);

      await _roll.setReleaseMode(ReleaseMode.stop);
      await _valid.setReleaseMode(ReleaseMode.stop);
      await _invalid.setReleaseMode(ReleaseMode.stop);
      await _win.setReleaseMode(ReleaseMode.stop);
      await _startDaily.setReleaseMode(ReleaseMode.stop);

      await _roll.setVolume(1.0);
      await _valid.setVolume(1.0);
      await _invalid.setVolume(1.0);
      await _win.setVolume(1.0);
      await _startDaily.setVolume(1.0);

      // iOS: Assets vorher setzen (stabiler als direkt play())
      await _roll.setSource(AssetSource('sfx/roll.wav'));
      await _valid.setSource(AssetSource('sfx/valid.wav'));
      await _invalid.setSource(AssetSource('sfx/invalid.wav'));
      await _win.setSource(AssetSource('sfx/win.wav'));
      await _startDaily.setSource(AssetSource('sfx/start_daily.wav'));

      _ready = true;
    } catch (_) {
      // Absichtlich: App darf NICHT crashen wegen Audio
      _ready = false;
    } finally {
      _loading = false;
    }
  }

  Future<void> dispose() async {
    await _roll.dispose();
    await _valid.dispose();
    await _invalid.dispose();
    await _win.dispose();
    await _startDaily.dispose();
    _ready = false;
  }

  Future<void> roll() async => _play(_roll, 'sfx/roll.wav');
  Future<void> valid() async => _play(_valid, 'sfx/valid.wav');
  Future<void> invalid() async => _play(_invalid, 'sfx/invalid.wav');
  Future<void> win() async => _play(_win, 'sfx/win.wav');
  Future<void> startDaily() async => _play(_startDaily, 'sfx/start_daily.wav');

  Future<void> _play(AudioPlayer p, String assetPath) async {
    if (!_ready) {
      await init();
      if (!_ready) return;
    }
    try {
      await p.stop();
      // setSource + resume ist auf iOS oft stabiler als play(AssetSource)
      await p.setSource(AssetSource(assetPath));
      await p.resume();
    } catch (_) {}
  }
}
