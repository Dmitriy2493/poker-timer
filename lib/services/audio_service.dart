import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool soundEnabled = true;

  Future<void> playLevelEnd() async {
    if (!soundEnabled) return;
    await _player.play(AssetSource('sounds/level_end.wav'));
  }

  Future<void> playWarning() async {
    if (!soundEnabled) return;
    await _player.play(AssetSource('sounds/warning.wav'));
  }

  Future<void> playCountdown() async {
    if (!soundEnabled) return;
    await _player.play(AssetSource('sounds/countdown.wav'));
  }

  void dispose() {
    _player.dispose();
  }
}
