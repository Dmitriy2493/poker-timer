import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool soundEnabled = true;

  Future<void> playLevelEnd() async {
    if (!soundEnabled) return;
    await _player.play(AssetSource('sounds/level_end.mp3'));
  }

  Future<void> playWarning() async {
    if (!soundEnabled) return;
    await _player.play(AssetSource('sounds/warning.mp3'));
  }

  void dispose() {
    _player.dispose();
  }
}
